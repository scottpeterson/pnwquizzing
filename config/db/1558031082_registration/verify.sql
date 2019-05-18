SELECT CASE WHEN
    (
        SELECT LIKE( '%schedule_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'schedule'
    ) +
    (
        SELECT LIKE( '%schedule_church_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'schedule_church'
    ) +
    (
        SELECT LIKE( '%UPDATE schedule_church SET last_modified%', sql )
        FROM sqlite_master WHERE type = 'trigger' AND name = 'update_schedule_church_last_modified'
    ) +
    (
        SELECT LIKE( '%registration_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'registration'
    ) +
    (
        SELECT LIKE( '%UPDATE registration SET last_modified%', sql )
        FROM sqlite_master WHERE type = 'trigger' AND name = 'update_registration_last_modified'
    )
    = 5
THEN 1 ELSE 0 END;
