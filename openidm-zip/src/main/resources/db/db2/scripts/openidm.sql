CONNECT TO DOPENIDM;
QUIESCE DATABASE IMMEDIATE FORCE CONNECTIONS;
UNQUIESCE DATABASE;
CONNECT RESET;
DEACTIVATE DATABASE DOPENIDM;
DROP DATABASE DOPENIDM;
-- DROP STOGROUP GOPENIDM;
-- COMMIT;
-- CREATE STOGROUP GOPENIDM
--       VOLUMES ('*')
--       VCAT     VSDB2T
--;
CREATE DATABASE   DOPENIDM
--       STOGROUP   GOPENIDM
--       BUFFERPOOL BP2
    -- Increase default page size for Activiti
    PAGESIZE 32 K
; 
CONNECT TO DOPENIDM;

-- http://db2-vignettes.blogspot.com/2013/07/a-temporary-table-could-not-be-created.html
CREATE BUFFERPOOL BPOIDMTEMPPOOL SIZE 500 PAGESIZE 32K;

CREATE TEMPORARY TABLESPACE TEMPSPACE2 pagesize 32k
       MANAGED BY AUTOMATIC STORAGE
       BUFFERPOOL BPOIDMTEMPPOOL;

CREATE SCHEMA SOPENIDM;

-- -----------------------------------------------------
-- Table openidm.objecttypes
-- -----------------------------------------------------
CREATE TABLESPACE SOIDM00 MANAGED BY AUTOMATIC STORAGE;

CREATE TABLE SOPENIDM.OBJECTTYPES (
    ID                         INTEGER GENERATED BY DEFAULT AS IDENTITY ( CYCLE ),
    OBJECTTYPE                 VARCHAR(255)   NOT NULL,
    PRIMARY KEY (ID) )
IN DOPENIDM.SOIDM00;
COMMENT ON TABLE SOPENIDM.OBJECTTYPES IS 'OPENIDM - Dictionary table for object types';
CREATE UNIQUE INDEX SOPENIDM.IDX_OBJECTTYPES_OBJECTTYPE ON SOPENIDM.OBJECTTYPES (OBJECTTYPE ASC);


-- -----------------------------------------------------
-- Table openidm.genericobjects
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM01 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.GENERICOBJECTS (
    id                         INTEGER GENERATED BY DEFAULT AS IDENTITY ( CYCLE ),
    objecttypes_id             INTEGER        NOT NULL,
    objectid                   VARCHAR(255)   NOT NULL,
    rev                        VARCHAR(38)    NOT NULL,
    fullobject                 CLOB(2M),
    PRIMARY KEY (ID),
    CONSTRAINT FK_GENERICOBJECTS_OBJECTTYPES
        FOREIGN KEY (OBJECTTYPES_ID ) REFERENCES SOPENIDM.OBJECTTYPES (ID ) ON DELETE CASCADE) IN DOPENIDM.SOIDM01;
COMMENT ON TABLE SOPENIDM.GENERICOBJECTS IS 'OPENIDM - Generic table For Any Kind Of Objects';
CREATE INDEX SOPENIDM.FK_GENERICOBJECTS_OBJECTTYPES ON SOPENIDM.GENERICOBJECTS (OBJECTTYPES_ID ASC);
CREATE INDEX SOPENIDM.IDX_GENERICOBJECTS_OBJECTID ON SOPENIDM.GENERICOBJECTS (OBJECTID ASC, OBJECTTYPES_ID ASC);

-- -----------------------------------------------------
-- Table openidm.genericobjectproperties
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM02 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.GENERICOBJECTPROPERTIES (
    genericobjects_id          INTEGER        NOT NULL,
    propkey                    VARCHAR(255)   NOT NULL,
    proptype                   VARCHAR(255),
    propvalue                  VARCHAR(2000),
    CONSTRAINT FK_GENERICOBJECTPROPERTIES_GENERICOBJECTS
        FOREIGN KEY (GENERICOBJECTS_ID ) REFERENCES SOPENIDM.GENERICOBJECTS (ID)
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM02;
COMMENT ON TABLE SOPENIDM.GENERICOBJECTPROPERTIES IS 'OPENIDM - Properties of Generic Objects';
CREATE INDEX SOPENIDM.IDX_GENERICOBJECTPROPERTIES_GENERICOBJECTS ON SOPENIDM.GENERICOBJECTPROPERTIES (GENERICOBJECTS_ID ASC);

-- -----------------------------------------------------
-- Table openidm.managedobjects
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM03 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.MANAGEDOBJECTS (
    id                         INTEGER GENERATED BY DEFAULT AS IDENTITY ( CYCLE ),
    objecttypes_id             INTEGER        NOT NULL,
    objectid                   VARCHAR(255)   NOT NULL,
    rev                        VARCHAR(38)    NOT NULL,
    fullobject                 CLOB(2M),
    PRIMARY KEY (ID),
    CONSTRAINT FK_MANAGEDOBJECTS_OBJECTTYPES
        FOREIGN KEY (OBJECTTYPES_ID ) REFERENCES SOPENIDM.OBJECTTYPES (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM03;
COMMENT ON TABLE SOPENIDM.MANAGEDOBJECTS IS 'OPENIDM - Generic Table For Managed Objects';
CREATE INDEX SOPENIDM.FK_MANAGEDOBJECTS_OBJECTTYPES ON SOPENIDM.MANAGEDOBJECTS (OBJECTTYPES_ID ASC);

-- -----------------------------------------------------
-- Table openidm.managedobjectproperties
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM04 MANAGED BY AUTOMATIC STORAGE ;
CREATE TABLE SOPENIDM.MANAGEDOBJECTPROPERTIES (
    MANAGEDOBJECTS_ID          INTEGER        NOT NULL,
    PROPKEY                    VARCHAR(255)   NOT NULL,
    PROPTYPE                   VARCHAR(255),
    PROPVALUE                  VARCHAR(2000),
    CONSTRAINT FK_MANAGEDOBJECTPROPERTIES_MANAGEDOBJECTS
        FOREIGN KEY (MANAGEDOBJECTS_ID )
        REFERENCES SOPENIDM.MANAGEDOBJECTS (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM04;
COMMENT ON TABLE SOPENIDM.MANAGEDOBJECTPROPERTIES IS 'OPENIDM - Properties of Managed Objects';
CREATE UNIQUE INDEX SOPENIDM.IDX_MANAGEDOBJECTPROPERTIES_PROP
    ON SOPENIDM.MANAGEDOBJECTPROPERTIES (PROPKEY ASC, MANAGEDOBJECTS_ID ASC);

-- -----------------------------------------------------
-- Table openidm.configobjects
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM05 MANAGED BY AUTOMATIC STORAGE ;
CREATE TABLE SOPENIDM.CONFIGOBJECTS (
    id                         INTEGER GENERATED BY DEFAULT AS IDENTITY ( CYCLE ),
    objecttypes_id             INTEGER        NOT NULL,
    objectid                   VARCHAR(255)   NOT NULL,
    rev                        VARCHAR(38)    NOT NULL,
    fullobject                 CLOB(2M),
    PRIMARY KEY (ID),
    CONSTRAINT FK_CONFIGOBJECTS_OBJECTTYPES
        FOREIGN KEY (OBJECTTYPES_ID )
        REFERENCES SOPENIDM.OBJECTTYPES (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM05;
COMMENT ON TABLE SOPENIDM.CONFIGOBJECTS IS 'OPENIDM - Generic Table For Config Objects';
CREATE INDEX SOPENIDM.FK_CONFIGOBJECTS_OBJECTTYPES ON SOPENIDM.CONFIGOBJECTS (OBJECTTYPES_ID ASC);

-- -----------------------------------------------------
-- Table openidm.configobjectproperties
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM06 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.CONFIGOBJECTPROPERTIES (
    CONFIGOBJECTS_ID           INTEGER        NOT NULL,
    PROPKEY                    VARCHAR(255)   NOT NULL,
    PROPTYPE                   VARCHAR(255),
    PROPVALUE                  VARCHAR(2000),
    CONSTRAINT FK_CONFIGOBJECTPROPERTIES_CONFIGOBJECTS
        FOREIGN KEY (CONFIGOBJECTS_ID )
        REFERENCES SOPENIDM.CONFIGOBJECTS (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM06;
COMMENT ON TABLE SOPENIDM.CONFIGOBJECTPROPERTIES IS 'OPENIDM - Properties of Config Objects';
CREATE UNIQUE INDEX SOPENIDM.IDX_CONFIGOBJECTPROPERTIES_PROP ON SOPENIDM.CONFIGOBJECTPROPERTIES (PROPKEY ASC, CONFIGOBJECTS_ID ASC);

-- -----------------------------------------------------
-- Table openidm.relationships
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM05 MANAGED BY AUTOMATIC STORAGE ;
CREATE TABLE SOPENIDM.RELATIONSHIPS (
    id                         INTEGER GENERATED BY DEFAULT AS IDENTITY ( CYCLE ),
    objecttypes_id             INTEGER        NOT NULL,
    objectid                   VARCHAR(255)   NOT NULL,
    rev                        VARCHAR(38)    NOT NULL,
    fullobject                 CLOB(2M),
    PRIMARY KEY (id),
    CONSTRAINT fk_relationships_objecttypes
        FOREIGN KEY (objecttypes_id)
        REFERENCES sopenidm.objecttypes (id)
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM05;
COMMENT ON TABLE sopenidm.relationships IS 'OPENIDM - Generic Table For Relationships';
CREATE INDEX sopenidm.fk_relationships_objecttypes ON sopenidm.relationships (objecttypes_id ASC);

-- -----------------------------------------------------
-- Table openidm.relationshiproperties
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM06 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.RELATIONSHIPPROPERTIES (
    relationships_id           INTEGER        NOT NULL,
    propkey                    VARCHAR(255)   NOT NULL,
    proptype                   VARCHAR(255),
    propvalue                  VARCHAR(2000),
    CONSTRAINT fk_relationshipproperties_relationships
        FOREIGN KEY (relationships_id)
        REFERENCES sopenidm.relationships (id)
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM06;
COMMENT ON TABLE SOPENIDM.RELATIONSHIPPROPERTIES IS 'OPENIDM - Properties of Relationships';
CREATE UNIQUE INDEX SOPENIDM.IDX_RELATIONSHIPPROPERTIES_PROP ON SOPENIDM.RELATIONSHIPPROPERTIES (PROPKEY ASC, RELATIONSHIPS_ID ASC);

-- -----------------------------------------------------
-- Table openidm.links
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM07 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.LINKS (
    objectid                   VARCHAR(38)    NOT NULL,
    rev                        VARCHAR(38)    NOT NULL,
    linktype                   VARCHAR(255)   NOT NULL,
    linkqualifier              VARCHAR(255)   NOT NULL,
    firstid                    VARCHAR(255)   NOT NULL,
    secondid                   VARCHAR(255)   NOT NULL,
    PRIMARY KEY (OBJECTID)
) IN DOPENIDM.SOIDM07;
COMMENT ON TABLE SOPENIDM.LINKS IS 'OPENIDM - Object Links For Mappings And Synchronization';

CREATE INDEX SOPENIDM.IDX_LINKS_FIRST ON SOPENIDM.LINKS (LINKTYPE ASC, LINKQUALIFIER ASC, FIRSTID ASC);
CREATE INDEX SOPENIDM.IDX_LINKS_SECOND ON SOPENIDM.LINKS (LINKTYPE ASC, LINKQUALIFIER ASC, SECONDID ASC);

-- -----------------------------------------------------
-- Table openidm.security
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM11 MANAGED BY AUTOMATIC STORAGE ;
CREATE TABLE SOPENIDM.SECURITY (
    objectid                   VARCHAR(38)     NOT NULL,
    rev                        VARCHAR(38)     NOT NULL,
    storestring                CLOB(2M)        NOT NULL
) IN DOPENIDM.SOIDM11;
COMMENT ON TABLE SOPENIDM.SECURITY IS 'OPENIDM - Security data';

-- -----------------------------------------------------
-- Table openidm.securitykeys
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM12 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.SECURITYKEYS (
    objectid                   VARCHAR(38)     NOT NULL,
    rev                        VARCHAR(38)     NOT NULL,
    keypair                    CLOB(2M)        NOT NULL
) IN DOPENIDM.SOIDM12;
COMMENT ON TABLE SOPENIDM.SECURITYKEYS IS 'OPENIDM - Security keys';

-- -----------------------------------------------------
-- Table `openidm`.`auditauthentication`
-- -----------------------------------------------------
CREATE TABLESPACE SOIDM20 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE sopenidm.auditauthentication (
  objectid VARCHAR(38) NOT NULL,
  transactionid VARCHAR(56) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  userid VARCHAR(255) NULL,
  eventname VARCHAR(50) NULL,
  result VARCHAR(255) NULL,
  principals CLOB(2M),
  context CLOB(2M),
  sessionid VARCHAR(255),
  entries CLOB(2M),
  PRIMARY KEY (objectid)
) IN DOPENIDM.SOIDM20;


-- -----------------------------------------------------
-- Table openidm.auditrecon
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM08 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.AUDITRECON (
    objectid VARCHAR(38) NOT NULL ,
    transactionid VARCHAR(56) NOT NULL ,
    activitydate VARCHAR(29) NOT NULL ,
    eventname VARCHAR(50) NULL ,
    userid VARCHAR(255) NULL ,
    activity VARCHAR(24) NULL ,
    exceptiondetail CLOB(2M) NULL ,
    linkqualifier VARCHAR(255) NULL ,
    mapping VARCHAR(511) NULL ,
    message CLOB(2M) NULL ,
    messagedetail CLOB(2M) NULL ,
    situation VARCHAR(24) NULL ,
    sourceobjectid VARCHAR(511) NULL ,
    status VARCHAR(20) NULL ,
    targetobjectid VARCHAR(511) NULL ,
    reconciling VARCHAR(12) NULL ,
    ambiguoustargetobjectids CLOB(2M) NULL ,
    reconaction VARCHAR(36) NULL ,
    entrytype VARCHAR(7) NULL ,
    reconid VARCHAR(56) NULL ,
    PRIMARY KEY (OBJECTID)
) IN DOPENIDM.SOIDM08;
COMMENT ON TABLE SOPENIDM.AUDITRECON IS 'OPENIDM - Reconciliation Audit Log';

CREATE INDEX sopenidm.idx_auditrecon_reconid ON sopenidm.auditrecon (reconid ASC);
--CREATE INDEX sopenidm.idx_auditrecon_targetobjectid ON sopenidm.auditrecon (targetobjectid(28) ASC);
--CREATE INDEX sopenidm.idx_auditrecon_sourceobjectid ON sopenidm.auditrecon (sourceobjectid(28) ASC);
CREATE INDEX sopenidm.idx_auditrecon_activitydate ON sopenidm.auditrecon (activitydate ASC);
--CREATE INDEX sopenidm.idx_auditrecon_mapping ON sopenidm.auditrecon (mapping(255) ASC);
CREATE INDEX sopenidm.idx_auditrecon_entrytype ON sopenidm.auditrecon (entrytype ASC);
CREATE INDEX sopenidm.idx_auditrecon_situation ON sopenidm.auditrecon (situation ASC);
CREATE INDEX sopenidm.idx_auditrecon_status ON sopenidm.auditrecon (status ASC);

-- -----------------------------------------------------
-- Table openidm.auditsync
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM13 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE sopenidm.auditsync (
    objectid                   VARCHAR(38)    NOT NULL,
    transactionid              VARCHAR(255),
    activitydate               VARCHAR(29),
    situation                  VARCHAR(24),
    activity                   VARCHAR(24),
    status                     VARCHAR(7),
    message                    CLOB(2M),
    actionid                   VARCHAR(255),
    exceptiondetail            CLOB(2M),
    mapping                    VARCHAR(511),
    linkqualifier              VARCHAR(255),
    sourceobjectid             VARCHAR(511),
    targetobjectid             VARCHAR(511),
    messagedetail              CLOB(2M),
    PRIMARY KEY (objectid) )
IN DOPENIDM.SOIDM13;
COMMENT ON TABLE SOPENIDM.AUDITSYNC IS 'OPENIDM - Sync Audit Log';

-- -----------------------------------------------------
-- Table `openidm`.`auditconfig`
-- -----------------------------------------------------
CREATE TABLESPACE SOIDM21 MANAGED BY AUTOMATIC STORAGE;
CREATE  TABLE sopenidm.auditconfig (
  objectid VARCHAR(38) NOT NULL ,
  activitydate VARCHAR(29) NOT NULL,
  transactionid VARCHAR(56) NOT NULL ,
  eventname VARCHAR(255) NULL ,
  userid VARCHAR(255) NULL ,
  runas VARCHAR(255) NULL ,
  resource_uri VARCHAR(255) NULL ,
  resource_protocol VARCHAR(10) NULL ,
  resource_method VARCHAR(10) NULL ,
  resource_detail VARCHAR(255) NULL ,
  before CLOB(2M) NULL ,
  after CLOB(2M) NULL ,
  changedfields VARCHAR(255) NULL ,
  rev VARCHAR(255) NULL,
  PRIMARY KEY (objectid)
) IN DOPENIDM.SOIDM21;
CREATE INDEX sopenidm.idx_auditconfig_transactionid ON sopenidm.auditconfig (transactionid ASC);


-- -----------------------------------------------------
-- Table openidm.auditactivity
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM09 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.AUDITACTIVITY (
    objectid VARCHAR(38) NOT NULL ,
    activity VARCHAR(24) NULL ,
    activitydate VARCHAR(29) NOT NULL,
    transactionid VARCHAR(56) NOT NULL ,
    eventname VARCHAR(255) NULL ,
    userid VARCHAR(255) NULL ,
    runas VARCHAR(255) NULL ,
    resource_uri VARCHAR(255) NULL ,
    resource_protocol VARCHAR(10) NULL ,
    resource_method VARCHAR(10) NULL ,
    resource_detail VARCHAR(255) NULL ,
    subjectbefore CLOB(2M) NULL ,
    subjectafter CLOB(2M) NULL ,
    changedfields VARCHAR(255) NULL ,
    passwordchanged VARCHAR(5) NULL ,
    subjectrev VARCHAR(255) NULL ,
    message CLOB(2M) NULL,
    activityobjectid VARCHAR(255) ,
    status VARCHAR(20) ,
    PRIMARY KEY (objectid)
) IN DOPENIDM.SOIDM09;
COMMENT ON TABLE SOPENIDM.AUDITACTIVITY IS 'OPENIDM - Activity Audit Logs';
CREATE INDEX SOPENIDM.idx_auditactivity_transactionid ON SOPENIDM.AUDITACTIVITY (transactionid ASC);

-- -----------------------------------------------------
-- Table openidm.internaluser
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM14 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.INTERNALUSER (
    objectid                   VARCHAR(254)    NOT NULL,
    rev                        VARCHAR(38),
    pwd                        VARCHAR(510),
    roles                      VARCHAR(1024),
    PRIMARY KEY (objectid)
) IN DOPENIDM.SOIDM14;
COMMENT ON TABLE SOPENIDM.INTERNALUSER IS 'OPENIDM - Internal User';


-- -----------------------------------------------------
-- Table openidm.auditaccess
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM10 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.AUDITACCESS (
    objectid VARCHAR(38) NOT NULL ,
    activity VARCHAR(24) NULL ,
    activitydate VARCHAR(29) NOT NULL,
    transactionid VARCHAR(56) NOT NULL ,
    eventname VARCHAR(255) ,
    server_ip VARCHAR(40) ,
    server_port VARCHAR(5) ,
    client_host VARCHAR(255) ,
    client_ip VARCHAR(40) ,
    client_port VARCHAR(5) ,
    userid VARCHAR(255) NULL ,
    principal CLOB(2M) NULL ,
    roles VARCHAR(1024) NULL ,
    auth_component VARCHAR(255) NULL ,
    resource_uri VARCHAR(255) NULL ,
    resource_protocol VARCHAR(10) NULL ,
    resource_method VARCHAR(14) NULL ,
    resource_detail VARCHAR(255) NULL ,
    http_method VARCHAR(10) NULL ,
    http_path VARCHAR(255) NULL ,
    http_querystring CLOB(2M) NULL ,
    http_headers CLOB(2M) ,
    status VARCHAR(20) NULL ,
    elapsedtime VARCHAR(13) NULL ,
    PRIMARY KEY (OBJECTID)
) IN DOPENIDM.SOIDM10;
COMMENT ON TABLE SOPENIDM.AUDITACCESS IS 'OPENIDM - Audit Access';
CREATE INDEX SOPENIDM.idx_auditaccess_status ON SOPENIDM.AUDITACCESS (status ASC);
--CREATE INDEX SOPENIDM.idx_auditaccess_principal ON SOPENIDM.AUDITACCESS (principal(28) ASC);

-- -----------------------------------------------------
-- Table openidm.schedulerobjects
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM15 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.SCHEDULEROBJECTS (
    ID                         INTEGER GENERATED BY DEFAULT AS IDENTITY ( CYCLE ),
    OBJECTTYPES_ID             INTEGER        NOT NULL,
    OBJECTID                   VARCHAR(255)   NOT NULL,
    REV                        VARCHAR(38)    NOT NULL,
    FULLOBJECT                 CLOB(2M),
    PRIMARY KEY (ID),
    CONSTRAINT FK_SCHEDULEROBJECTS_OBJECTTYPES
        FOREIGN KEY (OBJECTTYPES_ID )
        REFERENCES SOPENIDM.OBJECTTYPES (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM15;
COMMENT ON TABLE SOPENIDM.SCHEDULEROBJECTS IS 'OPENIDM - Generic table for scheduler objects';

CREATE INDEX SOPENIDM.FK_SCHEDULEROBJECTS_OBJECTTYPES ON SOPENIDM.SCHEDULEROBJECTS (OBJECTTYPES_ID ASC) ;
CREATE INDEX SOPENIDM.IDX_SCHEDULEROBJECTS_OBJECTID ON SOPENIDM.SCHEDULEROBJECTS (OBJECTID ASC, OBJECTTYPES_ID ASC);

-- -----------------------------------------------------
-- Table openidm.schedulerobjectproperties
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM16 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.SCHEDULEROBJECTPROPERTIES (
    SCHEDULEROBJECTS_ID        INTEGER        NOT NULL,
    PROPKEY                    VARCHAR(255)   NOT NULL,
    PROPTYPE                   VARCHAR(255),
    PROPVALUE                  VARCHAR(2000),
    CONSTRAINT FK_SCHEDULEROBJECTPROPERTIES_SCHEDULEROBJECTS
        FOREIGN KEY (SCHEDULEROBJECTS_ID )
        REFERENCES SOPENIDM.SCHEDULEROBJECTS (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM16;
COMMENT ON TABLE SOPENIDM.SCHEDULEROBJECTPROPERTIES IS 'OPENIDM - Properties of Generic Objects';
CREATE INDEX SOPENIDM.IDX_SCHEDULEROBJECTPROPERTIES_SCHEDULEROBJECTS
    ON SOPENIDM.SCHEDULEROBJECTPROPERTIES (SCHEDULEROBJECTS_ID ASC) ;

-- -----------------------------------------------------
-- Table openidm.uinotification
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM19 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.UINOTIFICATION (
    OBJECTID                   VARCHAR(38)    NOT NULL,
    REV                        VARCHAR(38)    NOT NULL,
    NOTIFICATIONTYPE           VARCHAR(255)   NOT NULL,
    CREATEDATE                 VARCHAR(255)   NOT NULL,
    MESSAGE                    CLOB(2M)       NOT NULL,
    REQUESTER                  VARCHAR(255)       NULL,
    RECEIVERID                 VARCHAR(38)    NOT NULL,
    REQUESTERID                VARCHAR(38)        NULL,
    NOTIFICATIONSUBTYPE        VARCHAR(255)       NULL,
    PRIMARY KEY (OBJECTID)
) IN DOPENIDM.SOIDM19;
COMMENT ON TABLE SOPENIDM.UINOTIFICATION IS 'OPENIDM - Generic table for ui notifications';

-- -----------------------------------------------------
-- Table openidm.clusterobjects
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM17 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.CLUSTEROBJECTS (
    ID                         INTEGER GENERATED BY DEFAULT AS IDENTITY ( CYCLE ),
    OBJECTTYPES_ID             INTEGER        NOT NULL,
    OBJECTID                   VARCHAR(255)   NOT NULL,
    REV                        VARCHAR(38)    NOT NULL,
    FULLOBJECT                 CLOB(2M),
    PRIMARY KEY (ID),
    CONSTRAINT FK_CLUSTEROBJECTS_OBJECTTYPES
        FOREIGN KEY (OBJECTTYPES_ID )
        REFERENCES SOPENIDM.OBJECTTYPES (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM17;
COMMENT ON TABLE SOPENIDM.CLUSTEROBJECTS IS 'OPENIDM - Generic table for cluster objects';

CREATE INDEX SOPENIDM.FK_CLUSTEROBJECTS_OBJECTTYPES ON SOPENIDM.CLUSTEROBJECTS (OBJECTTYPES_ID ASC);
CREATE INDEX SOPENIDM.IDX_CLUSTEROBJECTS_OBJECTID ON SOPENIDM.CLUSTEROBJECTS (OBJECTID ASC, OBJECTTYPES_ID ASC);

-- -----------------------------------------------------
-- Table openidm.clusterobjectproperties
-- -----------------------------------------------------

CREATE TABLESPACE SOIDM18 MANAGED BY AUTOMATIC STORAGE;
CREATE TABLE SOPENIDM.CLUSTEROBJECTPROPERTIES (
    CLUSTEROBJECTS_ID          INTEGER        NOT NULL,
    PROPKEY                    VARCHAR(255)   NOT NULL,
    PROPTYPE                   VARCHAR(255),
    PROPVALUE                  VARCHAR(2000),
    CONSTRAINT FK_CLUSTEROBJECTPROPERTIES_CLUSTEROBJECTS
        FOREIGN KEY (CLUSTEROBJECTS_ID )
        REFERENCES SOPENIDM.CLUSTEROBJECTS (ID )
        ON DELETE CASCADE
) IN DOPENIDM.SOIDM18;
COMMENT ON TABLE SOPENIDM.CLUSTEROBJECTPROPERTIES IS 'OPENIDM - Properties of Generic Objects';

CREATE INDEX SOPENIDM.IDX_CLUSTEROBJECTPROPERTIES_CLUSTEROBJECTS ON SOPENIDM.CLUSTEROBJECTPROPERTIES (CLUSTEROBJECTS_ID ASC);

-- -----------------------------------------------------
-- Data for table openidm.internaluser
-- -----------------------------------------------------

INSERT INTO sopenidm.internaluser (objectid, rev, pwd, roles) VALUES ('openidm-admin', '0', 'openidm-admin', '["openidm-admin","openidm-authorized"]');
INSERT INTO sopenidm.internaluser (objectid, rev, pwd, roles) VALUES ('anonymous', '0', 'anonymous', '["openidm-reg"]');

COMMIT;

