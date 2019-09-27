SELECT CASE WHEN
    (
        SELECT LIKE( '%captain TEXT DEFAULT NULL%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'registration'
    ) +
    (
        SELECT LIKE( '%drive INTEGER DEFAULT NULL%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'registration'
    )
    = 2
THEN 1 ELSE 0 END;
