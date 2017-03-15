CREATE TABLE files (
path          TEXT(256)     NOT NULL,
file_md5      CHAR(32)      PRIMARY KEY
);

CREATE TABLE files_ignore (
path          TEXT(256)     NOT NULL,
file_md5      CHAR(32)      NOT NULL
);
