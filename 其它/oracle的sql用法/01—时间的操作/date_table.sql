CREATE TABLE date_table
(
    dd DATE
);

SELECT dd FROM date_table;

INSERT INTO date_table VALUES(SYSDATE);
//����ϵͳʱ��

INSERT INTO date_table VALUES(TO_DATE('2000-11-12 23:13:26','YYYY-MM-DD HH24:MI:SS'));
//����ָ����ʽ��ʱ��

INSERT INTO date_table VALUES(TO_DATE('2008"��"11-12 23:13:26','YYYY"��"MM-DD HH24:MI:SS'));
//����Ĳ���ָ����ʽ��ʱ��

SELECT TO_CHAR(dd,'YYYY-MM-DD HH24:MI:SS AM') FROM date_table;
//��ָ���ĸ�ʽ���ʱ��

SELECT TO_CHAR(dd,'YYYY��MM��DD�� HH24��MI��SS��') FROM date_table;
//������Զ����ʽ

SELECT TO_CHAR(dd,'YYYY"��"MM"��"DD"��" HH24"��"MI"��"SS"��"') FROM date_table;
//��ȷ���Զ����ʽ