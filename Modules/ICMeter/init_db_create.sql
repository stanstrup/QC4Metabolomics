CREATE TABLE ic_data (
time      DATETIME      NOT NULL,
device    VARCHAR(50)   NOT NULL,
metric    VARCHAR(50)   NOT NULL,
value     DOUBLE        NOT NULL,
PRIMARY KEY(time, device, metric)
)
