global.helper = require('./routes/routes_helper'); //helper functions for interacting with database that is global so only one instance exists (means only one connection to db as well)
var expressApp = require('express')();
var sports = require('./sports/sports-parsing'); // Parses sports and sends notifications about sporting events
var events = require('./events/events'); // Sends notifications about upcoming events
const httpPort = process.env.PORT || 3000;

//basic middleware
expressApp.use(require('morgan')('common')); //logs all requests like standard apache logs
expressApp.use('/', express.static('public'));
expressApp.use(require('body-parser').json()); //parses json body into js data structure before hits routes
expressApp.use(function(req, res, next) { //log the entire body of post requests
    for (var key in req.body) {
        console.log('     Key: ' + key + ', Value: ' + req.body[key]);
    }
    next();
});

//routes
require('./routes/sc-connect-api')(expressApp); //all SC Connect API calls

//anything not directed above is out
expressApp.get('*', function(req, res) { //after routes because it should be called if nothing else found
    res.status(404);
    res.end('404 - Page Not Found');
});

var expressServer = expressApp.listen(httpPort, function() {
    console.log('SC Connect listening on port ' + httpPort + '.');
});

// Socket IO
var io = require('socket.io').listen(expressServer);
console.log('SC Connect socket io listening on port ' + httpPort + '.');

//Socket Handlers
require('./routes/sockets')(io);
