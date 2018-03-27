SET NAMES utf8mb4;

CREATE DATABASE scconnect
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE TABLE clients (
  client_id MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
  device_uuid varchar(36) NOT NULL,
  push_token varchar(64),
  user_id MEDIUMINT UNSIGNED,
  PRIMARY KEY (client_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE users (
  user_id MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
  google_id varchar(64) NOT NULL,
  email VARCHAR(50) NOT NULL,
  first_name VARCHAR(45) NOT NULL,
  last_name VARCHAR(45) NOT NULL,
  moderator BOOLEAN NOT NULL DEFAULT FALSE,
  admin BOOLEAN NOT NULL DEFAULT FALSE,
  message_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  create_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  banned BOOLEAN NOT NULL DEFAULT FALSE,
  banned_by_user_id MEDIUMINT UNSIGNED,
  PRIMARY KEY (user_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE messages (
  message_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  message VARCHAR(512) NOT NULL,
  tag_name VARCHAR(8) NOT NULL,
  user_id MEDIUMINT UNSIGNED NOT NULL,
  notification_pushed BOOLEAN NOT NULL DEFAULT FALSE,
  flagged BOOLEAN NOT NULL DEFAULT FALSE,
  visible BOOLEAN NOT NULL DEFAULT TRUE,
  removed_by_user_id MEDIUMINT UNSIGNED,
  PRIMARY KEY (message_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE tags (
  tag_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tag_name VARCHAR(8) NOT NULL,
  color_index TINYINT UNSIGNED NOT NULL,
  message_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  create_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  visible BOOLEAN NOT NULL DEFAULT TRUE,
  removed_by_user_id MEDIUMINT UNSIGNED,
  PRIMARY KEY (tag_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE subscriptions (
  subscription_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id MEDIUMINT UNSIGNED NOT NULL,
  tag_name VARCHAR(8) NOT NULL,
  notify BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (subscription_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE clubs (
  club_id INT NOT NULL AUTO_INCREMENT,
  club_name varchar(128) NOT NULL,
  meeting_location varchar(64) NOT NULL,
  opponent_name varchar(128) NOT NULL,
  opponent_score INT NOT NULL,
  home_score INT NOT NULL,
  PRIMARY KEY (sports_game_result_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE leaderboard_scores (
  leaderboard_score_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id MEDIUMINT NOT NULL,
  graduation_year MEDIUMINT UNSIGNED NOT NULL,
  leaderboard_score INT NOT NULL,
  PRIMARY KEY (leaderboard_score_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE events (
  event_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_name VARCHAR(256) NOT NULL,
  user_id MEDIUMINT UNSIGNED NOT NULL,
  create_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  start_date DATETIME NOT NULL,
  end_date DATETIME NOT NULL,
  location_name VARCHAR(32) NOT NULL,
  location_address VARCHAR(256) NOT NULL,
  location_latitude FLOAT NOT NULL,
  location_longitude FLOAT NOT NULL,
  leaderboard_points SMALLINT NOT NULL,
  visible BOOLEAN NOT NULL DEFAULT TRUE,
  removed_by_user_id MEDIUMINT UNSIGNED,
  PRIMARY KEY (event_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE check_ins (
  check_in_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  check_in_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  event_id INT UNSIGNED NOT NULL,
  user_id MEDIUMINT UNSIGNED NOT NULL,
  PRIMARY KEY (check_in_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE scheduled_sports_games (
  scheduled_sports_game_id INT NOT NULL AUTO_INCREMENT,
  sport_name varchar(64) NOT NULL,
  game_date DATETIME NOT NULL,
  opponent_name varchar(128) NOT NULL,
  location_name varchar(64) NOT NULL,
  PRIMARY KEY (scheduled_sports_game_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE sports_game_results (
  sports_game_result_id INT NOT NULL AUTO_INCREMENT,
  sport_name varchar(64) NOT NULL,
  game_date DATETIME NOT NULL,
  opponent_name varchar(128) NOT NULL,
  opponent_score INT NOT NULL,
  home_score INT NOT NULL,
  PRIMARY KEY (sports_game_result_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE fan_cam_records (
  record_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  create_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  image_aws_key VARCHAR(64) NOT NULL,
  user_id MEDIUMINT UNSIGNED NOT NULL,
  visible BOOLEAN NOT NULL DEFAULT TRUE,
  removed_by_user_id MEDIUMINT UNSIGNED,
  PRIMARY KEY (record_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE clubs (
  club_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  create_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  club_name VARCHAR(64) NOT NULL,
  associated_tag_name VARCHAR(8) NOT NULL,
  club_leaders VARCHAR(256) NOT NULL,
  meeting_days VARCHAR(128) NOT NULL,
  meeting_time VARCHAR(64) NOT NULL,
  meeting_location VARCHAR(64) NOT NULL,
  PRIMARY KEY (club_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;