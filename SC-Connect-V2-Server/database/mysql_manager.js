var mysql = require('mysql'); //for database
var mysqlConfig = require('../config/database_config');

//mysql db connection
var connection = mysql.createConnection(mysqlConfig);
connection.connect(function(err) {
    if (err) throw err;
    console.log('Connected to MySQL database successfully.');
})

exports.runProcedure = function(procedure_name, params, callback) {
    var query = 'CALL ' + procedure_name + '(';
    for (var i = 0; i < params.length; i++) {
        query += exports.escape(params[i]);
        if (i < params.length - 1) query += ',';
    }
    query += ');';
    connection.query(query, function(err, rows, fields) {
        if (err) throw err;
        callback(rows[0]); //rows 0 is the actual data bc data was put in an array alongside some other info (only true for procs)
    });
};

exports.query = function(queryString, callback) {
    connection.query(queryString, function(err, rows, fields) {
        if (err) throw err;
        callback(rows);
    });
};

exports.escape = function(object) {
    return mysql.escape(object);
}
