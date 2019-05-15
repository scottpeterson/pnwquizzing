-- dest.prereq: config/db/1553271300_user

CREATE TABLE IF NOT EXISTS role (
    role_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT DEFAULT NULL UNIQUE,
    created TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) ),
    active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS user_role (
    user_role_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER DEFAULT NULL REFERENCES user(user_id),
    role_id INTEGER DEFAULT NULL REFERENCES role(role_id),
    created TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) )
);

INSERT INTO role (name) VALUES
    ("Coach"),
    ("Quizzer"),
    ("Parent"),
    ("Volunteer"),
    ("Official"),
    ("Board"),
    ("Spectator");
