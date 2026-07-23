-- init.sql — Initialize the MCA user in FREEPDB1
-- This is run automatically by the installer during first container creation

ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE USER mca IDENTIFIED BY mca;
GRANT CONNECT, RESOURCE TO mca;
GRANT CREATE VIEW, CREATE SYNONYM TO mca;
ALTER USER mca QUOTA UNLIMITED ON USERS;

EXIT;
