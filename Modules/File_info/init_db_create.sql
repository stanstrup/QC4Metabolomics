CREATE TABLE file_info (
file_md5 CHAR(32) NOT NULL,
project       VARCHAR(256)  NOT NULL,
mode          ENUM('pos', 'neg','unknown') NOT NULL,
sample_id     TEXT(256)     NOT NULL,
time_run      DATETIME      NOT NULL,
FOREIGN KEY(file_md5) REFERENCES files(file_md5)
)
