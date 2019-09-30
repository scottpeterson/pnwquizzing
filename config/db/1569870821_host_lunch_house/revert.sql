ALTER TABLE schedule RENAME TO _schedule;

CREATE TABLE IF NOT EXISTS schedule (
    schedule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    meet TEXT DEFAULT NULL,
    location TEXT DEFAULT NULL,
    address TEXT DEFAULT NULL,
    address_url TEXT DEFAULT NULL,
    start TEXT DEFAULT NULL,
    deadline TEXT DEFAULT NULL
);

INSERT INTO schedule SELECT
    schedule_id,
    meet,
    location,
    address,
    address_url,
    start,
    deadline
FROM _schedule;

DROP TABLE _schedule;
