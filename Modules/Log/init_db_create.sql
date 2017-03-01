CREATE TABLE log (
                id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
                time          DATETIME      NOT NULL,
                msg           TEXT          NOT NULL,
                cat           ENUM('info', 'warning','error') NOT NULL,
                source        VARCHAR(256)  NOT NULL
                )
                
