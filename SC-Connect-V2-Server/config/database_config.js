module.exports = {
    host: "localhost",
    user: "root",
    password: "password",
    port: 3306,
    database: "scconnect3",
    multipleStatements: true, // Other settings
    connectionLimit: 20,
    queueLimit: 5000,
    charset: "utf8mb4" // Allows emojis
};

/** For AWS
    host: process.env.RDS_HOSTNAME, //Elastic Beanstalk environment variables
    user: process.env.RDS_USERNAME,
    password: process.env.RDS_PASSWORD,
    port: process.env.RDS_PORT,
    database: process.env.RDS_DB_NAME,
  */
