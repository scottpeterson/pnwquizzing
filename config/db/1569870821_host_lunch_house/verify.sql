SELECT CASE WHEN
    (
        SELECT LIKE( '%house INTEGER NOT NULL DEFAULT 1%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'schedule'
    ) +
    (
        SELECT LIKE( '%lunch INTEGER NOT NULL DEFAULT 1%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'schedule'
    )
    = 2
THEN 1 ELSE 0 END;
