CREATE TABLE IF NOT EXISTS container (
    container_id TEXT NOT NULL PRIMARY KEY,
    true_pid INTEGER NOT NULL,
);

CREATE TABLE IF NOT EXISTS condition_net_delay (
    condition_net_delay_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    base INTEGER NOT NULL DEFAULT 0,
    deviation INTEGER,
    correlation REAL,
    distribution TEXT
);

CREATE TABLE IF NOT EXISTS condition_net_drop (
    condition_net_drop_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    base REAL NOT NULL DEFAULT 0,
    correlation REAL
);

CREATE TABLE IF NOT EXISTS condition_net_reject (
    condition_net_reject_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    target TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS condition_net_ignore (
    condition_net_ignore_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    target TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS container_condition (
    container_condition_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    container_id TEXT NOT NULL,
    condition_type INTEGER NOT NULL,
    condition_id INTEGER NOT NULL,
    is_active INTEGER NOT NULL CHECK(is_income = 0 OR is_income = 1) DEFAULT 0,
    FOREIGN KEY(container_id) REFERENCES container(container_id)
);
