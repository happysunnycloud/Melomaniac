CREATE TABLE if not exists catalog (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    path      TEXT,
    file_name TEXT,
    title     TEXT,
    artist    TEXT,
    album     TEXT,
    year      INTEGER,
    duration  INTEGER,
    md5       TEXT,
    sha256    TEXT,    
    file_size INTEGER,
    UNIQUE(path, file_name)
);

CREATE INDEX if not exists idx_files_hash_size ON catalog(file_size, md5, sha256);