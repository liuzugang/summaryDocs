/*@lineinfo:filename=testsqlj*//*@lineinfo:user-code*//*@lineinfo:1^1*/
//sqlj基本联接.insert hellow sqlj入  sales表。
//之后用sqlplus察看结果;select * from sales;

import sqlj.runtime.*;
import sqlj.runtime.ref.*;

import oracle.sqlj.runtime.*;

import java.sql.*;

/*@lineinfo:generated-code*//*@lineinfo:12^1*/

//  ************************************************************
//  SQLJ iterator declaration:
//  ************************************************************

class student_iterator
extends sqlj.runtime.ref.ResultSetIterImpl
implements sqlj.runtime.NamedIterator
{
  public student_iterator(sqlj.runtime.profile.RTResultSet resultSet)
    throws java.sql.SQLException
  {
    super(resultSet);
    snoNdx = findColumn("sno");
    snameNdx = findColumn("sname");
    sageNdx = findColumn("sage");
    sclassNdx = findColumn("sclass");
    m_rs = (oracle.jdbc.OracleResultSet) resultSet.getJDBCResultSet();
  }
  private oracle.jdbc.OracleResultSet m_rs;
  public String sno()
    throws java.sql.SQLException
  {
    return m_rs.getString(snoNdx);
  }
  private int snoNdx;
  public String sname()
    throws java.sql.SQLException
  {
    return m_rs.getString(snameNdx);
  }
  private int snameNdx;
  public String sage()
    throws java.sql.SQLException
  {
    return m_rs.getString(sageNdx);
  }
  private int sageNdx;
  public String sclass()
    throws java.sql.SQLException
  {
    return m_rs.getString(sclassNdx);
  }
  private int sclassNdx;
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:17^1*/

public class testsqlj {
	public static void main(String args[]) {
	    
        		
		//String name_test="ora8";
        //宿主变量

		try {
			Oracle.connect(testsqlj.class,"connect.properties");
            //联接数据库

			/*@lineinfo:generated-code*//*@lineinfo:30^4*/

//  ************************************************************
//  #sql { delete from student };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OraclePreparedStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = sqlj.runtime.ref.DefaultContext.getDefaultContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
   String theSqlTS = "delete from student";
   __sJT_st = __sJT_ec.prepareOracleBatchableStatement(__sJT_cc,"0testsqlj",theSqlTS);
 // execute statement
   __sJT_ec.oracleExecuteBatchableUpdate();
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:30^29*/

            //直接更新数据
            String ss="qqqq";
            /*@lineinfo:generated-code*//*@lineinfo:34^13*/

//  ************************************************************
//  #sql { INSERT INTO STUDENT VALUES ('10009','wyfffwl','21','98001') };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OraclePreparedStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = sqlj.runtime.ref.DefaultContext.getDefaultContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
   String theSqlTS = "INSERT INTO STUDENT VALUES ('10009','wyfffwl','21','98001')";
   __sJT_st = __sJT_ec.prepareOracleBatchableStatement(__sJT_cc,"1testsqlj",theSqlTS);
 // execute statement
   __sJT_ec.oracleExecuteBatchableUpdate();
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:34^78*/
            /*@lineinfo:generated-code*//*@lineinfo:35^13*/

//  ************************************************************
//  #sql { INSERT INTO STUDENT VALUES ('10009','wyffztt','21','98001') };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OraclePreparedStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = sqlj.runtime.ref.DefaultContext.getDefaultContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
   String theSqlTS = "INSERT INTO STUDENT VALUES ('10009','wyffztt','21','98001')";
   __sJT_st = __sJT_ec.prepareOracleBatchableStatement(__sJT_cc,"2testsqlj",theSqlTS);
 // execute statement
   __sJT_ec.oracleExecuteBatchableUpdate();
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:35^78*/
            /*@lineinfo:generated-code*//*@lineinfo:36^13*/

//  ************************************************************
//  #sql { INSERT INTO STUDENT VALUES ('10009',:ss,'21','98001') };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OraclePreparedStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = sqlj.runtime.ref.DefaultContext.getDefaultContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
   String theSqlTS = "INSERT INTO STUDENT VALUES ('10009', :1 ,'21','98001')";
   __sJT_st = __sJT_ec.prepareOracleBatchableStatement(__sJT_cc,"3testsqlj",theSqlTS);
   // set IN parameters
   __sJT_st.setString(1,ss);
 // execute statement
   __sJT_ec.oracleExecuteBatchableUpdate();
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:36^72*/
            System.out.println("before submit!");
            //使用commit
            /*@lineinfo:generated-code*//*@lineinfo:39^13*/

//  ************************************************************
//  #sql { commit };
//  ************************************************************

  ((sqlj.runtime.ref.DefaultContext.getDefaultContext().getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : sqlj.runtime.ref.DefaultContext.getDefaultContext().getExecutionContext().getOracleContext()).oracleCommit(sqlj.runtime.ref.DefaultContext.getDefaultContext());


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:39^25*/
            System.out.println("OK!!!");

            //查询
            student_iterator si=null;
            /*@lineinfo:generated-code*//*@lineinfo:44^13*/

//  ************************************************************
//  #sql si = { select * from student };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OraclePreparedStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = sqlj.runtime.ref.DefaultContext.getDefaultContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "select * from student";
   __sJT_st = __sJT_ec.prepareOracleStatement(__sJT_cc,"4testsqlj",theSqlTS);
   // execute query
   si = new student_iterator(new sqlj.runtime.ref.OraRTResultSet(__sJT_ec.oracleExecuteQuery(),__sJT_st,"4testsqlj",null));
  } finally { __sJT_ec.oracleCloseQuery(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:44^43*/
            
            System.out.println("sno\tsname\tsage\tsclass");
            while(si.next())
            {
               System.out.println(si.sno()+"\t"+si.sname()+"\t"+si.sage()+"\t"+si.sclass());
            }

            System.out.println("Press any key to continue wyf...");
            System.in.read();
		} catch (Exception e) {
			System.out.println(e.toString());
			e.printStackTrace();
		}
		
	}

}/*@lineinfo:generated-code*/