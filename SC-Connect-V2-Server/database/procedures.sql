DELIMITER //


DROP PROCEDURE IF EXISTS RegisterClientByDeviceUUID //
CREATE PROCEDURE RegisterClientByDeviceUUID
(IN p_uuid VARCHAR(36))
BEGIN
  INSERT INTO clients (device_uuid)
  VALUES (p_uuid);
END //

DROP PROCEDURE IF EXISTS UpdatePushTokenOfClientByDeviceUUID //
CREATE PROCEDURE UpdatePushTokenOfClientByDeviceUUID
(IN p_uuid VARCHAR(36), p_push_token VARCHAR(64))
BEGIN
  UPDATE clients SET push_token = p_push_token
  WHERE device_uuid = p_uuid;
END //

DROP PROCEDURE IF EXISTS UpdateUserIDOfClientByID //
CREATE PROCEDURE UpdateUserIDOfClientByID
(IN p_client_id MEDIUMINT UNSIGNED, p_user_id MEDIUMINT UNSIGNED)
BEGIN
  UPDATE clients SET user_id = p_user_id
  WHERE client_id = p_client_id;
END //

DROP PROCEDURE IF EXISTS RemoveUserIDOfClientByID //
CREATE PROCEDURE RemoveUserIDOfClientByID
(IN p_client_id MEDIUMINT UNSIGNED)
BEGIN
  UPDATE clients SET user_id = null
  WHERE client_id = p_client_id;
END //

DROP PROCEDURE IF EXISTS FindClientByDeviceUUID//
CREATE PROCEDURE FindClientByDeviceUUID
(IN p_uuid VARCHAR(36))
BEGIN
  SELECT client_id, device_uuid, push_token, user_id
  FROM clients
  WHERE device_uuid = p_uuid;
END //

DROP PROCEDURE IF EXISTS FindClientsByUserID//
CREATE PROCEDURE FindClientsByUserID
(IN p_user_id MEDIUMINT UNSIGNED)
BEGIN
  SELECT client_id, device_uuid, push_token, user_id
  FROM clients
  WHERE user_id = p_user_id;
END //

DROP PROCEDURE IF EXISTS FindAllClients //
CREATE PROCEDURE FindAllClients
()
BEGIN
  SELECT client_id, device_uuid, push_token, user_id
  FROM clients;
END //

DROP PROCEDURE IF EXISTS RemoveClientByPushToken //
CREATE PROCEDURE RemoveClientByPushToken
(IN p_push_token VARCHAR(64))
BEGIN
  DELETE FROM clients
  WHERE push_token = p_push_token;
END //



DROP PROCEDURE IF EXISTS CreateUser //
CREATE PROCEDURE CreateUser
(IN p_google_id VARCHAR(64), p_email VARCHAR(50), p_first_name VARCHAR(45), p_last_name VARCHAR(45))
BEGIN
  INSERT INTO users (google_id, email, first_name, last_name)
  VALUES (p_google_id, p_email, p_first_name, p_last_name);

  SELECT user_id, google_id, email, first_name, last_name, moderator, admin, banned
  FROM users
  WHERE user_id = LAST_INSERT_ID();
END //

DROP PROCEDURE IF EXISTS FindUserByGoogleID //
CREATE PROCEDURE FindUserByGoogleID
(IN p_google_id VARCHAR(64))
BEGIN
  SELECT user_id, google_id, email, first_name, last_name, moderator, admin, banned
  FROM users
  WHERE google_id = p_google_id AND banned = FALSE;
END //

DROP PROCEDURE IF EXISTS FindUserByUserID //
CREATE PROCEDURE FindUserByUserID
(IN p_user_id MEDIUMINT UNSIGNED)
BEGIN
  SELECT user_id, google_id, email, first_name, last_name, moderator, admin, banned
  FROM users
  WHERE user_id = p_user_id AND banned = FALSE;
END //

DROP PROCEDURE IF EXISTS FindUserByEmail //
CREATE PROCEDURE FindUserByEmail
(IN p_email VARCHAR(50))
BEGIN
  SELECT user_id, google_id, email, first_name, last_name, moderator, admin, banned
  FROM users
  WHERE email = p_email AND banned = FALSE;
END //

DROP PROCEDURE IF EXISTS FindAllModerators //
CREATE PROCEDURE FindAllModerators
()
BEGIN
  SELECT user_id, google_id, email, first_name, last_name, moderator, admin, banned
  FROM users
  WHERE moderator = TRUE AND banned = FALSE;
END //

DROP PROCEDURE IF EXISTS DemoteModeratorByID //
CREATE PROCEDURE DemoteModeratorByID
(IN p_moderator_id MEDIUMINT UNSIGNED)
BEGIN
  UPDATE users
  SET moderator = FALSE
  WHERE user_id = p_moderator_id;
END //

DROP PROCEDURE IF EXISTS PromoteUserByID //
CREATE PROCEDURE PromoteUserByID
(IN p_user_id MEDIUMINT UNSIGNED)
BEGIN
  UPDATE users
  SET moderator = TRUE
  WHERE user_id = p_user_id;
END //




DROP PROCEDURE IF EXISTS SubscribeUserToTag //
CREATE PROCEDURE SubscribeUserToTag
(IN p_tag_name VARCHAR(8), p_user_id MEDIUMINT UNSIGNED)
BEGIN
  INSERT INTO subscriptions (tag_name, user_id)
  VALUES (p_tag_name, p_user_id);
END //

DROP PROCEDURE IF EXISTS UnsubscribeUserFromTag //
CREATE PROCEDURE UnsubscribeUserFromTag
(IN p_tag_name VARCHAR(8), p_user_id MEDIUMINT UNSIGNED)
BEGIN
  DELETE FROM subscriptions
  WHERE tag_name = p_tag_name AND user_id = p_user_id;
END //

DROP PROCEDURE IF EXISTS FindSubscriptionByTagNameAndUserID //
CREATE PROCEDURE FindSubscriptionByTagNameAndUserID
(IN p_tag_name VARCHAR(8), p_user_id MEDIUMINT UNSIGNED)
BEGIN
  SELECT subscription_id, user_id, tag_name, notify
  FROM subscriptions
  WHERE tag_name = p_tag_name AND user_id = p_user_id;
END //

DROP PROCEDURE IF EXISTS FindAllSubscriptionsOfUserByID //
CREATE PROCEDURE FindAllSubscriptionsOfUserByID
(IN p_user_id MEDIUMINT UNSIGNED)
BEGIN
  SELECT subscription_id, user_id, tag_name, notify
  FROM subscriptions
  WHERE user_id = p_user_id;
END //

DROP PROCEDURE IF EXISTS FindAllSubscribedUsersByTagName //
CREATE PROCEDURE FindAllSubscribedUsersByTagName
(IN p_tag_name VARCHAR(8))
BEGIN
  SELECT users.user_id, users.google_id, users.email, users.first_name, users.last_name, users.moderator, users.admin, users.banned
  FROM subscriptions
  JOIN users
  ON subscriptions.user_id = users.user_id
  WHERE subscriptions.tag_name = p_tag_name;
END //



DROP PROCEDURE IF EXISTS CreateLeaderboardScoreForUserByID //
CREATE PROCEDURE CreateLeaderboardScoreForUserByID
(IN p_user_id MEDIUMINT UNSIGNED, p_graduation_year MEDIUMINT UNSIGNED, p_leaderboard_score INT)
BEGIN
  INSERT INTO leaderboard_scores (user_id, graduation_year, leaderboard_score)
  VALUES (p_user_id, p_graduation_year, p_leaderboard_score);
END //

DROP PROCEDURE IF EXISTS UpdateLeaderboardScoreForUserByID //
CREATE PROCEDURE UpdateLeaderboardScoreForUserByID
(IN p_user_id MEDIUMINT UNSIGNED, p_graduation_year MEDIUMINT UNSIGNED, p_leaderboard_score INT)
BEGIN
  UPDATE leaderboard_scores
  SET leaderboard_score = p_leaderboard_score, graduation_year = p_graduation_year
  WHERE user_id = p_user_id;
END //

DROP PROCEDURE IF EXISTS FindLeaderboardScoreByUserID //
CREATE PROCEDURE FindLeaderboardScoreByUserID
(IN p_user_id MEDIUMINT UNSIGNED)
BEGIN
  SELECT leaderboard_score_id, user_id, graduation_year, leaderboard_score
  FROM leaderboard_scores
  WHERE user_id = p_user_id;
END //

DROP PROCEDURE IF EXISTS FindAllLeaderboardScores //
CREATE PROCEDURE FindAllLeaderboardScores
()
BEGIN
  SELECT leaderboard_scores.leaderboard_score_id, leaderboard_scores.user_id, leaderboard_scores.graduation_year, leaderboard_scores.leaderboard_score, users.first_name, users.last_name
  FROM leaderboard_scores
  JOIN users
  ON leaderboard_scores.user_id = users.user_id;
END //

DROP PROCEDURE IF EXISTS TotalLeaderboardPointsByGraduationYear //
CREATE PROCEDURE TotalLeaderboardPointsByGraduationYear
(IN p_graduation_year MEDIUMINT UNSIGNED)
BEGIN
  SELECT SUM(leaderboard_score)
  FROM leaderboard_scores
  WHERE graduation_year = p_graduation_year;
END //

DROP PROCEDURE IF EXISTS DeleteAllLeaderboardScores //
CREATE PROCEDURE DeleteAllLeaderboardScores
()
BEGIN
  DELETE FROM leaderboard_scores;
END //



DROP PROCEDURE IF EXISTS CreateTagByName //
CREATE PROCEDURE CreateTagByName
(IN p_tag_name VARCHAR(8), p_color_index TINYINT UNSIGNED)
BEGIN
  INSERT INTO tags (tag_name, color_index)
  VALUES (p_tag_name, p_color_index);

  SELECT tag_id, tag_name, color_index, message_count, visible
  FROM tags
  WHERE tag_id = LAST_INSERT_ID();
END //

DROP PROCEDURE IF EXISTS TopTenTags //
CREATE PROCEDURE TopTenTags
()
BEGIN
  SELECT tag_id, tag_name, color_index, message_count, visible
  FROM tags
  WHERE visible = TRUE
  ORDER BY last_update DESC
  LIMIT 10;
END //

DROP PROCEDURE IF EXISTS FindAllTags //
CREATE PROCEDURE FindAllTags
()
BEGIN
  SELECT tag_id, tag_name, color_index, message_count, visible
  FROM tags
  WHERE visible = TRUE;
END //

DROP PROCEDURE IF EXISTS FindTagByName //
CREATE PROCEDURE FindTagByName
(IN p_tag_name VARCHAR(8))
BEGIN
  SELECT tag_id, tag_name, color_index, message_count, visible
  FROM tags
  WHERE tag_name = p_tag_name AND visible = TRUE;
END //

DROP PROCEDURE IF EXISTS TagsContainingSearchTerm //
CREATE PROCEDURE TagsContainingSearchTerm
(IN p_search_term VARCHAR(10))
BEGIN
  SELECT tag_id, tag_name, color_index, message_count, visible
  FROM tags
  WHERE tag_name LIKE p_search_term AND visible = TRUE;
END //

DROP PROCEDURE IF EXISTS SubscriberCountOfTagByName //
CREATE PROCEDURE SubscriberCountOfTagByName
(IN p_tag_name VARCHAR(8))
BEGIN
  SELECT COUNT(*)
  FROM subscriptions
  WHERE tag_name = p_tag_name;
END //

DROP PROCEDURE IF EXISTS UpdateColorOfTagByName //
CREATE PROCEDURE UpdateColorOfTagByName
(IN p_tag_name VARCHAR(8), p_color_index TINYINT UNSIGNED)
BEGIN
  UPDATE tags 
  SET color_index = p_color_index
  WHERE tag_name = p_tag_name AND visible = TRUE;
END //

DROP PROCEDURE IF EXISTS HideTagByName //
CREATE PROCEDURE HideTagByName
(IN p_tag_name VARCHAR(8), p_moderator_id MEDIUMINT UNSIGNED)
BEGIN
  UPDATE tags
  SET visible = FALSE, removed_by_user_id = p_moderator_id
  WHERE tag_name = p_tag_name;
END //





DROP PROCEDURE IF EXISTS CreateMessage //
CREATE PROCEDURE CreateMessage
(IN p_user_id MEDIUMINT UNSIGNED, p_tag_name VARCHAR(8), p_message_body VARCHAR(512))
BEGIN
  INSERT INTO messages (user_id, tag_name, message)
  VALUES (p_user_id, p_tag_name, p_message_body);

  UPDATE users SET message_count = message_count + 1
  WHERE user_id = p_user_id;

  UPDATE tags SET message_count = message_count + 1
  WHERE tag_name = p_tag_name;

  SELECT messages.message_id, messages.post_date, messages.message, messages.tag_name, messages.user_id, messages.notification_pushed, messages.flagged, messages.visible, users.first_name, users.last_name
  FROM messages
  JOIN users
  ON messages.user_id = users.user_id
  WHERE messages.message_id = LAST_INSERT_ID();
END //

DROP PROCEDURE IF EXISTS LatestMessagesFromTagByName //
CREATE PROCEDURE LatestMessagesFromTagByName
(IN p_tag_name VARCHAR(8))
BEGIN
  SELECT messages.message_id, messages.post_date, messages.message, messages.tag_name, messages.user_id, messages.notification_pushed, messages.flagged, messages.visible, users.first_name, users.last_name
  FROM messages
  JOIN users
  ON messages.user_id = users.user_id
  WHERE messages.tag_name = p_tag_name AND messages.visible = TRUE
  ORDER BY messages.message_id DESC
  LIMIT 30;
END //

DROP PROCEDURE IF EXISTS LastMessageFromTagByName //
CREATE PROCEDURE LastMessageFromTagByName
(IN p_tag_name VARCHAR(8))
BEGIN
  SELECT messages.message_id, messages.post_date, messages.message, messages.tag_name, messages.user_id, messages.notification_pushed, messages.flagged, messages.visible, users.first_name, users.last_name
  FROM messages
  JOIN users
  ON messages.user_id = users.user_id
  WHERE messages.tag_name = p_tag_name AND messages.visible = TRUE
  ORDER BY messages.message_id DESC
  LIMIT 1;
END //

DROP PROCEDURE IF EXISTS MessagesBeforeMessageByID //
CREATE PROCEDURE MessagesBeforeMessageByID
(IN p_tag_name VARCHAR(8), p_message_id INT UNSIGNED)
BEGIN
  SELECT messages.message_id, messages.post_date, messages.message, messages.tag_name, messages.user_id, messages.notification_pushed, messages.flagged, messages.visible, users.first_name, users.last_name
  FROM messages
  JOIN users
  ON messages.user_id = users.user_id
  WHERE messages.tag_name = p_tag_name AND messages.message_id < p_message_id AND messages.visible = TRUE
  ORDER BY messages.message_id DESC
  LIMIT 20;
END //

DROP PROCEDURE IF EXISTS MessagesAfterMessageByID //
CREATE PROCEDURE MessagesAfterMessageByID
(IN p_tag_name VARCHAR(8), p_message_id INT UNSIGNED)
BEGIN
  SELECT messages.message_id, messages.post_date, messages.message, messages.tag_name, messages.user_id, messages.notification_pushed, messages.flagged, messages.visible, users.first_name, users.last_name
  FROM messages
  JOIN users
  ON messages.user_id = users.user_id
  WHERE messages.tag_name = p_tag_name AND messages.message_id > p_message_id AND messages.visible = TRUE
  ORDER BY messages.message_id DESC;
END //

DROP PROCEDURE IF EXISTS FindMessageByID //
CREATE PROCEDURE FindMessageByID
(IN p_message_id INT UNSIGNED)
BEGIN
  SELECT messages.message_id, messages.post_date, messages.message, messages.tag_name, messages.user_id, messages.notification_pushed, messages.flagged, messages.visible, users.first_name, users.last_name
  FROM messages
  JOIN users
  ON messages.user_id = users.user_id
  WHERE messages.message_id = p_message_id AND messages.visible = TRUE;
END //

DROP PROCEDURE IF EXISTS FlagMessageByID //
CREATE PROCEDURE FlagMessageByID
(IN p_message_id INT UNSIGNED)
BEGIN
  UPDATE messages
  SET flagged = TRUE
  WHERE message_id = p_message_id;
END //

DROP PROCEDURE IF EXISTS UnflagMessageByID //
CREATE PROCEDURE UnflagMessageByID
(IN p_message_id INT UNSIGNED)
BEGIN
  UPDATE messages
  SET flagged = FALSE
  WHERE message_id = p_message_id;
END //

DROP PROCEDURE IF EXISTS FindAllFlaggedMessages //
CREATE PROCEDURE FindAllFlaggedMessages
()
BEGIN
  SELECT messages.message_id, messages.post_date, messages.message, messages.tag_name, messages.user_id, messages.notification_pushed, messages.flagged, messages.visible, users.first_name, users.last_name
  FROM messages
  JOIN users
  ON messages.user_id = users.user_id
  WHERE messages.flagged = TRUE AND messages.visible = TRUE;
END //

DROP PROCEDURE IF EXISTS HideMessageByID //
CREATE PROCEDURE HideMessageByID
(IN p_message_id INT UNSIGNED, p_moderator_id MEDIUMINT UNSIGNED)
BEGIN
  UPDATE messages
  SET visible = FALSE, removed_by_user_id = p_moderator_id
  WHERE message_id = p_message_id;
END //



DROP PROCEDURE IF EXISTS CreateEvent //
CREATE PROCEDURE CreateEvent
(IN p_event_name VARCHAR (256), p_user_id MEDIUMINT UNSIGNED, p_start_date DATETIME, p_end_date DATETIME, p_location_name VARCHAR(32), p_location_address VARCHAR(256), p_location_latitude FLOAT, p_location_longitude FLOAT, p_leaderboard_points SMALLINT)
BEGIN
  INSERT INTO events (event_name, user_id, start_date, end_date, location_name, location_address, location_latitude, location_longitude, leaderboard_points)
  VALUES (p_event_name, p_user_id, p_start_date, p_end_date, p_location_name, p_location_address, p_location_latitude, p_location_longitude, p_leaderboard_points);
  SELECT event_id, event_name, user_id, create_date, start_date, end_date, location_name, location_address, location_latitude, location_longitude, leaderboard_points, visible
  FROM events
  WHERE event_id = LAST_INSERT_ID() AND visible = TRUE;
END //

DROP PROCEDURE IF EXISTS CheckInUserToEvent //
CREATE PROCEDURE CheckInUserToEvent
(IN p_event_id INT UNSIGNED, p_user_id INT UNSIGNED)
BEGIN
  INSERT INTO check_ins (event_id, user_id)
  VALUES (p_event_id, p_user_id);
END //

DROP PROCEDURE IF EXISTS FutureEvents //
CREATE PROCEDURE FutureEvents
()
BEGIN
  SELECT event_id, event_name, start_date, end_date, location_name, location_address, location_latitude, location_longitude, leaderboard_points, visible
  FROM events
  WHERE end_date > NOW() AND visible = TRUE
  ORDER BY start_date DESC;
END //

DROP PROCEDURE IF EXISTS FindEventByID //
CREATE PROCEDURE FindEventByID
(IN p_event_id INT UNSIGNED)
BEGIN
  SELECT event_id, event_name, start_date, end_date, location_name, location_address, location_latitude, location_longitude, leaderboard_points, visible
  FROM events
  WHERE event_id = p_event_id;
END //




DROP PROCEDURE IF EXISTS EventCheckInCount //
CREATE PROCEDURE EventCheckInCount
(IN p_event_id INT UNSIGNED)
BEGIN
  SELECT COUNT(*)
  FROM check_ins
  WHERE event_id = p_event_id;
END //

DROP PROCEDURE IF EXISTS FindCheckInByEventAndUserID //
CREATE PROCEDURE FindCheckInByEventAndUserID
(IN p_event_id INT UNSIGNED, p_user_id INT UNSIGNED)
BEGIN
  SELECT check_ins.check_in_id, check_ins.check_in_date, check_ins.event_id, check_ins.user_id, users.first_name, users.last_name
  FROM check_ins
  JOIN users
  ON check_ins.user_id = users.user_id
  WHERE check_ins.event_id = p_event_id AND check_ins.user_id = p_user_id;
END //

DROP PROCEDURE IF EXISTS FindCheckInsByEventID //
CREATE PROCEDURE FindCheckInsByEventID
(IN p_event_id INT UNSIGNED)
BEGIN
  SELECT check_ins.check_in_id, check_ins.check_in_date, check_ins.event_id, check_ins.user_id, users.first_name, users.last_name
  FROM check_ins
  JOIN users
  ON check_ins.user_id = users.user_id
  WHERE check_ins.event_id = p_event_id;
END //




DROP PROCEDURE IF EXISTS CreateScheduledSportsGame //
CREATE PROCEDURE CreateScheduledSportsGame
(IN p_sport_name varchar(64), p_game_date DATETIME, p_opponent_name varchar(128), p_location_name varchar(64))
BEGIN
  INSERT INTO scheduled_sports_games (sport_name, game_date, opponent_name, location_name)
  VALUES (p_sport_name, p_game_date, p_opponent_name, p_location_name);
END //

DROP PROCEDURE IF EXISTS FindScheduledGamesForSportByName //
CREATE PROCEDURE FindScheduledGamesForSportByName
(IN p_sport_name varchar(64))
BEGIN
  SELECT scheduled_sports_game_id, sport_name, game_date, opponent_name, location_name
  FROM scheduled_sports_games
  WHERE sport_name = p_sport_name;
END //

DROP PROCEDURE IF EXISTS FindAllScheduledGames //
CREATE PROCEDURE FindAllScheduledGames
()
BEGIN
  SELECT scheduled_sports_game_id, sport_name, game_date, opponent_name, location_name
  FROM scheduled_sports_games;
END //

DROP PROCEDURE IF EXISTS DeleteAllScheduledSportsGames //
CREATE PROCEDURE DeleteAllScheduledSportsGames
()
BEGIN
  DELETE FROM scheduled_sports_games;
END //



DROP PROCEDURE IF EXISTS CreateSportsGameResult //
CREATE PROCEDURE CreateSportsGameResult
(IN p_sport_name varchar(64), p_game_date DATETIME, p_opponent_name varchar(128), p_opponent_score INT, p_home_score INT)
BEGIN
  INSERT INTO sports_game_results (sport_name, game_date, opponent_name, opponent_score, home_score)
  VALUES (p_sport_name, p_game_date, p_opponent_name, p_opponent_score, p_home_score);
END //

DROP PROCEDURE IF EXISTS FindGameResultsForSportByName //
CREATE PROCEDURE FindGameResultsForSportByName
(IN p_sport_name varchar(64))
BEGIN
  SELECT sports_game_result_id, sport_name, game_date, opponent_name, opponent_score, home_score
  FROM sports_game_results
  WHERE sport_name = p_sport_name;
END //

DROP PROCEDURE IF EXISTS FindAllGameResults //
CREATE PROCEDURE FindAllGameResults
()
BEGIN
  SELECT sports_game_result_id, sport_name, game_date, opponent_name, opponent_score, home_score
  FROM sports_game_results;
END //

DROP PROCEDURE IF EXISTS DeleteAllSportsGameResults //
CREATE PROCEDURE DeleteAllSportsGameResults
()
BEGIN
  DELETE FROM sports_game_results;
END //



DROP PROCEDURE IF EXISTS CreateFanCamRecord //
CREATE PROCEDURE CreateFanCamRecord
(IN p_image_aws_key varchar(64), p_user_id MEDIUMINT UNSIGNED)
BEGIN
  INSERT INTO fan_cam_records (image_aws_key, user_id)
  VALUES (p_image_aws_key, p_user_id);
END //

DROP PROCEDURE IF EXISTS FindAllFanCamRecords //
CREATE PROCEDURE FindAllFanCamRecords
()
BEGIN
  SELECT record_id, create_date, image_aws_key, user_id, visible
  FROM fan_cam_records
  WHERE visible = TRUE;
END //

DROP PROCEDURE IF EXISTS FindFanCamRecordByID //
CREATE PROCEDURE FindFanCamRecordByID
(IN p_record_id INT UNSIGNED)
BEGIN
  SELECT record_id, create_date, image_aws_key, user_id, visible
  FROM fan_cam_records
  WHERE record_id = p_record_id AND visible = TRUE;
END //

DROP PROCEDURE IF EXISTS HideFanCamRecordByID //
CREATE PROCEDURE HideFanCamRecordByID
(IN p_record_id INT UNSIGNED, p_moderator_id MEDIUMINT UNSIGNED)
BEGIN
  UPDATE fan_cam_records
  SET visible = FALSE, removed_by_user_id = p_moderator_id
  WHERE record_id = p_record_id;
END //



DROP PROCEDURE IF EXISTS CreateClub //
CREATE PROCEDURE CreateClub
(IN p_club_name varchar(64), p_associated_tag_name VARCHAR(8), p_club_leaders varchar(256), p_meeting_days VARCHAR(128), p_meeting_time VARCHAR(64), p_meeting_location VARCHAR(64))
BEGIN
  INSERT INTO clubs (club_name, associated_tag_name, club_leaders, meeting_days, meeting_time, meeting_location)
  VALUES (p_club_name, p_associated_tag_name, p_club_leaders, p_meeting_days, p_meeting_time, p_meeting_location);
  SELECT club_id, create_date, club_name, associated_tag_name, club_leaders, meeting_days, meeting_time, meeting_location
  FROM clubs
  WHERE club_id = LAST_INSERT_ID();
END //

DROP PROCEDURE IF EXISTS UpdateClub //
CREATE PROCEDURE UpdateClub
(IN p_club_id INT UNSIGNED, p_club_name varchar(64), p_associated_tag_name VARCHAR(8), p_club_leaders varchar(256), p_meeting_days VARCHAR(128), p_meeting_time VARCHAR(64), p_meeting_location VARCHAR(64))
BEGIN
  UPDATE clubs
  SET club_name = p_club_name, associated_tag_name = p_associated_tag_name, club_leaders = p_club_leaders, meeting_days = p_meeting_days, meeting_time = p_meeting_time, meeting_location = p_meeting_location
  WHERE club_id = p_club_id;
END //

DROP PROCEDURE IF EXISTS FindClubByID //
CREATE PROCEDURE FindClubByID
(IN p_club_id INT UNSIGNED)
BEGIN
  SELECT club_id, create_date, club_name, associated_tag_name, club_leaders, meeting_days, meeting_time, meeting_location
  FROM clubs
  WHERE club_id = p_club_id;
END //

DROP PROCEDURE IF EXISTS FindAllClubs //
CREATE PROCEDURE FindAllClubs
()
BEGIN
  SELECT club_id, create_date, club_name, associated_tag_name, club_leaders, meeting_days, meeting_time, meeting_location
  FROM clubs;
END //

DROP PROCEDURE IF EXISTS DeleteClubByID //
CREATE PROCEDURE DeleteClubByID
(IN p_club_id INT UNSIGNED)
BEGIN
  DELETE FROM clubs
  WHERE club_id = p_club_id;
END //

DELIMITER ;