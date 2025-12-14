CREATE TABLE if not exists catalog (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    path      TEXT,
    file_name TEXT,
    title     TEXT,
    artist    TEXT,
    album     TEXT,
    year      INTEGER,
    duration  REAL,
	UNIQUE(path, file_name)
);

