CREATE TABLE file_schedule (
file_md5      CHAR(32)       NOT NULL,
module        VARCHAR(256)   NOT NULL,
priority      TINYINT       NOT NULL,
FOREIGN KEY(file_md5) REFERENCES files(file_md5)
);


