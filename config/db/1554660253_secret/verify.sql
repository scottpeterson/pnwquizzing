SELECT CASE WHEN
    (
        SELECT LIKE( '%secret_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'secret'
    ) = 1
THEN 1 ELSE 0 END;
