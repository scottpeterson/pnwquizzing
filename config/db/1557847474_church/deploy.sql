-- dest.prereq: config/db/1553271300_user

CREATE TABLE IF NOT EXISTS church (
    church_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT DEFAULT NULL UNIQUE,
    acronym TEXT DEFAULT NULL UNIQUE,
    created TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) ),
    active INTEGER NOT NULL DEFAULT 1
);

INSERT INTO church ( name, acronym ) VALUES ( "PNW Theological Institute", "PNWTI" );

DROP TRIGGER IF EXISTS update_user_last_modified;

ALTER TABLE user RENAME TO _user;

CREATE TABLE IF NOT EXISTS user (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    church_id INTEGER DEFAULT NULL REFERENCES church(church_id),
    username TEXT DEFAULT NULL UNIQUE,
    passwd TEXT DEFAULT NULL,
    first_name TEXT DEFAULT NULL,
    last_name TEXT DEFAULT NULL,
    email TEXT DEFAULT NULL UNIQUE,
    last_login TEXT NULL DEFAULT NULL,
    last_modified TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) ),
    created TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) ),
    active INTEGER NOT NULL DEFAULT 1
);

INSERT INTO user SELECT
    user_id,
    NULL,
    username,
    passwd,
    first_name,
    last_name,
    email,
    last_login,
    last_modified,
    created,
    active
FROM _user;

DROP TABLE _user;

CREATE TRIGGER IF NOT EXISTS update_user_last_modified BEFORE update ON user
BEGIN
    UPDATE user SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' )
    WHERE user_id = old.user_id;
END;
