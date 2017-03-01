CREATE TABLE files (
path          TEXT(256)     NOT NULL,
file_md5      CHAR(32)      PRIMARY KEY
);

CREATE TABLE file_info (
file_md5 CHAR(32) NOT NULL,
project       VARCHAR(256)  NOT NULL,
instrument    TEXT(256)     NOT NULL,
mode          ENUM('pos', 'neg','unknown') NOT NULL,
time_filename DATE          NOT NULL,
batch_seq_nr  SMALLINT      NOT NULL,
sample_id     TEXT(256)     NOT NULL,
sample_ext_nr SMALLINT      NOT NULL,
inst_run_nr   SMALLINT      NOT NULL,
time_run      DATETIME      NOT NULL,
FOREIGN KEY(file_md5) REFERENCES files(file_md5)
)
