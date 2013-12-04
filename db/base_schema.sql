CREATE TABLE IF NOT EXISTS image (
    image_id TEXT PRIMARY KEY,
    repository_name TEXT
);

CREATE TABLE IF NOT EXISTS container (
    container_id TEXT NOT NULL PRIMARY KEY,
    parent_image_id TEXT NOT NULL,
    ip_address TEXT,
    true_pid INTEGER NOT NULL,
    container_pid INTEGER NOT NULL,
    date_started DATETIME,
    FOREIGN KEY(parent_image_id) REFERENCES image(image_id));

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
    FOREIGN KEY(container_id) REFERENCES container(container_id)
);

CREATE TABLE IF NOT EXISTS container_volume (
    container_volume_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    host_volume_id INTEGER NOT NULL,
    location TEXT NOT NULL,
    container_id TEXT NOT NULL,
    FOREIGN KEY(host_volume_id) REFERENCES host_volume(host_volume_id),
    FOREIGN KEY(container_id) REFERENCES container(container_id)
);

CREATE TABLE IF NOT EXISTS exposed_port (
    exposed_port_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    container_id TEXT NOT NULL,
    container_port INTEGER,
    host_port INTEGER,
    FOREIGN KEY(container_id) REFERENCES container(container_id)
);

CREATE TABLE IF NOT EXISTS host_volume (
    host_volume_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    size INTEGER NOT NULL DEFAULT 50000,
    location TEXT NOT NULL
);

