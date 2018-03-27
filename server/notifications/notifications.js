var helper = global.helper; // Can use global helper bc not on background thread
var apn = require('apn');
var apnConnection = apn.Connection({
    production: false
}); //conects to apn using cert.pem and key.pem
var feedback = new apn.feedback({
    production: false,
    interval: 10
});

exports.sendNotification = function (tokens, message, shouldPlaySound) {
    var note = new apn.Notification();
    note.badge = 1;
    if (shouldPlaySound) {
        note.sound = 'default';
    }
    note.setAlertText(message);
    apnConnection.pushNotification(note, tokens); //send it to the tokens in the array
};


feedback.on("feedback", function (data) {
    data.forEach(function (item) {
        var itemToken = item.device.toString('hex');
        helper.removeClientByPushToken(itemToken, function () {
            console.log('Client with token ' + itemToken + ' was not responding and was successfully removed.');
        });
    });
});

apnConnection.on("connected", function () {
    console.log("Connected to APNS successfully.");
});

apnConnection.on("transmitted", function (notification, device) {
    console.log('APNS: Notification (\"' + notification.alert + '\") transmitted to: ' + device.token.toString("hex"));
});

apnConnection.on("socketError", console.error);

apnConnection.on("timeout", function () {
    console.log("APNS: Connection Timeout");
});

apnConnection.on("disconnected", function () {
    console.log("Disconnected from APNS");
});
