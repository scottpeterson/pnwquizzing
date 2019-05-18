-- dest.prereq: config/db/1557847474_church

CREATE TABLE IF NOT EXISTS schedule (
    schedule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    meet TEXT DEFAULT NULL,
    location TEXT DEFAULT NULL,
    address TEXT DEFAULT NULL,
    address_url TEXT DEFAULT NULL,
    start TEXT DEFAULT NULL,
    deadline TEXT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS schedule_church (
    schedule_church_id INTEGER PRIMARY KEY AUTOINCREMENT,
    schedule_id INTEGER DEFAULT NULL REFERENCES schedule(schedule_id),
    church_id INTEGER DEFAULT NULL REFERENCES church(church_id),
    last_modified TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) ),
    created TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) )
);

CREATE TRIGGER IF NOT EXISTS update_schedule_church_last_modified BEFORE update ON schedule_church
BEGIN
    UPDATE schedule_church SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' )
    WHERE schedule_church_id = old.schedule_church_id;
END;

CREATE TABLE IF NOT EXISTS registration (
    registration_id INTEGER PRIMARY KEY AUTOINCREMENT,
    church_id INTEGER DEFAULT NULL REFERENCES church(church_id),
    team TEXT DEFAULT NULL,
    name TEXT DEFAULT NULL,
    bib INTEGER DEFAULT NULL,
    role TEXT DEFAULT NULL,
    m_f TEXT DEFAULT NULL,
    grade INTEGER DEFAULT NULL,
    rookie INTEGER DEFAULT NULL,
    attend INTEGER DEFAULT NULL,
    house INTEGER DEFAULT NULL,
    lunch INTEGER DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    last_modified TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) ),
    created TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) )
);

CREATE TRIGGER IF NOT EXISTS update_registration_last_modified BEFORE update ON registration
BEGIN
    UPDATE registration SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' )
    WHERE registration_id = old.registration_id;
END;
