SELECT CASE WHEN
    (
        SELECT LIKE( '%church_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'church'
    ) +
    (
        SELECT LIKE( '%INTEGER DEFAULT NULL REFERENCES church(church_id)%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'user'
    )
    = 2
THEN 1 ELSE 0 END;
