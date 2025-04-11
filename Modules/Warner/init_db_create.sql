CREATE TABLE warner_stat_types (
stat_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
stat_name VARCHAR(20) NOT NULL
);

INSERT INTO warner_stat_types (stat_name)
VALUES ('mz'),('mzmin'),('mzmax'),
       ('rt'),('rtmin'),('rtmax'),
       ('into'),('intb'),('maxo'),
       ('sn'),('egauss'),('mu'),('sigma'),('h'),('f'),
       ('mz_dev_ppm'),('rt_dev'),('FWHM'),('datapoints'),('TF'),('ASF');

CREATE TABLE warner_rules (
instrument     TEXT                NOT NULL,
rule_name      TEXT               NOT NULL,
rule_id        int                 NOT NULL AUTO_INCREMENT PRIMARY KEY,
stat_id        int                 NOT NULL,
operator       ENUM('<', '>', '=') NOT NULL,
value          DOUBLE              NOT NULL,
use_abs_value  BOOL                NOT NULL,
enabled        BOOL                NOT NULL,
updated_at     TIMESTAMP           DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
KEY (updated_at),
FOREIGN KEY(stat_id)  REFERENCES warner_stat_types(stat_id)
);


/*
reason the PRIMARY KEY is set this way: 
http://weblogs.sqlteam.com/jeffs/archive/2007/08/23/composite_primary_keys.aspx
*/;

CREATE TABLE warner_log (
file_md5       CHAR(32)   NOT NULL, 
rule_id        int        NOT NULL,
processed_at   TIMESTAMP  NOT NULL,


FOREIGN KEY(file_md5) REFERENCES files(file_md5),
FOREIGN KEY(rule_id)  REFERENCES warner_rules(rule_id),

PRIMARY KEY(file_md5, rule_id)
);

CREATE INDEX `file_md5_index`          ON `warner_log` (file_md5);
CREATE INDEX `file_md5_index_rule_id`  ON `warner_log` (file_md5,rule_id);

