DROP TABLE SaleOrderList;
CREATE TABLE SaleOrderList 
(
    eid CHAR(4),
    ename VARCHAR2(20),
    etel VARCHAR2(12),
    CONSTRAINT pk_eid PRIMARY KEY(eid)
);

DROP TABLE SM_EMP;
CREATE TABLE SM_EMP
(
    jyid CHAR(4),
    jyeid CHAR(4),
    jyvalue NUMBER(8,2),
    CONSTRAINT fk_jyeid FOREIGN KEY(jyeid) REFERENCES SaleOrderList(eid),
    CONSTRAINT pk_jyid PRIMARY KEY(jyid)
);

DROP SEQUENCE jyid_s;
CREATE SEQUENCE jyid_s  MAXVALUE 9999 CYCLE;

INSERT INTO SaleOrderList(eid,ename,etel)
VALUES('0001','Tom','2044669');
INSERT INTO SaleOrderList(eid,ename,etel)
VALUES('0002','Jhone','2044533');
INSERT INTO SaleOrderList(eid,ename,etel)
VALUES('0003','Lily','2044000');
INSERT INTO SaleOrderList(eid,ename,etel)
VALUES('0004','Marry','2044111');
SELECT * FROM SaleOrderList;

select TO_CHAR(jyid_s.nextval,'9999') from dual;

INSERT INTO SM_EMP(jyid,jyeid,jyvalue)
VALUES(TO_CHAR(jyid_s.nextval,'099'),'0001',5687.60);
INSERT INTO SM_EMP(jyid,jyeid,jyvalue)
VALUES(TO_CHAR(jyid_s.nextval,'099'),'0001',687.60);
INSERT INTO SM_EMP(jyid,jyeid,jyvalue)
VALUES(TO_CHAR(jyid_s.nextval,'099'),'0002',15687.00);
INSERT INTO SM_EMP(jyid,jyeid,jyvalue)
VALUES(TO_CHAR(jyid_s.nextval,'099'),'0002',1100.00);
INSERT INTO SM_EMP(jyid,jyeid,jyvalue)
VALUES(TO_CHAR(jyid_s.nextval,'099'),'0002',5687.60);
INSERT INTO SM_EMP(jyid,jyeid,jyvalue)
VALUES(TO_CHAR(jyid_s.nextval,'099'),'0003',10000.00);

SELECT * FROM SM_EMP;