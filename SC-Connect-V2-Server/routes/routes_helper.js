//includes
var dbManager = require('../database/mysql_manager'); //used to interact with the database
var moment = require('moment'); //for date parsing

/*
 *   Client Helper Functions
 */

// Adds the client to the database.
exports.registerClientWithDeviceUUID = function (uuid, callback) {
    if (uuid && uuid.length == 36) { //validate input data
        var proc_name = "RegisterClientByDeviceUUID";
        var params = [uuid];
        dbManager.runProcedure(proc_name, params, function (clientRows) {
            callback(true);
        });
    } else {
        callback(false); //uuid or token is null or invalid length
    }
};

// Updates the push token of the client.
exports.updatePushTokenOfClientWithDeviceUUID = function (uuid, pushToken, callback) {
    if (uuid && pushToken && pushToken.length == 64) { //validate input data
        var proc_name = "UpdatePushTokenOfClientByDeviceUUID";
        var params = [uuid, pushToken];
        dbManager.runProcedure(proc_name, params, function (clientRows) {
            callback(true);
        });
    } else {
        callback(false);
    }
};

// Looks up the client by device uuid.
exports.findClientWithDeviceUUID = function (uuid, callback) {
    if (uuid) {
        var proc_name = "FindClientByDeviceUUID";
        var params = [uuid];
        dbManager.runProcedure(proc_name, params, function (clientRows) {
            if (clientRows && clientRows.length > 0) {
                callback(clientRows[0]);
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //uuid or token is null or invalid length
    }
};

// Finds all clients where the given user is signed in.
exports.findClientsByUserID = function (userID, callback) {
    if (userID && !isNaN(userID)) {
        var proc_name = "FindClientsByUserID";
        var params = [userID];
        dbManager.runProcedure(proc_name, params, function (clientRows) {
            if (clientRows && clientRows.length > 0) {
                callback(clientRows);
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //uuid or token is null or invalid length
    }
};

// Finds all clients.
exports.findAllClients = function (callback) {
    var proc_name = "FindAllClients";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (clientRows) {
        if (clientRows && clientRows.length > 0) {
            callback(clientRows);
        } else {
            callback(null);
        }
    });
};

// Removes the client with the given push token.
exports.removeClientByPushToken = function (pushToken, callback) {
    if (pushToken && pushToken.length == 64) { //validate input data
        dbManager.runProcedure('RemoveClientByPushToken', [pushToken], function () {
            callback();
        });
    } else {
        callback(); //invalid input
    }
};

/*
 *   User Helper Functions
 */

// Looks up the user by google identifier.
exports.findUserByGoogleID = function (googleID, callback) {
    if (googleID) {
        var proc_name = "FindUserByGoogleID";
        var params = [googleID];
        dbManager.runProcedure(proc_name, params, function (userRows) {
            if (userRows && userRows.length > 0) {
                callback(userRows[0]);
            } else {
                callback(null); //not found
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Looks up the user by local user identifier.
exports.findUserByUserID = function (userID, callback) {
    if (userID && !isNaN(userID)) {
        var proc_name = "FindUserByUserID";
        var params = [userID];
        dbManager.runProcedure(proc_name, params, function (userRows) {
            if (userRows && userRows.length > 0) {
                callback(userRows[0]);
            } else {
                callback(null); //not found
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Looks up the user by email address
exports.findUserByEmail = function (email, callback) {
    if (email && email.length <= 50) { //validate length of input
        var proc_name = "FindUserByEmail";
        var params = [email];
        dbManager.runProcedure(proc_name, params, function (userRows) {
            if (userRows && userRows.length > 0) {
                callback(userRows[0]);
            } else {
                callback(null); //not found
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Looks up the user by google identifier (if exists) or creates a user. Returns user row.
exports.findOrCreateUser = function (googleID, email, firstName, lastName, callback) {
    exports.findUserByGoogleID(googleID, function (user) {
        if (user) {
            callback(user);
        } else if (email && email.length <= 50 && firstName && firstName.length <= 45 && lastName && lastName.length <= 45) { //validate input data
            var proc_name = "CreateUser";
            var params = [googleID, email, firstName, lastName];
            dbManager.runProcedure(proc_name, params, function (createUserRows) {
                if (createUserRows && createUserRows.length > 0) {
                    callback(createUserRows[0]);
                } else {
                    callback(null); //should never reach this point
                }
            });
        }
    });
};

// Grabs all users that are marked as moderators.
exports.findAllModerators = function (callback) {
    var proc_name = "FindAllModerators";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (userRows) {
        if (userRows && userRows.length > 0) {
            callback(userRows);
        } else {
            callback(null); //no moderators exist
        }
    });
};

// Demotes the moderator back to a normal user.
exports.demoteModeratorByID = function (moderatorID, callback) {
    if (moderatorID && !isNaN(moderatorID)) {
        var proc_name = "DemoteModeratorByID";
        var params = [moderatorID];
        dbManager.runProcedure(proc_name, params, function () {
            callback(); //success
        });
    } else {
        callback(); //invalid input
    }
};

// Promotes the user to moderator status.
exports.promoteUserByID = function (userID, callback) {
    if (userID && !isNaN(userID)) {
        var proc_name = "PromoteUserByID";
        var params = [userID];
        dbManager.runProcedure(proc_name, params, function () {
            callback(); //success
        });
    } else {
        callback(); //invalid input
    }
};

/*
 *   User Sign In Helper Functions
 */

// Marks the user as signed in on the given client.
exports.signInUserOnClientByID = function (clientID, userID, callback) {
    if (clientID && !isNaN(clientID) && userID && !isNaN(userID)) { //further validation not used bc both should be pulled directly from database.
        var proc_name = "UpdateUserIDOfClientByID";
        var params = [clientID, userID];
        dbManager.runProcedure(proc_name, params, function () {
            callback();
        });
    } else {
        callback();
    }
};

// Unmarks the user as signed in on the given client.
exports.signOutUserOnClientByID = function (clientID, callback) {
    if (clientID && !isNaN(clientID)) {
        var proc_name = "RemoveUserIDOfClientByID";
        var params = [clientID];
        dbManager.runProcedure(proc_name, params, function () { //sets user_id property of client = null
            callback();
        });
    } else {
        callback(); //should never reach this point bc data passed in should be validated with JWT validation
    }
};

/*
 * Subscription Helpers
 */

// Subscribes user to given tag.
exports.subscribeUserToTag = function (tagName, userID, callback) {
    if (tagName && userID && !isNaN(userID)) {
        var proc_name = "SubscribeUserToTag";
        var params = [tagName, userID];
        dbManager.runProcedure(proc_name, params, function () {
            callback();
        });
    } else {
        callback(); //should never reach this point
    }
};

// Unsubscribers user from given tag.
exports.unsubscribeUserFromTag = function (tagName, userID, callback) {
    if (tagName && userID && !isNaN(userID)) {
        var proc_name = "UnsubscribeUserFromTag";
        var params = [tagName, userID];
        dbManager.runProcedure(proc_name, params, function () {
            callback();
        });
    } else {
        callback(); //should never reach this point
    }
};

// Looks up a subscription between the user and the tag.
exports.findSubscriptionByTagNameAndUserID = function (tagName, userID, callback) {
    if (tagName && userID && !isNaN(userID)) {
        var proc_name = "FindSubscriptionByTagNameAndUserID";
        var params = [tagName, userID];
        dbManager.runProcedure(proc_name, params, function (subscriptionRows) {
            if (subscriptionRows && subscriptionRows.length > 0) {
                callback(subscriptionRows[0]);
            } else {
                callback(null); //doesn't exist
            }
        });
    } else {
        callback(null); //should never reach this point
    }
};

// Looks up all subscriptions of the given user.
exports.findAllSubscriptionsOfUserByID = function (userID, callback) {
    if (userID && !isNaN(userID)) {
        var proc_name = "FindAllSubscriptionsOfUserByID";
        var params = [userID];
        dbManager.runProcedure(proc_name, params, function (subscriptionRows) {
            if (subscriptionRows && subscriptionRows.length > 0) {
                callback(subscriptionRows);
            } else {
                callback(null); //no subscriptions
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Looks up every user that is subscribed to the given tag.
exports.findAllSubscribedUsersByTagName = function (tagName, callback) {
    if (tagName) {
        var proc_name = "FindAllSubscribedUsersByTagName";
        var params = [tagName];
        dbManager.runProcedure(proc_name, params, function (userRows) {
            if (userRows) {
                callback(userRows);
            } else {
                callback(null); //no users subscribed
            }
        });
    } else {
        callback(null); //invalid input
    }
};


/*
 * Leaderboard Score Helpers
 */

// Updates or creates a leaderboard score for the user with the given score. Update adds the score to the user's current total.
exports.updateOrCreateLeaderboardScoreForUserByID = function (userID, graduationYear, score, callback) {
    if (userID && !isNaN(userID) && graduationYear && !isNaN(graduationYear) && score && !isNaN(score) && score > 0) { // No negative scores allowed.
        exports.findLeaderboardScoreByUserID(userID, function (leaderboardScore) {
            if (leaderboardScore) {
                var proc_name = "UpdateLeaderboardScoreForUserByID";
                var params = [userID, graduationYear, leaderboardScore.leaderboard_score + score];
                dbManager.runProcedure(proc_name, params, function () {
                    callback();
                });
            } else {
                var proc_name = "CreateLeaderboardScoreForUserByID";
                var params = [userID, graduationYear, score];
                dbManager.runProcedure(proc_name, params, function () {
                    callback();
                });
            }
        });
    } else {
        callback(); //invalid input
    }
};

// Looks up the leaderboard score for the user.
exports.findLeaderboardScoreByUserID = function (userID, callback) {
    if (userID && !isNaN(userID)) {
        var proc_name = "FindLeaderboardScoreByUserID";
        var params = [userID];
        dbManager.runProcedure(proc_name, params, function (leaderboardScoreRows) {
            if (leaderboardScoreRows && leaderboardScoreRows.length > 0) {
                callback(leaderboardScoreRows[0]); //should only be one score per user
            } else {
                callback(null); //no score yet
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Looks up all of the leaderboard scores. Proc also grabs the first and last name for the user of each score and attaches it to the row.
exports.findAllLeaderboardScores = function (callback) {
    var proc_name = "FindAllLeaderboardScores";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (leaderboardScoreRows) {
        if (leaderboardScoreRows && leaderboardScoreRows.length > 0) {
            callback(leaderboardScoreRows);
        } else {
            callback(null); //no scores yet
        }
    });
};

// Totals the number of points that the given grad year has.
exports.totalLeaderboardPointsByGraduationYear = function (graduationYear, callback) {
    if (!isNaN(graduationYear)) {
        var proc_name = "TotalLeaderboardPointsByGraduationYear";
        var params = [graduationYear];
        dbManager.runProcedure(proc_name, params, function (leaderboardScoreRows) {
            if (leaderboardScoreRows && leaderboardScoreRows.length > 0) {
                callback(leaderboardScoreRows[0]['SUM(leaderboard_score)']);
            } else {
                callback(null); //invalid total (probably no points)
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Deletes up all of the leaderboard scores.
exports.deleteAllLeaderboardScores = function (callback) {
    var proc_name = "DeleteAllLeaderboardScores";
    var params = [];
    dbManager.runProcedure(proc_name, params, function () {
        callback();
    });
};

/*
 * Tag Helpers
 */

// Creates a tag with a name and color index.
exports.createTagByName = function (tagName, colorIndex, callback) {
    if (tagName && tagName.length <= 8 && !isNaN(colorIndex) && colorIndex >= 0 && colorIndex < 15) { //validate input (can't check if colorIndex exists bc could be 0)
        var proc_name = "CreateTagByName";
        var params = [tagName, colorIndex];
        dbManager.runProcedure(proc_name, params, function (createTagRows) {
            if (createTagRows && createTagRows.length > 0) {
                callback(createTagRows[0]);
            } else {
                callback(null); //should never reach this point
            }
        });
    } else {
        callback(null); //bad input
    }
};

// Finds or creates a tag with a name and color index.
exports.findOrCreateTagByName = function (tagName, colorIndex, callback) {
    if (tagName && tagName.length <= 8 && !isNaN(colorIndex) && colorIndex >= 0 && colorIndex < 15) { //validate input (can't check if colorIndex exists bc could be 0)
        exports.findTagByName(tagName, function (tag) {
            if (tag) {
                callback(tag);
            } else {
                exports.createTagByName(tagName, colorIndex, function (createdTag) {
                    callback(createdTag); // Could be null if fails
                });
            }
        });
    } else {
        callback(null); //bad input
    }
};

// Grabs the subsciption count of a tag by name. Always returns a number if tagname passed in (0 if no subscriptions on tag or tag does not exist).
exports.subscriberCountByTagName = function (tagName, callback) {
    if (tagName) {
        var proc_name = "SubscriberCountOfTagByName";
        var params = [tagName];
        dbManager.runProcedure(proc_name, params, function (subscriptionRows) {
            if (subscriptionRows && subscriptionRows.length > 0) {
                callback(subscriptionRows[0]['COUNT(*)']);
            } else {
                callback(null); //should never reach here bc COUNT(*) always returns a value
            }
        });
    } else {
        callback(null); //bad input
    }
};

// Grabs the most recently used tags.
exports.topTags = function (callback) {
    var proc_name = "TopTenTags";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (tagRows) {
        if (tagRows) {
            callback(tagRows);
        } else {
            callback(null);
        }
    });
};

// Grabs all tags.
exports.findAllTags = function (callback) {
    var proc_name = "FindAllTags";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (tagRows) {
        if (tagRows) {
            callback(tagRows);
        } else {
            callback(null);
        }
    });
};

// Updates the color index for the tag by name and returns if successful.
exports.updateTagColor = function (tagName, newColorIndex, callback) {
    if (tagName && !isNaN(newColorIndex) && newColorIndex >= 0 && newColorIndex < 15) { // Can't check if newColorIndex exists like usual bc if (obj) also checks if it is = 0.
        var proc_name = "UpdateColorOfTagByName";
        var params = [tagName, newColorIndex];
        dbManager.runProcedure(proc_name, params, function () {
            callback(true);
        });
    } else {
        callback(false); //bad input
    }
};

// Looks up the tag by name. Procedure checks for visibility, so hidden tag won't be returned. Also validates length of tag name bc all procs have 8 character limit for the tag name.
exports.findTagByName = function (tagName, callback) {
    if (tagName && tagName.length <= 8) { //proc only takes 8 character tag name
        var proc_name = "FindTagByName";
        var params = [tagName];
        dbManager.runProcedure(proc_name, params, function (tagRows) {
            if (tagRows && tagRows.length > 0) {
                callback(tagRows[0]);
            } else {
                callback(null); // not found
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Grabs all tags containing the search term.
exports.tagsContainingSearchTerm = function (searchTerm, callback) {
    if (searchTerm && searchTerm.length <= 8) {
        var proc_name = 'TagsContainingSearchTerm';
        var params = ['%' + searchTerm + '%']; //wildcards for use in MySQL comparison
        dbManager.runProcedure(proc_name, params, function (tagRows) {
            if (tagRows) {
                callback(tagRows);
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //invalid search term
    }
};

// Marks the given tag as hidden and notes which moderator hid it.
exports.hideTagByName = function (tagName, moderatorID, callback) {
    if (tagName && moderatorID && !isNaN(moderatorID)) {
        var proc_name = 'HideTagByName';
        var params = [tagName, moderatorID];
        dbManager.runProcedure(proc_name, params, function () {
            callback(); //success
        });
    } else {
        callback(); //invalid input
    }
};

/*
 *   Messages Helpers
 */

// Creates a message for the given user (by id) on the given tag (by name) with the given message body. Both user and tag should be checked for visibility before calling this function.
exports.createMessage = function (userID, tagName, messageBody, callback) {
    if (userID && !isNaN(userID) && tagName && messageBody && messageBody.length < 512) {
        var proc_name = 'CreateMessage';
        var params = [userID, tagName, messageBody];
        dbManager.runProcedure(proc_name, params, function (messagesRows) {
            if (messagesRows && messagesRows.length == 1) {
                callback(messagesRows[0]); //pass back just one message bc only one created
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Grabs the latest messages on the given tag.
exports.latestMessagesFromTagWithName = function (tagName, callback) {
    if (tagName) {
        var proc_name = 'LatestMessagesFromTagByName';
        var params = [tagName];
        dbManager.runProcedure(proc_name, params, function (messagesRows) {
            if (messagesRows) {
                callback(messagesRows);
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Grabs the single latest messages on the given tag.
exports.lastMessageFromTagWithName = function (tagName, callback) {
    if (tagName) {
        var proc_name = 'LastMessageFromTagByName';
        var params = [tagName];
        dbManager.runProcedure(proc_name, params, function (messagesRows) {
            if (messagesRows && messagesRows.length == 1) {
                callback(messagesRows[0]); //pass back just one message
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Grabs messages before given message (by id) on given tag. This works bc newest messages have bigger id.
exports.messagesBeforeMessageWithID = function (tagName, messageID, callback) {
    if (tagName && messageID && !isNaN(messageID)) {
        var proc_name = 'MessagesBeforeMessageByID';
        var params = [tagName, messageID];
        dbManager.runProcedure(proc_name, params, function (messagesRows) {
            if (messagesRows) {
                callback(messagesRows);
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Grabs messages after given message (by id) on given tag. This works bc newest messages have bigger id.
exports.messagesAfterMessageWithID = function (tagName, messageID, callback) {
    if (tagName && messageID && !isNaN(messageID)) {
        var proc_name = 'MessagesAfterMessageByID';
        var params = [tagName, messageID];
        dbManager.runProcedure(proc_name, params, function (messagesRows) {
            if (messagesRows) {
                callback(messagesRows);
            } else {
                callback(null);
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Grabs the message of the given message id.
exports.findMessageByID = function (messageID, callback) {
    if (messageID && !isNaN(messageID)) { // Can do usual check on message id (which is an int) bc mysql starts auto_increment at 1.
        var proc_name = 'FindMessageByID';
        var params = [messageID];
        dbManager.runProcedure(proc_name, params, function (messagesRows) {
            if (messagesRows) {
                callback(messagesRows[0]); //Only return one message bc one per id
            } else {
                callback(null); //not found
            }
        });
    } else {
        callback(null); //invalid input
    }
};

// Grabs all flagged messages.
exports.findAllFlaggedMessages = function (callback) {
    var proc_name = 'FindAllFlaggedMessages';
    var params = [];
    dbManager.runProcedure(proc_name, params, function (messagesRows) {
        if (messagesRows) {
            callback(messagesRows);
        } else {
            callback(null); //no flagged messages
        }
    })
};

// Marks the given message as flagged.
exports.flagMessageByID = function (messageID, callback) {
    if (messageID && !isNaN(messageID)) {
        var proc_name = 'FlagMessageByID';
        var params = [messageID];
        dbManager.runProcedure(proc_name, params, function () {
            callback(); //success
        });
    } else {
        callback(); //invalid input
    }
};

// Unmarks the given message as flagged.
exports.unflagMessageByID = function (messageID, callback) {
    if (messageID && !isNaN(messageID)) {
        var proc_name = 'UnflagMessageByID';
        var params = [messageID];
        dbManager.runProcedure(proc_name, params, function () {
            callback(); //success
        });
    } else {
        callback(); //invalid input
    }
};

// Marks the given message as hidden and notes which moderator hid it.
exports.hideMessageByID = function (messageID, moderatorID, callback) {
    if (messageID && !isNaN(messageID) && moderatorID && !isNaN(moderatorID)) {
        var proc_name = 'HideMessageByID';
        var params = [messageID, moderatorID];
        dbManager.runProcedure(proc_name, params, function () {
            callback(); //success
        });
    } else {
        callback(); //invalid input
    }
};

/*
 *   Event Helpers
 */

// Create event with the given info. Function name includes "school" because createEvent is an existing js function.
exports.createEvent = function (eventName, userID, startDate, endDate, locationName, locationAddress, locationLatitude, locationLongitude, leaderboardPoints, callback) {
    if (eventName && eventName.length > 0 && eventName.length < 256 &&
        userID && !isNaN(userID) &&
        startDate && endDate && moment(startDate, 'yyyy.MM.dd HH:mm:ss').isBefore(moment(endDate, 'yyyy.MM.dd HH:mm:ss')) && //validate that start date is before end date
        locationName && locationName.length > 0 && locationName.length <= 32 &&
        locationAddress && locationAddress.length <= 256 &&
        locationLongitude >= -180.0 && locationLongitude <= 180.0 &&
        locationLatitude >= -90.0 && locationLatitude <= 90.0 &&
        leaderboardPoints && !isNaN(leaderboardPoints) && leaderboardPoints > 0 && leaderboardPoints <= 100) { //can't have more than 100 points for one event

        var proc_name = 'CreateEvent';
        var params = [eventName, userID, startDate, endDate, locationName, locationAddress, locationLatitude, locationLongitude, leaderboardPoints];
        dbManager.runProcedure(proc_name, params, function (eventRows) {
            if (eventRows && eventRows.length == 1) { //should just return one row bc one created
                callback(eventRows[0]);
            } else {
                callback(null); //internal error
            }
        });
    } else {
        callback(null); //bad request
    }
};

// Checks in the given user to the given event.
exports.checkInUserToEvent = function (eventID, userID, callback) {
    if (eventID && !isNaN(eventID) && userID && !isNaN(userID)) {
        var proc_name = "CheckInUserToEvent";
        var params = [eventID, userID];
        dbManager.runProcedure(proc_name, params, function () {
            callback();
        });
    } else {
        callback(); //bad input
    }
};

// Grabs all events that start or end in the future.
exports.getAllFutureEvents = function (callback) {
    var proc_name = "FutureEvents";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (eventRows) {
        if (eventRows) {
            callback(eventRows);
        } else {
            callback(null);
        }
    });
};

// Looks up the event by id.
exports.findEventByID = function (eventID, callback) {
    if (eventID && !isNaN(eventID)) {
        var proc_name = "FindEventByID";
        var params = [eventID];
        dbManager.runProcedure(proc_name, params, function (eventRows) {
            if (eventRows) {
                callback(eventRows[0]); // one event per id
            } else {
                callback(null);
            }
        });
    } else {
        callback(null);
    }
};

// Grabs the number of users that are checked into the given event.
exports.eventCheckInCount = function (eventID, callback) {
    if (eventID && !isNaN(eventID)) {
        var proc_name = "EventCheckInCount";
        var params = [eventID];
        dbManager.runProcedure(proc_name, params, function (checkInRows) {
            if (checkInRows) {
                callback(checkInRows[0]['COUNT(*)']); //pulls the count int out of the rows
            } else {
                callback(null); //should never reach here bc COUNT(*) always returns a value
            }
        });
    } else {
        callback(null); //bad input
    }
};

// Looks up if given user has checked into the given event.
exports.findCheckInByEventAndUserID = function (eventID, userID, callback) {
    if (eventID && !isNaN(eventID) && userID && !isNaN(userID)) {
        var proc_name = "FindCheckInByEventAndUserID";
        var params = [eventID, userID];
        dbManager.runProcedure(proc_name, params, function (checkInRows) {
            if (checkInRows) {
                callback(checkInRows[0]);
            } else {
                callback(null); //check in not found
            }
        });
    } else {
        callback(null); //bad input
    }
};

// Grabs the check in rows of all users checked into the given event.
exports.findCheckInsByEventID = function (eventID, callback) {
    if (eventID && !isNaN(eventID)) {
        var proc_name = "FindCheckInsByEventID";
        var params = [eventID];
        dbManager.runProcedure(proc_name, params, function (checkInRows) {
            if (checkInRows) {
                callback(checkInRows); //returns all check ins bc likely more than one user checked in
            } else {
                callback(null); //check in not found
            }
        });
    } else {
        callback(null); //bad input
    }
};

/*
 * Scheduled Sports Games Helpers
 */

// Creates a scheduled game.
exports.createScheduledSportsGame = function (sportName, gameDate, opponentName, locationName, callback) {
    if (sportName && gameDate && opponentName && opponentName.length <= 128 && locationName && locationName.length < 64) { //need to validate gameDate
        var proc_name = "CreateScheduledSportsGame";
        var params = [sportName, gameDate, opponentName, locationName];
        dbManager.runProcedure(proc_name, params, function () {
            callback();
        });
    } else {
        callback(); //bad input
    }
};

// Looks up all scheduled games by sport.
exports.findScheduledGamesForSportByName = function (sportName, callback) {
    if (sportName) {
        var proc_name = "FindScheduledGamesForSportByName";
        var params = [sportName];
        dbManager.runProcedure(proc_name, params, function (scheduledSportsGameRows) {
            if (scheduledSportsGameRows) {
                callback(scheduledSportsGameRows);
            } else {
                callback(null); //no scheduled games found
            }
        });
    } else {
        callback(null); //bad input
    }
};

// Looks up all scheduled games.
exports.findAllScheduledGames = function (callback) {
    var proc_name = "FindAllScheduledGames";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (scheduledSportsGameRows) {
        if (scheduledSportsGameRows) {
            callback(scheduledSportsGameRows);
        } else {
            callback(null); //no scheduled games found
        }
    });
};

// Deletes all schedule games.
exports.deleteAllScheduledSportsGames = function (callback) {
    var proc_name = "DeleteAllScheduledSportsGames";
    var params = [];
    dbManager.runProcedure(proc_name, params, function () {
        callback();
    });
};

/*
 * Sports Game Result Helpers
 */

// Creates a game result.
exports.createSportsGameResult = function (sportName, gameDate, opponentName, opponentScore, homeScore, callback) {
    if (sportName && gameDate && opponentName && opponentName.length <= 128 &&
        opponentScore && !isNaN(opponentScore) &&
        homeScore && !isNaN(homeScore)) { //need to validate gameDate
        var proc_name = "CreateSportsGameResult";
        var params = [sportName, gameDate, opponentName, opponentScore, homeScore];
        dbManager.runProcedure(proc_name, params, function () {
            callback();
        });
    } else {
        callback(); //bad input
    }
};

// Looks up all game results by sport.
exports.findGameResultsForSportByName = function (sportName, callback) {
    if (sportName) {
        var proc_name = "FindGameResultsForSportByName";
        var params = [sportName];
        dbManager.runProcedure(proc_name, params, function (sportsGameResultRows) {
            if (sportsGameResultRows) {
                callback(sportsGameResultRows);
            } else {
                callback(null); //no game results found
            }
        });
    } else {
        callback(null); //bad input
    }
};

// Looks up all game results.
exports.findAllGameResults = function (callback) {
    var proc_name = "FindAllGameResults";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (sportsGameResultRows) {
        if (sportsGameResultRows) {
            callback(sportsGameResultRows);
        } else {
            callback(null); //no game results found
        }
    });
};

// Deletes all game results.
exports.deleteAllSportsGameResults = function (callback) {
    var proc_name = "DeleteAllSportsGameResults";
    var params = [];
    dbManager.runProcedure(proc_name, params, function () {
        callback();
    });
};

/*
 * Fan Cam Helpers
 */

// Creates a fan cam image record.
exports.createFanCamRecord = function (awsKey, userID, callback) {
    if (awsKey && userID && !isNaN(userID)) {
        var proc_name = "CreateFanCamRecord";
        var params = [awsKey, userID];
        dbManager.runProcedure(proc_name, params, function (fanCamRows) {
            callback();
        });
    } else {
        callback(); //bad input
    }
};

// Looks up all fan cam image records.
exports.findAllFanCamRecords = function (callback) {
    var proc_name = "FindAllFanCamRecords";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (fanCamRecordRows) {
        if (fanCamRecordRows) {
            callback(fanCamRecordRows);
        } else {
            callback(null); //no image records found
        }
    });
};

// Looks up fan cam image record by id.
exports.findFanCamRecordByID = function (recordID, callback) {
    if (recordID && !isNaN(recordID)) {
        var proc_name = "FindFanCamRecordByID";
        var params = [recordID];
        dbManager.runProcedure(proc_name, params, function (fanCamRecordRows) {
            if (fanCamRecordRows && fanCamRecordRows.length > 0) {
                callback(fanCamRecordRows[0]); // just one row per id
            } else {
                callback(null); //no image records found
            }
        });
    } else {
        callback(null);
    }
};

// Hides fan cam image record by id and marks who hid it.
exports.hideFanCamRecordByID = function (recordID, userID, callback) {
    if (recordID && !isNaN(recordID) && userID && !isNaN(userID)) {
        var proc_name = "HideFanCamRecordByID";
        var params = [recordID, userID];
        dbManager.runProcedure(proc_name, params, function () {
            callback(); //success
        });
    } else {
        callback(); // invalid input
    }
};


/*
 * Club Helpers
 */

// Creates a club and returns filled in club row.
exports.createClub = function (clubName, associatedTagName, clubLeaders, meetingDays, meetingTime, meetingLocation, callback) {
    if (clubName && clubName.length <= 64 &&
        associatedTagName && associatedTagName.length <= 8 &&
        clubLeaders && meetingDays &&
        meetingTime && meetingTime.length <= 64 &&
        meetingLocation && meetingLocation.length <= 64) {
        var clubLeadersString = clubLeaders.join();
        var meetingDaysString = meetingDays.join();
        if (clubLeadersString.length <= 256 && meetingDaysString.length <= 128) {
            var proc_name = "CreateClub";
            var params = [clubName, associatedTagName, clubLeadersString, meetingDaysString, meetingTime, meetingLocation];
            dbManager.runProcedure(proc_name, params, function (clubRows) {
                if (clubRows && clubRows.length == 1) {
                    clubRows[0].club_leaders = clubRows[0].club_leaders.split(','); // Turn arrays back into arrays (instead of comma separated strings).
                    clubRows[0].meeting_days = clubRows[0].meeting_days.split(',');
                    callback(clubRows[0]);
                } else {
                    callback(null); //internal error
                }
            });
        } else {
            callback(null); //bad input
        }
    } else {
        callback(null); //bad input
    }
};

// Updates a club.
exports.updateClub = function (clubID, clubName, associatedTagName, clubLeaders, meetingDays, meetingTime, meetingLocation, callback) {
    if (clubID && !isNaN(clubID) && clubName && clubName.length <= 64 &&
        associatedTagName && associatedTagName.length <= 8 &&
        clubLeaders && meetingDays &&
        meetingTime && meetingTime.length <= 64 &&
        meetingLocation && meetingLocation.length <= 64) {
        var clubLeadersString = clubLeaders.join();
        var meetingDaysString = meetingDays.join();
        if (clubLeadersString.length <= 256 && meetingDaysString.length <= 128) {
            var proc_name = "UpdateClub";
            var params = [clubID, clubName, associatedTagName, clubLeadersString, meetingDaysString, meetingTime, meetingLocation];
            dbManager.runProcedure(proc_name, params, function () {
                callback(true); // success
            });
        } else {
            callback(false); //bad input
        }
    } else {
        callback(false); //bad input
    }
};

// Finds club with the given id.
exports.findClubByID = function (clubID, callback) {
    if (clubID && !isNaN(clubID)) {
        var proc_name = "FindClubByID";
        var params = [clubID];
        dbManager.runProcedure(proc_name, params, function (clubRows) {
            if (clubRows && clubRows.length == 1) {
                clubRows[0].club_leaders = clubRows[0].club_leaders.split(','); // Turn arrays back into arrays (instead of comma separated strings).
                clubRows[0].meeting_days = clubRows[0].meeting_days.split(',');
                callback(clubRows[0]);
            } else {
                callback(null); //not found
            }
        });
    } else {
        callback(null); //Invalid input
    }
};

// Looks up all clubs.
exports.findAllClubs = function (callback) {
    var proc_name = "FindAllClubs";
    var params = [];
    dbManager.runProcedure(proc_name, params, function (clubRows) {
        if (clubRows) {
            for (var i = 0; i < clubRows.length; i++) {
                clubRows[i].club_leaders = clubRows[i].club_leaders.split(','); // Turn arrays back into arrays (instead of comma separated strings).
                clubRows[i].meeting_days = clubRows[i].meeting_days.split(',');
            }
            callback(clubRows);
        } else {
            callback(null); //no clubs found
        }
    });
};

// Deletes club with the given id.
exports.deleteClubByID = function (clubID, callback) {
    if (clubID && !isNaN(clubID)) {
        var proc_name = "DeleteClubByID";
        var params = [clubID];
        dbManager.runProcedure(proc_name, params, function () {
            callback();
        });
    } else {
        callback(); //Invalid input
    }
};


/*
 * Graduation Year Helpers
 */

// Creates an array of the 4 current graduation years.
exports.availableGraduationYears = function () {
    var now = moment();
    var graduationYears = [];
    if (now.isAfter(moment().month('Jul').date(1)) && now.isBefore(moment().month('Dec').date(31))) { // If it is in the first half of school year, next year is first valid graduation year.
        graduationYears.push(now.year() + 1);
        graduationYears.push(now.year() + 2);
        graduationYears.push(now.year() + 3);
        graduationYears.push(now.year() + 4);
    } else { // If it is in second half of school year, current year is still a valid graduation year.
        graduationYears.push(now.year());
        graduationYears.push(now.year() + 1);
        graduationYears.push(now.year() + 2);
        graduationYears.push(now.year() + 3);
    }
    return graduationYears;
};
