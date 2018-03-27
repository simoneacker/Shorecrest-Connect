var repeat = require('repeat');
var shortid = require('shortid');
var jsdom = require('node-jsdom');
var moment = require('moment'); //for date manipulation
var sportsData = require('./sports-config');
var helper = global.helper; //require('../routes/routes_helper'); //own connection to db bc on background process
var notifications = require('../notifications/notifications');
const baseURL = 'http://www.wescoathletics.com/index.php?pid=0.3.41.';
const urlEnding = ".321";

/* Startup */
parseAllSportsData(function () {}); // Initial load
repeat(createSportsNotificationTimeouts).every(24, 'h').start();

// Create the two timers that notify about scheduled events at noon and results at midnight.
function createSportsNotificationTimeouts() {
    var millisecondsTillNoon = millisecondsTill(12);
    var millisecondsTillMidnight = millisecondsTill(0);

    setTimeout(function () {
        sendScheduledGameNotifications();
    }, millisecondsTillNoon);
    setTimeout(function () {
        sendGameResultNotifications();
    }, millisecondsTillMidnight);
}

// Sends one notification about every game scheduled the current day.
function sendScheduledGameNotifications() {
    parseAllSportsData(function () {
        helper.findAllScheduledGames(function (scheduledGames) {
            if (scheduledGames) {
                var counter = 0;
                var sportsOfScheduledGamesToday = [];
                scheduledGames.forEach(function (scheduledGame) {
                    var gameDate = moment(scheduledGame.game_date, 'yyyy.MM.ddTHH:mm:ss.SSSZ');
                    if (!sportsOfScheduledGamesToday.includes(scheduledGame.sport_name) && gameDate.isSame(moment(), 'd')) {
                        sportsOfScheduledGamesToday.push(scheduledGame.sport_name);
                    }
                    if (counter >= scheduledGames.length - 1) {
                        var notificationText = 'Sports events today: ' + sportsOfScheduledGamesToday.join(', ') + '.'; 
                        if (sportsOfScheduledGamesToday.length == 0) {
                            notificationText = 'There are no sports events today.'
                        }
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
                    counter++;
                });
            }
        });
    });
}

// Sends notifications about every game result from the current day.
function sendGameResultNotifications() {
    parseAllSportsData(function () {
        helper.findAllGameResults(function (gameResults) {
            if (gameResults) {
                gameResults.forEach(function (gameResult) {
                    var gameDate = moment(gameResult.game_date, 'yyyy.MM.ddTHH:mm:ss.SSSZ');
                    if (gameResult.home_score != -1 && gameResult.opponent_score != -1 && gameDate.isSame(moment(), 'd')) {
                        var notificationText = '';
                        if (gameResult.home_score > gameResult.opponent_score) {
                            notificationText = 'Shorecrest ' + gameResult.sport_name + ' won ' + gameResult.home_score + '-' + gameResult.opponent_score + ' vs. ' + gameResult.opponent_name;
                        } else if (gameResult.home_score < gameResult.opponent_score) {
                            notificationText = 'Shorecrest ' + gameResult.sport_name + ' lost ' + gameResult.opponent_score + '-' + gameResult.home_score + ' vs. ' + gameResult.opponent_name;
                        } else {
                            notificationText = 'Shorecrest ' + gameResult.sport_name + ' tied ' + gameResult.home_score + '-' + gameResult.opponent_score + ' vs. ' + gameResult.opponent_name;
                        }
                        helper.findAllClients(function (clients) {
                            if (clients) {
                                clients.forEach(function (client) {
                                    if (client.push_token) {
                                        notifications.sendNotification([client.push_token], notificationText, false);
                                    }
                                });
                            }
                        });
                    }
                });
            }
        });
    });
}

// Clears all old data and then fresh parses the data for each sport. 
function parseAllSportsData(callback) {
    console.log('Sports data parse started.');
    var counter = 0; //one bc increment after if statement
    helper.deleteAllScheduledSportsGames(function () {
        helper.deleteAllSportsGameResults(function () {
            sportsData.forEach(function (sportDict) {
                var url = baseURL + sportDict.urlNumber + urlEnding;
                getScheduledGamesAndResultFromURL(url, function (error, scheduledGames, gameResults) {
                    if (!error) {
                        for (var i = 0; i < scheduledGames.length; i++) {
                            var scheduledGame = scheduledGames[i];
                            helper.createScheduledSportsGame(sportDict.sport, scheduledGame.date, scheduledGame.opponent_name, scheduledGame.location_name, function () {});
                        }

                        for (var i = 0; i < gameResults.length; i++) {
                            var gameResult = gameResults[i];
                            helper.createSportsGameResult(sportDict.sport, gameResult.date, gameResult.opponent_name, gameResult.opponent_score, gameResult.home_score, function () {});
                        }
                    } else {
                        console.log(error);
                    }
                    if (counter >= sportsData.length - 1) {
                        console.log('Sports data parse completed.');
                        callback();
                    }
                    counter++;
                });
            });
        });
    });
}

//callsback with error and sportsEvents array of dictionaries
function getScheduledGamesAndResultFromURL(url, callback) {
    var scheduledGames = [];
    var gameResults = [];
    if (url) {
        jsdom.env({
            url: url,
            done: function (err, window) {
                if (err) console.error(err);
                global.document = window.document; //used in strip function

                var schedulesContent = window.document.getElementById('ep_tab_content_schedule'); //grab the area containing the schedules
                if (schedulesContent) {
                    var tables = schedulesContent.querySelectorAll('table.nwc_schedule'); //grab all schedule tables
                    var schoolYears = parseSchoolYears(schedulesContent.querySelectorAll('h3')[0].innerHTML);
                    if (schoolYears) {
                        for (var i = 0; i < tables.length; i++) {
                            var tableBody = tables[i].querySelectorAll('tbody')[0]; //grabs the one (hopefully) body for the current table
                            if (tableBody) {
                                var headerRows = tableBody.querySelectorAll('th'); //grab header info
                                var rows = tableBody.querySelectorAll('tr.nwc_schedule_row1, tr.nwc_schedule_row2'); //grab data rows
                                if (headerRows.length == 4) {
    //                                console.log(url + ': Post season.');
                                } else if (headerRows.length == 5) {
                                    if (strip(headerRows[3].innerHTML) == "Place / Result") {
    //                                    console.log(url + ': Postseason.');
                                    } else {
                                        var gameResult = createArrayOfResultDictionaries(rows, schoolYears);
                                        if (gameResult) {
                                            gameResults = gameResults.concat(gameResult);
                                        }
                                    }
                                } else if (headerRows.length == 6) {
                                    var scheduledGame = createArrayOfScheduledGameDictionaries(rows, schoolYears);
                                    if (scheduledGame) {
                                        scheduledGames = scheduledGames.concat(scheduledGame);
                                    }
                                }
                            }
                        }
                        callback(null, scheduledGames, gameResults);
                    } else {
                        callback('School years could not be parsed.', null, null);
                    }
                } else {
                    callback('Could not get html to parse.', null, null)
                }
            }
        });
    } else {
        callback('No data for given sport.', null, null);
    }
}

// Parses the two separate years from a years string (ex 2017-18 -> [2017, 2018]).
function parseSchoolYears(yearsString) {
    if (yearsString && yearsString.length >= 7) {
        var firstYear = parseInt(yearsString.substring(0, 4));
        var secondYear = parseInt(yearsString.substring(0, 2) + yearsString.substring(5, 7));
        if (!isNaN(firstYear) && !isNaN(secondYear)) {
            return [firstYear, secondYear];
        }
    }

    return null;
}

// Iterates through every result row and attempts to grab the correct data.
function createArrayOfResultDictionaries(rows, schoolYears) {
    var resultDictArray = [];
    for (var i = 0; i < rows.length; i++) {
        var itemsInRow = rows[i].querySelectorAll('td'); //grabs the columns from the row
        if (itemsInRow.length == 6) {
            var resultDict = parseNormalResultRow(itemsInRow, schoolYears);
            if (resultDict) {
                resultDictArray.push(resultDict);
            }
        } else if (itemsInRow.length == 5) {
            var resultDict = parseShortResultRow(itemsInRow, schoolYears);
            if (resultDict) {
                resultDictArray.push(resultDict);
            }
            i++; //force skip the next row bc it is related to this row but too hard to parse.
        }
    }

    return resultDictArray;
}

// Parses the information from a normal result row (6 items) into a result dictionary.
function parseNormalResultRow(itemsInRow, schoolYears) {
    if (itemsInRow.length == 6) {
        var resultDictionary = {}
        var dateString = strip(itemsInRow[2].innerHTML);
        var homeInfo = strip(itemsInRow[3].innerHTML).split(' '); //array with school name and score
        var opponentInfo = strip(itemsInRow[4].innerHTML).split(' '); //array with school name and score
        if (dateString) {
            resultDictionary['date'] = formattedDateString(dateString, null, schoolYears);
            if (homeInfo.length == 2) {
                resultDictionary['home_score'] = homeInfo[1];
            } else if (homeInfo.length == 3) {
                resultDictionary['home_score'] = homeInfo[2];
            } else {
                resultDictionary['home_score'] = -1;
            }
            if (opponentInfo.length == 2) {
                resultDictionary['opponent_name'] = opponentInfo[0];
                resultDictionary['opponent_score'] = opponentInfo[1];
            } else if (opponentInfo.length == 3) {
                resultDictionary['opponent_name'] = opponentInfo[0] + ' ' + opponentInfo[1];
                resultDictionary['opponent_score'] = opponentInfo[2];
            } else {
                resultDictionary['opponent_name'] = 'Multiple Opponents';
                resultDictionary['opponent_score'] = -1;
            }
            return resultDictionary;
        } else {
            return null; //date doesn't exist
        }
    } else {
        return null;
    }
}

// Parses the information from a short result row (5 items) into a result dictionary.
function parseShortResultRow(itemsInRow, schoolYears) {
    if (itemsInRow.length == 5) {
        var resultDictionary = {};
        var dateString = strip(itemsInRow[2].innerHTML);
        if (dateString) {
            resultDictionary['date'] = formattedDateString(dateString, null, schoolYears);
            resultDictionary['opponent_name'] = strip(itemsInRow[3].innerHTML); //name of event
            resultDictionary['home_score'] = -1;
            resultDictionary['opponent_score'] = -1;
            return resultDictionary;
        } else {
            return null; //date doesn't exist
        }
    } else {
        return null;
    }
}

function createArrayOfScheduledGameDictionaries(rows, schoolYears) {
    var scheduledGameDictArray = [];
    for (var i = 0; i < rows.length; i++) {
        var scheduledGameDict = {};
        var itemsInRow = rows[i].querySelectorAll('td'); //grabs the columns from the row
        if (itemsInRow.length == 7) {
            var dateString = strip(itemsInRow[1].innerHTML);
            var timeString = strip(itemsInRow[3].innerHTML);
            if (dateString) {
                scheduledGameDict['date'] = formattedDateString(dateString, timeString, schoolYears);
                scheduledGameDict['opponent_name'] = strip(itemsInRow[2].innerHTML);
                scheduledGameDict['location_name'] = strip(itemsInRow[5].innerHTML);
                scheduledGameDictArray.push(scheduledGameDict);
            }
        } else if (itemsInRow.length == 3) {
            var dateString = strip(itemsInRow[1].innerHTML);
            if (dateString) {
                scheduledGameDict['date'] = formattedDateString(dateString, null, schoolYears);
                scheduledGameDict['opponent_name'] = strip(itemsInRow[2].innerHTML); //name of event
                scheduledGameDict['location_name'] = '';
                i++; //force skip the next row bc it is related to this row but too hard to parse.
                scheduledGameDictArray.push(scheduledGameDict);
            }
        }
    }

    return scheduledGameDictArray;
}

// Creates a string formatted in the 'YYYY-MM-DD HH:MM:SS' format. Takes a date string (ddd, MMM DD), time string (h:mm a), and array of the two years the school year is in (ex [2017, 2018]).
function formattedDateString(dateString, timeString, schoolYears) {
    if (dateString && schoolYears) {
        var now = moment();
        var preFormatDateString = dateString + ' ' + now.year() + ' ' + (timeString || '12:00 AM');
        var date = moment(preFormatDateString, 'ddd, MMM DD YYYY h:mm a');
        if (date.isAfter(moment().month('Aug').date(1)) && date.isBefore(moment().month('Dec').date(31))) { // If event in first half of school year, then its year is the first of the given.
            date.year(schoolYears[0]);
        } else { // If event in second half of school year, then its year is the first of the given years.
            date.year(schoolYears[1]);
        }
        return date.format('YYYY-MM-DD HH:MM:SS');
    } else {
        return null; //something null or missing
    }
}

// Grabs the data out of the html element using the global DOCUMENT, so that must be set.
function strip(html) {
    if (html && document) {
        var tmp = document.createElement("DIV");
        tmp.innerHTML = html;
        return tmp.textContent || tmp.innerText;
    } else {
        return null;
    }
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
