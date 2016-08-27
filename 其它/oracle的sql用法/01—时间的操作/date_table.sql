CREATE TABLE date_table
(
    dd DATE
);

SELECT dd FROM date_table;

INSERT INTO date_table VALUES(SYSDATE);
//插入系统时间

INSERT INTO date_table VALUES(TO_DATE('2000-11-12 23:13:26','YYYY-MM-DD HH24:MI:SS'));
//插入指定格式的时间

INSERT INTO date_table VALUES(TO_DATE('2008"年"11-12 23:13:26','YYYY"年"MM-DD HH24:MI:SS'));
//错误的插入指定格式的时间

SELECT TO_CHAR(dd,'YYYY-MM-DD HH24:MI:SS AM') FROM date_table;
//按指定的格式输出时间

SELECT TO_CHAR(dd,'YYYY年MM月DD日 HH24点MI分SS秒') FROM date_table;
//错误的自定义格式

SELECT TO_CHAR(dd,'YYYY"年"MM"月"DD"日" HH24"点"MI"分"SS"秒"') FROM date_table;
//正确的自定义格式