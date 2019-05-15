SELECT CASE WHEN
    (
        SELECT LIKE( '%role_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'role'
    ) +
    (
        SELECT LIKE( '%user_role_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'user_role'
    )
    = 2
THEN 1 ELSE 0 END;
