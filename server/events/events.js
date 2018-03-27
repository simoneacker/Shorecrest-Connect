var repeat = require('repeat');
var moment = require('moment'); //for date manipulation
var helper = global.helper; //require('../routes/routes_helper'); //own connection to db bc on background process
var notifications = require('../notifications/notifications');

/* Startup */
repeat(createEventsNotificationTimeout).every(24, 'h').start();

// Create the timer that notifies about events at noon.
function createEventsNotificationTimeout() {
    var millisecondsTillNoon = millisecondsTill(12);

    setTimeout(function () {
        sendUpcomingEventNotifications();
    }, millisecondsTillNoon);
}

// Sends one notification about every event scheduled during the current day. Only sends notif if event starts, ends, or bridges today.
function sendUpcomingEventNotifications() {
    helper.getAllFutureEvents(function (events) {
        if (events) {
            events.forEach(function (event) {
                var eventStartDate = moment(event.start_date, 'yyyy.MM.ddTHH:mm:ss.SSSZ');
                var eventEndDate = moment(event.end_date, 'yyyy.MM.ddTHH:mm:ss.SSSZ');
                if (eventStartDate.isSame(moment(), 'd') || eventEndDate.isSame(moment(), 'd') || (eventStartDate.isBefore(moment(), 'd') && eventEndDate.isAfter(moment(), 'd'))) {
                    var notificationText = 'Event: ' + event.event_name + ' is happening today.';
                    helper.findAllClients(function (clients) {
                        if (clients) {
                            clients.forEach(function (client) {
                                if (client.push_token) {
                                    notifications.sendNotification([client.push_token], notificationText, true);
                                }
                            });
                        }
                    });
                }
            });
        }
    });
}

/* Utility functions */
function millisecondsTill(hour) {
  if(hour >= 0 && hour <= 23) {
    var now = moment().milliseconds(); //milliseconds
    var givenDate = moment().hour(hour).minutes(0).milliseconds(0).milliseconds(); //millis
    var millisTill = givenDate - now;
    if(millisTill < 0) {
      millisTill += 86400000; //tomorrow
    }
    return millisTill;
  }
  return 0;
}