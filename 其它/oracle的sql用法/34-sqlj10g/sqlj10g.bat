set classpath=%classpath%;E:\oracle\product\10.2.0\db_1\oc4j\sqlj\lib\translator.jar
set classpath=%classpath%;E:\oracle\product\10.2.0\db_1\sqlj\lib\runtime12.jar
set classpath=%classpath%;E:\oracle\product\10.2.0\db_1\jdbc\lib\classes12.jar
set classpath=%classpath%;E:\sqlj10g

path=E:\oracle\product\10.2.0\db_1\jdk\bin;%path%

java sqlj.tools.Sqlj testsqlj.sqlj

java testsqlj