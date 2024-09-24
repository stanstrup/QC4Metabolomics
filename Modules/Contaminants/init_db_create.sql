CREATE TABLE cont_cmp (
ion_id   int                NOT NULL,
name     TEXT               NOT NULL,
mode     ENUM('pos', 'neg') NOT NULL,
mz       DOUBLE             NOT NULL,
anno     TEXT               NOT NULL,
notes    TEXT               NOT NULL,

PRIMARY KEY(ion_id, mode)
);


CREATE TABLE cont_data (
file_md5 CHAR(32) NOT NULL, 
ion_id   int      NOT NULL,
stat     ENUM('EIC_median', 'EIC_mean', 'EIC_sd', 'EIC_max') NOT NULL,
mode     ENUM('pos', 'neg') NOT NULL,
value    DOUBLE NULL,

FOREIGN KEY(file_md5) REFERENCES files(file_md5),
FOREIGN KEY(ion_id, mode)     REFERENCES cont_cmp(ion_id, mode),

PRIMARY KEY(file_md5, ion_id, mode, stat)
);

CREATE INDEX `idx_cont_data_value`  ON `cont_data` (stat,value DESC);
