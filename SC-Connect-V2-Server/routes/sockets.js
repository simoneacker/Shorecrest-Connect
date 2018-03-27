var helper = global.helper;
var jwt = require('jsonwebtoken');
var jwtConfig = require('../config/jwt_config'); //for JSON Web Token functions
var notifications = require('../notifications/notifications'); //for push notifications
var numberOfConnectedClients = 0;


/*
 *   Sockets Handlers
 */
module.exports = function (io) {
    io.on('connection', function (socket) {
        numberOfConnectedClients++;
        console.log('A client connected. Number of connected clients: ' + numberOfConnectedClients);

        // Dictionary of arrays (one per tag name) tracking names of currently typing users.
        var typingUsersByTag = {};

        // Joins rooms for all tags that the user is subscribed to.
        socket.on('joinAllSubscribedRooms', function (data, callback) {
            dataFromJWT(data.auth_token, function (authInfo) {
                if (authInfo) {
                    helper.findAllSubscriptionsOfUserByID(authInfo.user.user_id, function (subscriptions) {
                        if (subscriptions) {
                            subscriptions.forEach(function(subscription) {
                                socket.join(subscription.tag_name, function () {
                                    console.log(authInfo.user.first_name + ' ' + authInfo.user.last_name + ' joined room: ' + subscription.tag_name + '.');
                                });
                            });
                            callback('Success');
                        } else {
                            callback('User not subscribed to any tags.');
                        }
                    });
                } else {
                    callback('Not authorized'); //bad auth info
                }
            });
        });

        // Joins specific room.
        socket.on('joinRoom', function (data, callback) {
            dataFromJWT(data.auth_token, function (authInfo) {
                if (authInfo) {
                    helper.findTagByName(data.tag_name, function (tag) {
                        if (tag) {
                            socket.join(tag.tag_name, function () {
                                console.log(authInfo.user.first_name + ' ' + authInfo.user.last_name + ' joined room: ' + tag.tag_name + '.');
                                callback('Success');
                            });
                        } else {
                            callback('Tag does not exist.');
                        }
                    });
                } else {
                    callback('Not authorized'); //bad auth info
                }
            });
        });

        // Leaves a specific room.
        socket.on('leaveRoom', function (data, callback) {
            dataFromJWT(data.auth_token, function (authInfo) {
                if (authInfo) {
                    helper.findTagByName(data.tag_name, function (tag) {
                        if (tag) {
                            socket.leave(tag.tag_name, function () {
                                console.log(authInfo.user.first_name + ' ' + authInfo.user.last_name + ' left room: ' + tag.tag_name + '.');
                                callback('Success');
                            });
                        } else {
                            callback('Tag does not exist.');
                        }
                    });
                } else {
                    callback('Not authorized'); //bad auth info
                }
            });
        });

        // Accepts a new message that will be sent to the room for the tag it is posted to. Replies with an ack that contains {'error': 'error' or null}.
        socket.on('createMessage', function (data, callback) {
            var tagName = data.tag_name;
            var messageBody = data.message_body;

            dataFromJWT(data.auth_token, function (authInfo) {
                if (authInfo) {
                    helper.findTagByName(tagName, function (tag) {
                        if (tag) {
                            helper.createMessage(authInfo.user.user_id, tagName, messageBody, function (message) {
                                if (message) {
                                    console.log(authInfo.user.first_name + ' ' + authInfo.user.last_name + ' posted a message to ' + tagName + '.');
                                    io.to(tagName).emit('newMessage', message);
                                    sendNotificationToAllSubscribers(tagName, JSON.parse(messageBody), authInfo.user.first_name + ' ' + authInfo.user.last_name);
                                    callback('Success');
                                } else {
                                    callback('Bad request'); //likely invalid or missing message_body. Could also be an internal server error, but that is unlikely.
                                }
                            });
                        } else {
                            callback('Tag does not exist');
                        }
                    });
                } else {
                    callback('Not authorized'); //bad auth info
                }
            });
        });


        socket.on('startTyping', function (data, callback) {
            var tagName = data.tag_name;

            dataFromJWT(data.auth_token, function (authInfo) {
                if (authInfo) {
                    helper.findTagByName(tagName, function (tag) {
                        if (tag) {
                            var username = authInfo.user.first_name + ' ' + authInfo.user.last_name;
                            if (!typingUsersByTag[tagName]) {
                                typingUsersByTag[tagName] = [];
                            }
                            typingUsersByTag[tagName].push(username);
                            console.log(username + ' started typing on ' + tagName + '.');
                            io.to(tagName).emit('typingUpdate', tagName, typingUsersByTag[tagName]);
                            callback('Success');
                        } else {
                            callback('Tag does not exist');
                        }
                    });
                } else {
                    callback('Not authorized'); //bad auth info
                }
            });
        });

        socket.on('stopTyping', function (data, callback) {
            var tagName = data.tag_name;

            dataFromJWT(data.auth_token, function (authInfo) {
                if (authInfo) {
                    helper.findTagByName(tagName, function (tag) {
                        if (tag) {
                            var username = authInfo.user.first_name + ' ' + authInfo.user.last_name;
                            if (typingUsersByTag[tagName]) {
                                var indexOfName = typingUsersByTag[tagName].indexOf(username);
                                if (indexOfName > -1) {
                                    typingUsersByTag[tagName].splice(indexOfName, 1); //remove the name
                                }
                            }
                            console.log(username + ' stopped typing on ' + tagName + '.');
                            io.to(tagName).emit('typingUpdate', tagName, typingUsersByTag[tagName]);
                            callback('Success');
                        } else {
                            callback('Tag does not exist');
                        }
                    });
                } else {
                    callback('Not authorized'); //bad auth info
                }
            });
        });

        socket.on('disconnect', function () {
            numberOfConnectedClients--;
            console.log('A client disconnected. Number of connected clients: ' + numberOfConnectedClients);
        });
    });
}

// Function that validates the given JSON Web Token and sends back key info.
//    -> Dictionary keys are lowercase with underscores for spaces like all data returned from mysql request.
function dataFromJWT(authToken, callback) {
    if (authToken) {
        jwt.verify(authToken, jwtConfig.secret, function (err, decodedToken) {
            if (!err && decodedToken.uuid && decodedToken.userID) {
                helper.findClientWithDeviceUUID(decodedToken.uuid, function (client) {
                    if (client) {
                        helper.findUserByUserID(decodedToken.userID, function (user) {
                            if (user && client.user_id == user.user_id) { //validate that the user is signed in on that client
                                callback({
                                    client: client,
                                    user: user
                                }); //auth info dict
                            } else {
                                callback(null); //user does not exist
                            }
                        });
                    } else {
                        callback(null); //client does not exist
                    }
                });
            } else {
                console.log(err);
                callback(null); //invalid token or expired
            }
        });
    } else {
        callback(null); //no auth info provided
    }
}

// Generates and sends notification about the new message to all users subscribed to the given tag.
function sendNotificationToAllSubscribers(tagName, messageBodyDictionary, username) {
    var notificationText = '';
    var messageText = messageBodyDictionary['pure_message']['text'];
    if (messageText) {
        notificationText = username + ' to ' + tagName + ': ' + messageText;
    } else if (messageBodyDictionary['photo_message']) {
        notificationText = username + ' sent a photo.';
    } else if (messageBodyDictionary['video_message']) {
        notificationText = username + ' sent a video.';
    } else {
        return; //don't send message bc issue creating it
    }
    
    helper.findAllSubscribedUsersByTagName(tagName, function (users) { //send remote notifications
        if (users) {
            users.forEach(function (user) {
                helper.findClientsByUserID(user.user_id, function (clients) {
                    if (clients) {
                        clients.forEach(function (client) {
                            if (client.push_token) {
                                notifications.sendNotification([client.push_token], notificationText, true);
                            }
                        });
                    }
                });
            });
        }
    });
}
