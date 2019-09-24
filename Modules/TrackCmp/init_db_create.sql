CREATE TABLE std_stat_types (
stat_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
stat_name VARCHAR(20) NOT NULL
);

INSERT INTO std_stat_types (stat_name)
VALUES ('mz'),('mzmin'),('mzmax'),
       ('rt'),('rtmin'),('rtmax'),
       ('into'),('intb'),('maxo'),
       ('sn'),('egauss'),('mu'),('sigma'),('h'),('f'),
       ('mz_dev_ppm'),('rt_dev'),('FWHM'),('datapoints'),('TF'),('ASF');

CREATE TABLE std_compounds (
cmp_id     int                NOT NULL AUTO_INCREMENT PRIMARY KEY,
cmp_name   TEXT               NOT NULL,
instrument TEXT               NOT NULL,
mode       ENUM('pos', 'neg') NOT NULL,
cmp_mz     DOUBLE             NOT NULL,
cmp_rt1    DOUBLE             NOT NULL,
cmp_rt2    DOUBLE,
enabled    BOOL               NOT NULL,
updated_at TIMESTAMP          DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
KEY (updated_at)
);


/*
reason the PRIMARY KEY is set this way: 
http://weblogs.sqlteam.com/jeffs/archive/2007/08/23/composite_primary_keys.aspx
*/;

CREATE TABLE std_stat_data (
file_md5 CHAR(32) NOT NULL, 
stat_id  int      NOT NULL,
cmp_id   int      NOT NULL,
found    BOOL     NOT NULL,
FOREIGN KEY(file_md5) REFERENCES files(file_md5),
FOREIGN KEY(stat_id)  REFERENCES std_stat_types(stat_id),
FOREIGN KEY(cmp_id)   REFERENCES std_compounds(cmp_id),
value DOUBLE NULL,
PRIMARY KEY(file_md5, stat_id, cmp_id)
)
