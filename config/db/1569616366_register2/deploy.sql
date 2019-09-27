-- dest.prereq: config/db/1558031082_registration

DROP TRIGGER IF EXISTS update_registration_last_modified;

ALTER TABLE registration RENAME TO _registration;

CREATE TABLE IF NOT EXISTS registration (
    registration_id INTEGER PRIMARY KEY AUTOINCREMENT,
    church_id INTEGER DEFAULT NULL REFERENCES church(church_id),
    team TEXT DEFAULT NULL,
    name TEXT DEFAULT NULL,
    bib INTEGER DEFAULT NULL,
    captain TEXT DEFAULT NULL,
    role TEXT DEFAULT NULL,
    m_f TEXT DEFAULT NULL,
    grade INTEGER DEFAULT NULL,
    rookie INTEGER DEFAULT NULL,
    attend INTEGER DEFAULT NULL,
    drive INTEGER DEFAULT NULL,
    house INTEGER DEFAULT NULL,
    lunch INTEGER DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    last_modified TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) ),
    created TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' ) )
);

INSERT INTO registration SELECT
    registration_id,
    church_id,
    team,
    name,
    bib,
    NULL,
    role,
    m_f,
    grade,
    rookie,
    attend,
    NULL,
    house,
    lunch,
    notes,
    last_modified,
    created
FROM _registration;

DROP TABLE _registration;

CREATE TRIGGER IF NOT EXISTS update_registration_last_modified BEFORE update ON registration
BEGIN
    UPDATE registration SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' )
    WHERE registration_id = old.registration_id;
END;
