/*
 * SC-Connect API Routes
 *   -> Contains all handling functions (routes) for web requests used in the SC-Connect app.
 *      Most handlers direct further action to the helper file.
 *   -> Authentication between the the server and app is done via JSON Web Tokens. A token is a string that includes basic information and a signature.
 *        It should be impossible to forge a valid signature that will verify on the server side.
 *        The token becomes invalid after the "exp" claim has passed. It is valid for one month after creation.
 *        When a user signs in, it is marked in the database that they are signed in on the given client.
 *          If they choose to logout, the server will unmark the user as signed in on that client and although the token could still be valid, the server won't accept those requests.
 *        The token is also used for socket communication from the app to the server in order to verify who the user is.
 *
 */

//includes
var helper = global.helper;
var GoogleAuthentication = require('google-auth-library');
var googleAuth = new GoogleAuthentication;
var jwt = require('jsonwebtoken');
var jwtConfig = require('../config/jwt_config'); //for JSON Web Token functions

//constants
const serverGoogleClientID = '674210700940-b640lvcr8uddhcjlq758on7r6ino1429.apps.googleusercontent.com'
const iosGoogleClientID = '674210700940-qoer1us8n7u2uh31fmkk15siv2amjrqc.apps.googleusercontent.com'

/*
 *   Route Handlers
 */
module.exports = function (expressApp) {


    /*
     * Client Request Handlers
     */

    //Registers client by UUID
    expressApp.post('/scconnect/clients/register', function (req, res) {
        var uuid = req.body.uuid;

        helper.findClientWithDeviceUUID(uuid, function (client) {
            if (client) {
                res.sendStatus(200); //device already registered
            } else {
                helper.registerClientWithDeviceUUID(uuid, function (success) {
                    if (success) {
                        res.sendStatus(201);
                    } else {
                        res.sendStatus(400); //uuid wrong length
                    }
                });
            }
        });
    });

    //Updates the Apple Push Notification Token for the client by UUID
    expressApp.post('/scconnect/clients/updatePushToken', function (req, res) {
        var uuid = req.body.uuid;
        var pushToken = req.body.push_token;

        helper.findClientWithDeviceUUID(uuid, function (client) {
            if (client) {
                helper.updatePushTokenOfClientWithDeviceUUID(uuid, pushToken, function (success) {
                    if (success) {
                        res.sendStatus(201);
                    } else {
                        res.sendStatus(400); //push token wrong length
                    }
                });
            } else {
                res.sendStatus(404); //device does not exist
            }
        });
    });

    /*
     * JSON Web Token (utilizes user/client functions) Request Handlers
     */

    expressApp.post('/scconnect/clients/signInToGoogleAccount', function (req, res) {
        var uuid = req.body.uuid;
        var googleIDToken = req.body.google_id_token;

        helper.findClientWithDeviceUUID(uuid, function (client) {
            if (client) {
                fetchUserForIDTokenFromGoogleAPI(googleIDToken, function (googleUser) {
                    if (googleUser) {
                        helper.findOrCreateUser(googleUser.sub, googleUser.email, googleUser.given_name, googleUser.family_name, function (user) {
                            if (user) {
                                helper.signInUserOnClientByID(client.client_id, user.user_id, function () {
                                    res.type('application/json');
                                    res.status(201);
                                    res.end(JSON.stringify({
                                        'json_web_token': generateSignedJWT(uuid, user.user_id)
                                    }));
                                });
                            } else {
                                res.sendStatus(500); //should never reach this point
                            }
                        });
                    } else {
                        res.sendStatus(401); //invalid id token
                    }
                });
            } else {
                res.sendStatus(401); //client with that uuid does not exist
            }
        });
    });

    expressApp.post('/scconnect/clients/signOutFromGoogleAccount', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides

        helper.signOutUserOnClientByID(authInfo.client.client_id, function () {
            res.sendStatus(201);
        });
    });

    expressApp.get('/scconnect/clients/GoogleAccountPermissions', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides

        res.type('application/json');
        res.status(200);
        res.end(JSON.stringify({
            'moderator': authInfo.user.moderator,
            'admin': authInfo.user.admin
        }));
    });


    /*
     *   Subscription Request Handlers
     */

    // Creates a subscription for the user to the given tag.
    expressApp.post('/scconnect/subscriptions/subscribeToTag', validateJWT, function (req, res) {
        var authInfo = res.locals.auth;
        var tagName = req.body.tag_name;

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.findSubscriptionByTagNameAndUserID(tagName, authInfo.user.user_id, function (subscription) {
                    if (!subscription) {
                        helper.subscribeUserToTag(tagName, authInfo.user.user_id, function () {
                            res.sendStatus(201); //subscribed successfully
                        });
                    } else {
                        res.sendStatus(200); //already subscribed
                    }
                });
            } else {
                res.sendStatus(404); //tag does not exist
            }
        });
    });

    // Removes subscription for the user from the given tag.
    expressApp.post('/scconnect/subscriptions/unsubscribeFromTag', validateJWT, function (req, res) {
        var authInfo = res.locals.auth;
        var tagName = req.body.tag_name;

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.findSubscriptionByTagNameAndUserID(tagName, authInfo.user.user_id, function (subscription) {
                    if (subscription) {
                        helper.unsubscribeUserFromTag(tagName, authInfo.user.user_id, function () {
                            res.sendStatus(201); //unsubscribed successfully
                        });
                    } else {
                        res.sendStatus(200); //not currently subscribed
                    }
                });
            } else {
                res.sendStatus(404); //tag does not exist
            }
        });
    });

    // Grabs the names of all subscribed tags and returns them.
    expressApp.get('/scconnect/subscriptions/allSubscribedTagNames/', validateJWT, function (req, res) {
        var authInfo = res.locals.auth;

        helper.findAllSubscriptionsOfUserByID(authInfo.user.user_id, function (subscriptions) {
            res.type('application/json');
            res.status(201);
            if (subscriptions) {
                var subscribedTagNames = [];
                for (var i = 0; i < subscriptions.length; i++) {
                    subscribedTagNames.push(subscriptions[i].tag_name);
                }
                res.end(JSON.stringify({
                    'tag_names': subscribedTagNames
                }));
            } else {
                res.end(JSON.stringify({
                    'tag_names': []
                }));
            }
        });
    });

    //Turns off notifications for the given client from the given tag
    // expressApp.post('/scconnect/clients/turnOnNotificationsFromTag', function(req, res) {
    //     var uuid = req.body.uuid;
    //     var tagName = req.body.tag_name;
    //     findClientWithDeviceUUID(uuid, function(errorCode, client) {
    //         if (!errorCode) {
    //             dbManager.runProcedure('NotifyClientFromTagWithName', [client.client_id, tagName], function() {
    //                 res.sendStatus(201); //successfully updated token of client
    //             });
    //         } else {
    //             res.sendStatus(errorCode);
    //         }
    //     });
    // });

    //Turns on notifications for the given client from the given tag
    // expressApp.post('/scconnect/clients/turnOffNotificationsFromTag', function(req, res) {
    //     var uuid = req.body.uuid;
    //     var tagName = req.body.tag_name;
    //     findClientWithDeviceUUID(uuid, function(errorCode, client) {
    //         if (!errorCode) {
    //             dbManager.runProcedure('StopNotifyingClientFromTagWithName', [client.client_id, tagName], function() {
    //                 res.sendStatus(201); //successfully updated token of client
    //             });
    //         } else {
    //             res.sendStatus(errorCode);
    //         }
    //     });
    // });

    /*
     * Leaderboard Scores
     */

    // Grabs all scores and returns them.
    expressApp.get('/scconnect/leaderboard/scores', function (req, res) {
        helper.findAllLeaderboardScores(function (leaderboardScores) {
            res.type('application/json');
            res.status(200);
            if (leaderboardScores) {
                res.end(JSON.stringify({
                    'leaderboard_scores': leaderboardScores
                }));
            } else {
                res.end(JSON.stringify({
                    'leaderboard_scores': [] // no scores yet
                }));
            }
        });
    });

    // Grabs the total points for each available graduation year. If no points, defaults to 0 for that graduation year.
    expressApp.get('/scconnect/leaderboard/graduationYearTotals', function (req, res) {
        var graduationYears = helper.availableGraduationYears();
        var graduationYearTotals = [];
        var numberOfTotalledGraduationYears = 0;
        graduationYears.forEach(function(graduationYear) {
            helper.totalLeaderboardPointsByGraduationYear(graduationYear, function (pointsTotal) {
                var graduationYearTotal = {};
                if (pointsTotal && !isNaN(pointsTotal)) {
                    graduationYearTotal['graduation_year'] = graduationYear;
                    graduationYearTotal['points_total'] = pointsTotal;
                } else {
                    graduationYearTotal['graduation_year'] = graduationYear;
                    graduationYearTotal['points_total'] = 0; // Gives every grad year a default of 0 points.
                }
                graduationYearTotals.push(graduationYearTotal);
                if (numberOfTotalledGraduationYears >= graduationYears.length - 1) {
                    res.type('application/json');
                    res.status(200);
                    res.end(JSON.stringify({
                        'graduation_year_totals': graduationYearTotals
                    }));
                }
                numberOfTotalledGraduationYears++;
            });
        });
    });
    
    // Grabs the list of available graduation years.
    expressApp.get('/scconnect/leaderboard/availableGraduationYears', function (req, res) {
        res.type('application/json');
        res.status(200);
        res.end(JSON.stringify({
            'available_graduation_years': helper.availableGraduationYears()
        }));
    });

    /*
     * Tag Request Handlers
     */

    // Creates a tag with the given name and color index. Must be signed in.
    expressApp.post('/scconnect/tags/create', validateJWT, function (req, res) {
        var tagName = req.body.tag_name;
        var colorIndex = parseInt(req.body.color_index);

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                res.sendStatus(200); //Tag already exists
            } else {
                helper.createTagByName(tagName, colorIndex, function (newTag) {
                    if (newTag) {
                        res.type('application/json');
                        res.status(201);
                        res.end(JSON.stringify({
                            'tag': newTag
                        }));
                    } else {
                        res.sendStatus(400); //bad request bc invalid color index or tag name too long
                    }
                });
            }
        });
    });

    //Gets the top tags (by most recent activity) in descending order
    expressApp.get('/scconnect/tags/topTags/', function (req, res) {
        helper.topTags(function (topTags) {
            res.type('application/json');
            res.status(200);
            if (topTags) {
                res.end(JSON.stringify({
                    'tags': topTags
                }));
            } else {
                res.end(JSON.stringify({
                    'tags': [] //empty array bc no top tags passed back
                }));
            }
        });
    });

    // Gets all tags.
    expressApp.get('/scconnect/tags/all/', function (req, res) {
        helper.findAllTags(function (tags) {
            res.type('application/json');
            res.status(200);
            if (tags) {
                res.end(JSON.stringify({
                    'tags': tags
                }));
            } else {
                res.end(JSON.stringify({
                    'tags': [] //empty array bc no tags passed back
                }));
            }
        });
    });

    //Gets the info of the given tag
    expressApp.get('/scconnect/tags/info/', function (req, res) { //without the info keyword, this method will prevent toptags from getting called bc toptags treated as tagName
        var tagName = req.query.tagName;
        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                res.type('application/json');
                res.status(200);
                res.end(JSON.stringify({
                    'tag': tag
                }));
            } else {
                res.sendStatus(404); //tag not found
            }
        });
    });

    // Gets the subscriber count of the specified tag.
    expressApp.get('/scconnect/tags/subscriberCount/', function (req, res) {
        var tagName = req.query.tagName;

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.subscriberCountByTagName(tagName, function (count) {
                    if (count != null) { //can't do if(count) bc count could be zero
                        res.type('application/json');
                        res.status(200);
                        res.end(JSON.stringify({
                            'subscriber_count': count
                        }));
                    } else {
                        res.sendStatus(500); //should never reach this point bc only reached passed in tag name is null
                    }
                });
            } else {
                res.sendStatus(404); //tag does not exist
            }
        })
    });

    //Gets any tags that contain the given search term (don't think it's case sensitive)
    expressApp.get('/scconnect/tags/tagsContainingSearchTerm/', function (req, res) {
        var searchTerm = req.query.searchTerm;

        helper.tagsContainingSearchTerm(searchTerm, function (tags) {
            res.type('application/json');
            res.status(200);
            if (tags) {
                res.end(JSON.stringify({
                    'tags': tags
                }));
            } else {
                res.end(JSON.stringify({
                    'tags': [] //empty array bc no tags containing search term passed back (possible that search term was too long)
                }));
            }
        })
    });

    //Updates the color index of the given tag
    expressApp.post('/scconnect/tags/updateColor', validateJWT, function (req, res) {
        var tagName = req.body.tag_name;
        var colorIndex = parseInt(req.body.color_index);

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.updateTagColor(tagName, colorIndex, function (success) {
                    if (success) {
                        res.sendStatus(201); //updated
                    } else {
                        res.sendStatus(400); //Bad request input
                    }
                })
            } else {
                res.sendStatus(404); //tag does not exist
            }
        });
    });





    /*
     * Message Request Handlers
     */

    //Creates a formatted message (of type pure, video, photo, etc) on the given tag and sends back the newly created message.
    expressApp.post('/scconnect/messages/create', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var tagName = req.body.tag_name;
        var messageBody = req.body.message_body;

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.createMessage(authInfo.user.user_id, tagName, messageBody, function (message) {
                    if (message) {
                        res.type('application/json');
                        res.status(201);
                        res.end(JSON.stringify({
                            'message': message
                        }));
                    } else {
                        res.sendStatus(400); //likely invalid or missing message_body. Could also be an internal server error, but unlikely
                    }
                });
            } else {
                res.sendStatus(404); //tag does not exist
            }
        });
    });

    //Gets the latest messages from a given tag
    expressApp.get('/scconnect/messages/latest/', function (req, res) {
        var tagName = req.query.tagName;

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.latestMessagesFromTagWithName(tagName, function (messages) {
                    res.type('application/json');
                    res.status(200);
                    if (messages) {
                        res.end(JSON.stringify({
                            'messages': messages
                        }));
                    } else {
                        res.end(JSON.stringify({
                            'messages': [] //empty array bc no messages passed back but the tag exists
                        }));
                    }
                });
            } else {
                res.sendStatus(404); //tag not found
            }
        });
    });

    //Gets the single latest message from a given tag (proc checks for visibility)
    expressApp.get('/scconnect/messages/last/', function (req, res) {
        var tagName = req.query.tagName;

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.lastMessageFromTagWithName(tagName, function (message) {
                    res.type('application/json');
                    res.status(200);
                    if (message) {
                        res.end(JSON.stringify({
                            'message': message
                        }));
                    } else {
                        res.end(JSON.stringify({
                            'message': {} //empty dictionary bc no message passed back but the tag exists
                        }));
                    }
                });
            } else {
                res.sendStatus(404); //tag not found
            }
        });
    });

    //Gets ~20 messages prior to the given message from the given tag.
    expressApp.get('/scconnect/messages/before/', function (req, res) {
        var tagName = req.query.tagName;
        var messageID = parseInt(req.query.messageID); //could check that messageID is valid, but it really doesn't matter bc proc checks just uses messageID to check if other messages are smaller

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.messagesBeforeMessageWithID(tagName, messageID, function (messages) {
                    res.type('application/json');
                    res.status(200);
                    if (messages) {
                        res.end(JSON.stringify({
                            'messages': messages
                        }));
                    } else {
                        res.end(JSON.stringify({
                            'messages': [] //empty array bc no messages passed back but the tag exists
                        }));
                    }
                });
            } else {
                res.sendStatus(404); //tag not found
            }
        });
    });

    //Gets all messages newer than the given message from the given tag.
    expressApp.get('/scconnect/messages/after/', function (req, res) {
        var tagName = req.query.tagName;
        var messageID = parseInt(req.query.messageID);

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.messagesAfterMessageWithID(tagName, messageID, function (messages) {
                    res.type('application/json');
                    res.status(200);
                    if (messages) {
                        res.end(JSON.stringify({
                            'messages': messages
                        }));
                    } else {
                        res.end(JSON.stringify({
                            'messages': [] //empty array bc no messages passed back but the tag exists
                        }));
                    }
                });
            } else {
                res.sendStatus(404); //tag not found
            }
        });
    });

    // Flags the given message.
    expressApp.post('/scconnect/messages/flagMessage', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var messageID = req.body.message_id;

        helper.findMessageByID(messageID, function (message) {
            if (message) {
                helper.flagMessageByID(messageID, function () {
                    res.sendStatus(201);
                });
            } else {
                res.sendStatus(404); //message not found
            }
        });
    });

    // Unflags the given message.
    expressApp.post('/scconnect/messages/unflagMessage', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var messageID = req.body.message_id;

        helper.findMessageByID(messageID, function (message) {
            if (message) {
                helper.unflagMessageByID(messageID, function () {
                    res.sendStatus(201);
                });
            } else {
                res.sendStatus(404); //message not found
            }
        });
    });

    // Gets all flagged messages.
    expressApp.get('/scconnect/messages/flagged/', function (req, res) {
        helper.findAllFlaggedMessages(function (messages) {
            res.type('application/json');
            res.status(200);
            if (messages) {
                res.end(JSON.stringify({
                    'messages': messages
                }));
            } else {
                res.end(JSON.stringify({
                    'messages': [] //empty array bc no flagged messages
                }));
            }
        });
    });


    /*
     * Check In Request Handlers
     */

    //Creates an event with the given info and returns a filled in event so app can stay in sync with server (ids, etc)
    expressApp.post('/scconnect/events/create', validateJWT, function (req, res) { //Takes google id because user must be signed in and google id more stable than local client id
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var eventName = req.body.event_name;
        var startDate = req.body.start_date; //should be formatted like datetime (currently not validated)
        var endDate = req.body.end_date; //should be formatted like datetime (currently not validated)
        var locationName = req.body.location_name;
        var locationAddress = req.body.location_address;
        var locationLatitude = req.body.location_latitude;
        var locationLongitude = req.body.location_longitude;
        var leaderboardPoints = req.body.leaderboard_points; //number of points that will be awarded for checking in at this event

        helper.createEvent(eventName, authInfo.user.user_id, startDate, endDate, locationName, locationAddress, locationLatitude, locationLongitude, leaderboardPoints, function (event) {
            if (event) {
                res.type('application/json');
                res.status(201);
                res.end(JSON.stringify({
                    'event': event
                }));
            } else {
                res.sendStatus(400); //bad input data most likely
            }
        });
    });

    // Marks the user as checked in to the given event and updates their leaderboard score.
    expressApp.post('/scconnect/events/checkIn', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var eventID = req.body.event_id;
        var graduationYear = req.body.graduation_year; // Year that the user will graduate

        helper.findEventByID(eventID, function (event) {
            if (event) {
                helper.findCheckInByEventAndUserID(eventID, authInfo.user.user_id, function (checkIn) {
                    if (!checkIn) { //if not already checked in
                        helper.checkInUserToEvent(eventID, authInfo.user.user_id, function () {
                            helper.updateOrCreateLeaderboardScoreForUserByID(authInfo.user.user_id, graduationYear, event.leaderboard_points, function () {
                                res.sendStatus(201); //checked in
                            });
                        });
                    } else {
                        res.sendStatus(200); //already checked in
                    }
                });
            } else {
                res.sendStatus(404); //event does not exist
            }
        });
    });

    //Gets the check in status of the user on a specific event
    expressApp.get('/scconnect/events/checkInStatus/', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var eventID = req.query.eventID;

        helper.findCheckInByEventAndUserID(eventID, authInfo.user.user_id, function (checkIn) {
            res.type('application/json');
            res.status(200);
            if (checkIn) {
                res.end(JSON.stringify({
                    'checked_in': true
                }));
            } else {
                res.end(JSON.stringify({
                    'checked_in': false
                }));
            }
        });
    });

    //Gets all future events in descending order.
    expressApp.get('/scconnect/events/future/', function (req, res) {
        helper.getAllFutureEvents(function (events) {
            res.type('application/json');
            res.status(200);
            if (events) {
                res.end(JSON.stringify({
                    'events': events
                }));
            } else {
                res.end(JSON.stringify({
                    'events': [] //empty array bc no events passed back
                }));
            }
        });
    });

    //Gets the check in count of the given event
    expressApp.get('/scconnect/events/checkInCount/', function (req, res) {
        var eventID = req.query.eventID;

        helper.findEventByID(eventID, function (event) {
            if (event) {
                helper.eventCheckInCount(eventID, function (checkInCount) {
                    if (checkInCount) {
                        res.type('application/json');
                        res.status(200);
                        res.end(JSON.stringify({
                            'check_in_count': checkInCount
                        }));
                    } else {
                        res.sendStatus(500); //should never reach this point
                    }
                });
            } else {
                res.sendStatus(404); //event does not exist
            }
        });
    });

    //Gets the list of names for users that have checked in to the specific event
    expressApp.get('/scconnect/events/checkedInUsernameList/', function (req, res) {
        var eventID = req.query.eventID;

        helper.findEventByID(eventID, function (event) {
            if (event) {
                helper.findCheckInsByEventID(eventID, function (checkIns) {
                    res.type('application/json');
                    res.status(200);
                    if (checkIns) {
                        var usernames = []; //array to hold just the full names of all checked in users on the given event
                        for (var i = 0; i < checkIns.length; i++) {
                            usernames.push(checkIns[i].first_name + ' ' + checkIns[i].last_name);
                        }

                        res.end(JSON.stringify({
                            'checked_in_usernames': usernames
                        }));
                    } else {
                        res.end(JSON.stringify({
                            'checked_in_usernames': [] //no users checked in yet
                        }));
                    }
                });
            } else {
                res.sendStatus(404); //event does not exist
            }
        });

    });

    /*
     * Sports Request Handlers
     */

    // Gets all scheduled games for the given sport.
    expressApp.get('/scconnect/sports/scheduledGames/', function (req, res) {
        var sportName = req.query.sportName;

        if (sportName) {
            helper.findScheduledGamesForSportByName(sportName, function (scheduledGames) {
                res.type('application/json');
                res.status(200);
                if (scheduledGames) {
                    res.end(JSON.stringify({
                        'schedules_games': scheduledGames
                    }));
                } else {
                    res.end(JSON.stringify({
                        'schedules_games': [] //no schedules games or sport doesn't exist
                    }));
                }
            });
        } else {
            res.sendStatus(400); //bad request
        }
    });

    // Gets all game results for the given sport.
    expressApp.get('/scconnect/sports/gameResults/', function (req, res) {
        var sportName = req.query.sportName;

        if (sportName) {
            helper.findGameResultsForSportByName(sportName, function (gameResults) {
                res.type('application/json');
                res.status(200);
                if (gameResults) {
                    res.end(JSON.stringify({
                        'game_results': gameResults
                    }));
                } else {
                    res.end(JSON.stringify({
                        'game_results': [] //no game results or sport doesn't exist
                    }));
                }
            });
        } else {
            res.sendStatus(400); //bad request
        }
    });

    /*
     * Fan Cam Request Handlers
     */

    // Creates a record of the fan cam image and returns the filled in record.
    expressApp.post('/scconnect/fancam/create', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var imageAWSKey = req.body.image_aws_key;

        helper.createFanCamRecord(imageAWSKey, authInfo.user.user_id, function () {
            res.sendStatus(201);
        });
    });

    // Gets all fan cam image records.
    expressApp.get('/scconnect/fancam/all/', function (req, res) {
        helper.findAllFanCamRecords(function (fanCamRecords) {
            res.type('application/json');
            res.status(200);
            if (fanCamRecords) {
                res.end(JSON.stringify({
                    'fan_cam_records': fanCamRecords
                }));
            } else {
                res.end(JSON.stringify({
                    'fan_cam_records': [] //no records exist
                }));
            }
        });
    });

    /*
     * Club Request Handlers
     */

    // Creates a club with the given info and returns a filled in club.
    expressApp.post('/scconnect/clubs/create', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var clubName = req.body.club_name;
        var associatedTagName = req.body.associated_tag_name;
        var clubLeaders = req.body.club_leaders;
        var meetingDays = req.body.meeting_days;
        var meetingTime = req.body.meeting_time;
        var meetingLocation = req.body.meeting_location;

        helper.findOrCreateTagByName(associatedTagName, 0, function (associatedTag) { //0 is default color index
            if (associatedTag) {
                helper.createClub(clubName, associatedTagName, clubLeaders, meetingDays, meetingTime, meetingLocation, function (club) {
                    if (club) {
                        res.type('application/json');
                        res.status(201);
                        res.end(JSON.stringify({
                            'club': club
                        }));
                    } else {
                        res.sendStatus(400); //bad input data most likely
                    }
                });
            } else {
                res.sendStatus(500); // Should never reach this point
            }
        })
    });
    
    // Updates a club with the given info.
    expressApp.post('/scconnect/clubs/update', validateJWT, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var clubID = req.body.club_id;
        var clubName = req.body.club_name;
        var associatedTagName = req.body.associated_tag_name;
        var clubLeaders = req.body.club_leaders;
        var meetingDays = req.body.meeting_days;
        var meetingTime = req.body.meeting_time;
        var meetingLocation = req.body.meeting_location;

        helper.findOrCreateTagByName(associatedTagName, 0, function (associatedTag) { //0 is default color index
            if (associatedTag) {
                helper.updateClub(clubID, clubName, associatedTagName, clubLeaders, meetingDays, meetingTime, meetingLocation, function (success) {
                    if (success) {
                        res.sendStatus(201);
                    } else {
                        res.sendStatus(400); //bad input data most likely
                    }
                });
            } else {
                res.sendStatus(500); // Should never reach this point
            }
        })
    });

    // Gets all clubs.
    expressApp.get('/scconnect/clubs/all/', function (req, res) {
        helper.findAllClubs(function (clubs) {
            res.type('application/json');
            res.status(200);
            if (clubs) {
                res.end(JSON.stringify({
                    'clubs': clubs
                }));
            } else {
                res.end(JSON.stringify({
                    'clubs': [] //no clubs exist
                }));
            }
        });
    });


    /*
     * Graduation Year Request Handlers
     */

    // Gets available graduation years.
    expressApp.get('/scconnect/graduationYears/available/', function (req, res) {
        res.type('application/json');
        res.status(200);
        res.end(JSON.stringify({
            'graduation_years': helper.availableGraduationYears()
        }));
    });


    /*
     * Moderator Request Handlers
     */

    // Hides the given message and marks which mod hid it.
    expressApp.post('/scconnect/moderator/hideMessage', validateJWT, isModerator, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var messageID = req.body.message_id;

        helper.findMessageByID(messageID, function (message) {
            if (message) {
                helper.hideMessageByID(messageID, authInfo.user.user_id, function () {
                    res.sendStatus(201);
                });
            } else {
                res.sendStatus(404); //message not found
            }
        });
    });

    // Hides the given tag and marks which mod hid it.
    expressApp.post('/scconnect/moderator/hideTag', validateJWT, isModerator, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var tagName = req.body.tag_name;

        helper.findTagByName(tagName, function (tag) {
            if (tag) {
                helper.hideTagByName(tagName, authInfo.user.user_id, function () {
                    res.sendStatus(201);
                });
            } else {
                res.sendStatus(404); //tag not found
            }
        });
    });

    // Deletes the given club by id.
    expressApp.post('/scconnect/moderator/deleteClub', validateJWT, isModerator, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var clubID = req.body.club_id;

        helper.findClubByID(clubID, function (club) {
            if (club) {
                helper.deleteClubByID(clubID, function () {
                    res.sendStatus(201);
                });
            } else {
                res.sendStatus(404); //club not found
            }
        });
    });
    
    // Hides the given fan cam image record and marks which mod hid it.
    expressApp.post('/scconnect/moderator/hideFanCamImageRecord', validateJWT, isModerator, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var recordID = req.body.fan_cam_image_record_id;

        helper.findFanCamRecordByID(recordID, function(fanCamRecord) {
            if (fanCamRecord) {
                helper.hideFanCamRecordByID(recordID, authInfo.user.user_id, function () {
                    res.sendStatus(201);
                });
            } else {
                res.sendStatus(404); //record not found
            }
        });
    });

    // Removes all leaderboard scores.
    expressApp.post('/scconnect/moderator/clearLeaderboardScores', validateJWT, isModerator, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides

        helper.deleteAllLeaderboardScores(function () {
            res.sendStatus(201); // success
        });
    });


    /*
     * Administrator Request Handlers
     */

    // Grabs information about each moderator (a user that is marked as moderator).
    expressApp.get('/scconnect/admin/allModerators', validateJWT, isAdmin, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides

        helper.findAllModerators(function (moderators) {
            res.type('application/json');
            res.status(200);
            if (moderators) {
                res.end(JSON.stringify({
                    'moderators': moderators
                }));
            } else {
                res.end(JSON.stringify({
                    'moderators': [] //empty array bc no moderators passed back
                }));
            }
        });
    });

    // Demotes the given moderator back to a normal user.
    expressApp.post('/scconnect/admin/demoteModerator', validateJWT, isAdmin, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var moderatorID = req.body.moderator_id;

        helper.findUserByUserID(moderatorID, function (moderator) {
            if (moderator) {
                if (moderator.moderator == true && moderator.user_id != authInfo.user.user_id && moderator.admin == false) {
                    helper.demoteModeratorByID(moderatorID, function () {
                        res.sendStatus(201); //success
                    });
                } else {
                    res.sendStatus(401); //can't demote yourself or another admin or a user that isn't a moderator
                }
            } else {
                res.sendStatus(404); //moderator does not exist
            }
        });
    });

    // Promotes the given user to moderator status.
    expressApp.post('/scconnect/admin/promoteUser', validateJWT, isAdmin, function (req, res) {
        var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides
        var email = req.body.email;

        helper.findUserByEmail(email, function (user) {
            if (user) {
                if (user.moderator == false) {
                    helper.promoteUserByID(user.user_id, function () {
                        res.sendStatus(201); //success
                    });
                } else {
                    res.sendStatus(401); //can't promote a moderator
                }
            } else {
                //could create template user without a lot of the info until they sign up
                res.sendStatus(404); //user does not exist
            }
        });
    });
};


/*
 *   Middleware
 */

// Middleware that validates the given JSON Web Token and passes on key info to the next handler. Works with GET and POST.
//    -> Client and user data is passed on in res.locals.auth dictionary. One client dictionary and one user dictionary.
//       Dictionary keys are lowercase with underscores for spaces like all data returned from mysql request.
function validateJWT(req, res, next) {
    var authToken = req.body.auth_token || req.query.authToken;

    if (authToken) {
        jwt.verify(authToken, jwtConfig.secret, function (err, decodedToken) {
            if (!err && decodedToken.uuid && decodedToken.userID) {
                helper.findClientWithDeviceUUID(decodedToken.uuid, function (client) {
                    if (client) {
                        helper.findUserByUserID(decodedToken.userID, function (user) {
                            if (user && client.user_id == user.user_id) { //validate that the user is signed in on that client
                                res.locals.auth = {
                                    client: client,
                                    user: user
                                }; //auth info dict for passing along to handler
                                next();
                            } else {
                                res.sendStatus(401); //user does not exist
                            }
                        });
                    } else {
                        res.sendStatus(401); //client does not exist
                    }
                });
            } else {
                console.log(err);
                res.sendStatus(401); //invalid token or expired
            }
        });
    } else {
        res.sendStatus(401); //no auth info provided
    }
}

// Middleware that ensures the signed in user is a moderator. Can only be called after validateJWT. 
function isModerator(req, res, next) {
    var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides

    if (authInfo.user.moderator == true) {
        next();
    } else {
        res.sendStatus(401); //not authorized (bc not a moderator)
    }
}

// Middleware that ensures the signed in user is an admin. Can only be called after validateJWT. 
function isAdmin(req, res, next) {
    var authInfo = res.locals.auth; //this should exist if it got to here bc that is what validateJWT provides

    if (authInfo.user.admin == true) {
        next();
    } else {
        res.sendStatus(401); //not authorized (bc not an admin)
    }
}

/*
 *   Google Auth Helper Functions
 */

// Grabs the google info for the user of the given id token and passes it back in google's user model format (their dict keys).
function fetchUserForIDTokenFromGoogleAPI(idToken, callback) {
    if (idToken) {
        var serverClient = new googleAuth.OAuth2(serverGoogleClientID, '', ''); //uses server client id w/o a secret because with an id token, the user information is publicly accessible
        serverClient.verifyIdToken(idToken, iosGoogleClientID, function (error, login) { //uses ios client id bc id token generated for that client
            if (error) {
                console.log(error);
                callback(null);
            } else {
                var googleUser = login.getPayload();
                callback(googleUser);
            }
        });
    } else {
        callback(null);
    }
}

/*
 * JSON Web Token Functions
 */

// Generates a JWT with the given information and an expiration date (one month from now). Signed with the app's secret using the (HMAC SHA256) algorithm.
function generateSignedJWT(uuid, userID) {
    var expiresDateInSeconds = Math.floor(Date.now() / 1000) + (60 * 60 * 24 * 31); //one month ahead of now in seconds
    var payload = {
        uuid: uuid,
        userID: userID,
        exp: expiresDateInSeconds
    };
    return jwt.sign(payload, jwtConfig.secret);
}
