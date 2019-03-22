SELECT CASE WHEN
    (
        SELECT LIKE( '%user_id INTEGER PRIMARY KEY AUTOINCREMENT%', sql )
        FROM sqlite_master WHERE type = 'table' AND name = 'user'
    ) +
    (
        SELECT LIKE( '%UPDATE user SET last_modified%', sql )
        FROM sqlite_master WHERE type = 'trigger' AND name = 'update_user_last_modified'
    )
    = 2
THEN 1 ELSE 0 END;
