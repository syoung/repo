CREATE TABLE IF NOT EXISTS package 
(
    owner           VARCHAR(30) NOT NULL,
    username        VARCHAR(30) NOT NULL,
    packagename     VARCHAR(40) NOT NULL,
    repository      VARCHAR(40) NOT NULL,
    privacy         VARCHAR(40) NOT NULL,
    status          VARCHAR(40) NOT NULL,
    version         VARCHAR(40) NOT NULL,
    opsdir          VARCHAR(255),
    installdir      VARCHAR(255) NOT NULL,
    envars          TEXT,

    description     TEXT,
    notes           TEXT,
    website         TEXT,
    installed        DATETIME,
    
    PRIMARY KEY  (username, packagename, version)
);
