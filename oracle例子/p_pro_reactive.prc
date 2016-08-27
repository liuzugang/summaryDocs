create or replace procedure p_pro_reactive
(year in number,sysdeptcode in char)
is
  user_dept_code char(18);
  id_start number(6);--分组统计时id开始值
  id_parent_start number(6);--分组统计时parent_id开始值
  cn_volt number(3);--电压等级码值个数
  cn_volt_equa number(3);--补偿电压等级码值个数
  cn_branch_class number(3);--单位类别码值个数
  cn_dept number(3);--单位个数
begin
  user_dept_code := sysdeptcode;
  cn_volt := 15;
  cn_volt_equa := 15;
  --2014-1-16 将“2、全资子公司及控股公司”拆分为“2、全资子公司”和“3、控股公司”，增加一个单位类别，cn_branch_class=:9->cn_branch_class:=10
  cn_branch_class := 10;
  cn_dept := 99;

  --2014-1-16 电压等级编码为0的电压等级名称由“特高压”修改为“1000千伏”
  --2014-1-16 将“（三）省电力公司”下的“2、全资子公司及控股公司”拆分为“2、全资子公司”和“3、控股公司”
  --删除本期上次统计的数据
  delete from pro_reactive where tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  ----一。插入电网总计及明细
  --A3 按电压等级、补偿电压等级分组数据，id_level=3，插入的sort_char是5位，第1-3位表示电压等级，第4、5位表示补偿电压。数据来源是源表reactive。
  --结果：第3层，sort_char=5位，电压等级||补偿电压=001||04。
  id_start := 1;
  id_parent_start := cn_volt * cn_volt_equa + 1;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize),'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,
         3,decode(decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize),
                  '0','1000千伏','O','±800千伏','1','750千伏','P','±660千伏','2','500千伏','Q','±500千伏','R','±400千伏','S','±400千伏以下','3','330千伏','4','220千伏','5','110千伏','B','66千伏','6','35千伏','C','20千伏','10千伏及以下') item_name,
         decode(voltage,'0','000','O','001','1','002','P','003','2','004','Q','005','R','006','S','007','3','008','4','009','5','010','B','011','6','012','C','013','014')||
         decode(decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize),
                '0','00','O','01','1','02','P','03','2','04','Q','05','R','06','S','07','3','08','4','09','5','10','B','11','6','12','C','13','14') sort_char,
         sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
             nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
             nvl(e_static,0)+nvl(u_static,0)),
         sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)),
         sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)),
         sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)),sum(e_phaseshiftor),sum(u_phaseshiftor),
         sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)),sum(e_capacitor),sum(u_capacitor),
         sum(nvl(e_reactor,0)+nvl(u_reactor,0)),sum(e_reactor),sum(u_reactor),
         sum(nvl(e_other,0)+nvl(u_other,0)),sum(e_other),sum(u_other),
         sum(nvl(e_static,0)+nvl(u_static,0)),sum(e_static),sum(u_static),sysdeptcode
  from reactive
  where tab_year=year and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S') and sys_dept_code=sysdeptcode
  and ('41311016130101000 '<>sysdeptcode  --不是河北
       or
       exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --河北，只统计南网
      )
  group by voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize);

  --A2 按电压等级分组数据，id_level=2，插入的sort_char是3位，表示电压等级。数据来源是A1部分插入的记录，取的sort_char是5位。
  --结果：第2层，sort_char=3位，(电压等级||补偿电压=001||04)的第1段，即，电压等级=001。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code, id_start+to_number(substr(sort_char,1,3)) id,--取5位的sort_char的第3位，表示电压等级
         id_parent_start parent_id,2,
         decode(substr(sort_char,1,3),
                '000','1000千伏','001','±800千伏','002','750千伏','003','±660千伏','004','500千伏','005','±500千伏','006','±400千伏','007','±400千伏以下','008','330千伏','009','220千伏','010','110千伏','011','66千伏','012','35千伏','013','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,3) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,3);

  --A1 电网总计项，id_level=1，1条记录，sort_char为0。数据来源是A2部分插入的记录，取的sort_char是3位。
  --结果：第1层，sort_char=0。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 1;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code, id_start id,0 parent_id, 1,'电网总计' item_name,'0' sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=3 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --------二。插入一、国家电网公司/二、其他及其明细corp_group in (11,12,13,14,23,24,25,26,27)，即全部的单位类别--------
  --BA4 按单位类别、电压等级、补偿电压等级分组数据，id_level=4，插入的sort_char是7位。
  --第1、2位表示单位类别（第一位为1或者2，1表示“一、国家电网公司”，2表示“二、其他”），第3-5表示电压等级，第6、7位表示补偿电压等级。数据来源是源表reactive。
  --2014-1-16单位类别中将全资子公司和控股公司拆分，branch_class=21时为控股公司
  --结果：第4层，sort_char=7位，单位类别||电压等级||补偿电压等级=11||001||04。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(decode(branch_class,50,11, 40,12, 45,12, 10,131, 70,132, 21,133, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27),1,2),
                         11,0, 12,1, 13,2, 14,3, 23,4, 24,5, 25,6, 26,7, 27,8)*cn_volt*cn_volt_equa+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize),'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+decode(substr(decode(branch_class,50,11, 40,12, 45,12, 10,131, 70,132, 21,133, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27),1,2),
                                11,0, 12,1, 13,2, 14,3, 23,4, 24,5, 25,6, 26,7, 27,8)*cn_volt+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,
         4 id_level,decode(decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize),
                           '0','1000千伏','O','±800千伏','1','750千伏','P','±660千伏','2','500千伏','Q','±500千伏','R','±400千伏','S','±400千伏以下','3','330千伏','4','220千伏','5','110千伏','B','66千伏','6','35千伏','C','20千伏','10千伏及以下') item_name,
         substr(decode(branch_class,50,11, 40,12, 45,12, 10,131, 70,132, 21,133, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27),1,2)||
         decode(voltage,'0','000','O','001','1','002','P','003','2','004','Q','005','R','006','S','007','3','008','4','009','5','010','B','011','6','012','C','013','014')||
         decode(decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize),
               '0','00','O','01','1','02','P','03','2','04','Q','05','R','06','S','07','3','08','4','09','5','10','B','11','6','12','C','13','14') sort_char,
         sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
             nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
             nvl(e_static,0)+nvl(u_static,0)),
         sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)),
         sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)),
         sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)),sum(e_phaseshiftor),sum(u_phaseshiftor),
         sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)),sum(e_capacitor),sum(u_capacitor),
         sum(nvl(e_reactor,0)+nvl(u_reactor,0)),sum(e_reactor),sum(u_reactor),
         sum(nvl(e_other,0)+nvl(u_other,0)),sum(e_other),sum(u_other),
         sum(nvl(e_static,0)+nvl(u_static,0)),sum(e_static),sum(u_static),sysdeptcode
  from reactive
  where tab_year=year and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S') and sys_dept_code=sysdeptcode
  and ('41311016130101000 '<>sysdeptcode  --不是河北
       or
       exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --河北，只统计南网
      )
  group by substr(decode(branch_class,50,11, 40,12, 45,12, 10,131, 70,132, 21,133, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27),1,2),
           voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize);

  --BA3 按单位类别、电压等级分组数据，id_level=3，插入的sort_char是5位。
  --第1、2表示单位类别（第一位为1或者2，1表示“一、国家电网公司”，2表示“二、其他”），第3-5位表示电压等级。数据来源是BA4部分插入的记录，取的sort_char是5位。
  --结果：第3层，sort_char=5位，(单位类别||电压等级||补偿电压等级)的第1、2段，即，单位类别||电压等级=11||001。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,5),1,2),
                         '11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_volt+to_number(substr(substr(sort_char,1,5),3,3)) id,--取7位的sort_char的第5位，表示电压等级
         id_parent_start+decode(substr(substr(sort_char,1,5),1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8) parent_id,
         3 id_level,decode(substr(substr(sort_char,1,5),3,3),/*decode(substr(sort_char,3,3),*/
                           '000','1000千伏','001','±800千伏','002','750千伏','003','±660千伏','004','500千伏','005','±500千伏','006','±400千伏','007','±400千伏以下','008','330千伏','009','220千伏','010','110千伏','011','66千伏','012','35千伏','013','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,5) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=7 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,5);
--commit;return;--testlzg
  --BA2 按单位类别分组数据，id_level=2，插入的sort_char是2位，第1、2表示单位类别（第一位为1或者2，1表示“一、国家电网公司”，2表示“二、其他”）。
  --数据来源是BA3部分插入的记录，取的sort_char是5位。这些记录的父节点是不存在的，设置为999991表示“一、国家电网公司”和999992表示“二、其他”,但会根据sort_char排在B1的下方。
  --结果：第2层，sort_char=2位，(单位类别||电压等级)的第1段，即，单位类别=11。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(sort_char,1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8) id,
         decode(substr(sort_char,1,2),'11',999991, '12',999991, '13',999991, 999992) parent_id,2 id_level,  --parent_id在B1部分记录插入后，会再update一次
         decode(substr(sort_char,1,2),'11','（一）总部','12','（二）分部','13','（三）省电力公司','14','（四）其他省公司','23','（一）参股','24','（二）代管',
                '25','（三）地方电力公司','26','（四）用户','27','（五）电厂') item_name,substr(sort_char,1,2) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=5 and substr(sort_char,1,1)<>'0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,2);

  --BB3 按单位类别的第一位（第一位为1或者2，1表示“一、国家电网公司”，2表示“二、其他”）、电压等级、补偿电压等级分组数据，id_level=3。
  --插入的sort_char是6位，第1位为1或2（1表示“一、国家电网公司”，2表示“二、其他”），第2-4表示电压等级，第5、6位表示补偿电压。数据来源是BA4部分插入的记录，取的sort_char是7位。
  --结果：第3层，sort_char=6位,单位类别第1位||电压等级||补偿电压等级=1||001||04。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 2*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+(substr(sort_char,1,1)-1)*cn_volt*cn_volt_equa+to_number(substr(substr(sort_char,3,5),1,3))*cn_volt_equa+to_number(substr(substr(sort_char,3,5),4,2)) id,
         id_parent_start+(substr(sort_char,1,1)-1)*cn_volt+substr(substr(sort_char,3,5),3,1) parent_id,3 id_level,
         decode(substr(substr(sort_char,3,5),4,2),
                '00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,1)||substr(sort_char,3,5) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=7 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,3,5),substr(sort_char,1,1);

  --BB2 按单位类别的第一位（第一位为1或者2，1表示“一、国家电网公司”，2表示“二、其他”）、电压等级分组数据，id_level=2。
  --插入的sort_char是4位，第1位为1或2（1表示“一、国家电网公司”，2表示“二、其他”），第2-4表示电压等级。数据来源是BB3部分插入的记录，取的sort_char是6位。
  --结果：第2层，sort_char=4位,(单位类别第1位||电压等级||补偿电压等级)的第1、2段，即单位类别第1位||电压等级=1||001。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 2*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+(substr(substr(sort_char,1,4),1,1)-1)*cn_volt+to_number(substr(substr(sort_char,1,4),2,3)) id,
         id_parent_start+substr(substr(sort_char,1,4),1,1)-1 parent_id,2 id_level,
         decode(substr(substr(sort_char,1,4),2,3),
                '000','1000千伏','001','±800千伏','002','750千伏','003','±660千伏','004','500千伏','005','±500千伏','006','±400千伏','007','±400千伏以下','008','330千伏','009','220千伏','010','110千伏','011','66千伏','012','35千伏','013','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,4) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
     sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=6 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,4);

  ----B1 插入一、国家电网公司，二、其他，按单位类别的第一位（第一位为1或者2，1表示“一、国家电网公司”，2表示“二、其他”）分组数据，id_level=1。
  --插入的sort_char是1位，分别为'1'、'2'，插入“一、国家电网公司”和“二、其他”这两条记录。父节点id号是0。数据来源是BB2部分插入的记录，取的sort_char是4位。
  --结果：第1层，sort_char=1位,(单位类别第1位||电压等级)的第1段，即单位类别第1位=1。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 2;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+substr(sort_char,1,1)-1,0 parent_id,1 id_level,
         decode(substr(sort_char,1,1),'1','一、国家电网公司', '2','二、其他') item_name,
         substr(sort_char,1,1) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
      sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=4 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,1);

  --更新BA2部分插入记录(sort_char为2位且第1位不是0)的parent_id（取自B1插入的记录）
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char=substr(a.sort_char,1,1) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=2 and substr(sort_char,1,1)<>'0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;
 
  --------三。插入一、国家电网公司/二、其他下的单位类别下的单位明细--------
  --------三。1。针对单位类别corp_group in (11,14,23,24,25,26,27)。不含131和132，即不含13。不含12，12只在东北公司有单位明细。--------

  ----BC 插入一、国家电网公司/二、其他下的单位类别corp_group in (11,14,23,24,25,26,27) 下的单位明细(不含12和13)。
  --BC5 按单位类别、单位、电压等级、补偿电压等级分组数据，id_level=5。数据来源是源表reactive。
  --插入的sort_char是10位，第1、2位表示单位类别，第3位是1（和BA部分有区别，BA部分sort_char的第3位是0），第4、5位是单位排序号，第6-8是电压等级，第9、10位是补偿电压。
  --结果：第5层，sort_char=10位，单位类别||单位顺序号||电压等级||补偿电压等级=11||101||001||04。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_dept*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --按单位类别、单位代码、电压等级和补偿电压等级分组统计 开始
  with t as (select decode(branch_class,50,11, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27) corp_group,
                    reactive.dept_code,sort_no,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize) voltage_equalize,voltage,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                        nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                        nvl(e_static,0)+nvl(u_static,0)) sum_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
                    sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
                    sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
                    sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
                    sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
                    sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
                    sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode sys_dept_code
             from reactive,sub_dept
             where tab_year=year and sys_dept_code=sysdeptcode and sub_dept.dept_code=reactive.dept_code and
                   branch_class in (50,60,22,23,11,20,30,24) and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S')
                   and ('41311016130101000 '<>sysdeptcode  --不是河北
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --河北，只统计南网
                       )
             group by decode(branch_class,50,11, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27),reactive.dept_code,sort_no,
                      voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize))
  --按单位类别、单位代码、电压等级和补偿电压等级分组统计 结束
  select year,user_dept_code,
         id_start+decode(corp_group,'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept*cn_volt*cn_volt_equa+(rn-1)*cn_volt*cn_volt_equa+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(voltage_equalize,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+decode(corp_group,'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept*cn_volt+(rn-1)*cn_volt+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,5 id_level,
         decode(voltage_equalize,
                '0','1000千伏','O','±800千伏','1','750千伏','P','±660千伏','2','500千伏','Q','±500千伏','R','±400千伏','S','±400千伏以下','3','330千伏','4','220千伏','5','110千伏','B','66千伏','6','35千伏','C','20千伏','10千伏及以下') item_name,
         corp_group||'1'||lpad(rn,2,'0')||decode(voltage,'0','000','O','001','1','002','P','003','2','004','Q','005','R','006','S','007','3','008','4','009','5','010','B','011','6','012','C','013','014')||
         decode(voltage_equalize,'0','00','O','01','1','02','P','03','2','04','Q','05','R','06','S','07','3','08','4','09','5','10','B','11','6','12','C','13','14') sort_char,
         sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
         u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
  from
      (select t.corp_group,t.dept_code,rn,voltage_equalize,voltage,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
       from
           (select corp_group,dept_code,row_number() over(partition by corp_group order by sort_no) rn
            from t group by corp_group,dept_code,sort_no) a,t
       where a.dept_code=t.dept_code and t.sys_dept_code=sysdeptcode and a.corp_group=t.corp_group);

  --BC4 按单位类别、单位、电压等级分组数据，id_level=4。
  --插入的sort_char是8位，第1、2位表示单位类别，第3位是1，第4、5位是单位排序号，第6-8表示电压等级。数据来源是BC5部分插入的记录，取的sort_char是10位。
  --结果：第4层，sort_char=8位，(单位类别||单位顺序号||电压等级||补偿电压等级)第1、2、3段，即单位类别||单位顺序号||电压等级=11||101||001。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_dept*cn_volt;


  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,8),1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept*cn_volt+
         (substr(substr(sort_char,1,8),4,2)-1)*cn_volt+substr(substr(sort_char,1,8),7,2) id,--电压等级
         id_parent_start+decode(substr(substr(sort_char,1,8),1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept+
         substr(substr(sort_char,1,8),4,2)-1 parent_id,4 id_level,
         decode(substr(substr(sort_char,1,8),7,2),
                '00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,8) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=10 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,8);
  --commit;return;--testlzg
  --BC3 按单位类别、单位分组数据，id_level=3。插入的sort_char是5位，第1、2位表示单位类别，第3位是1，第4、5位是单位排序号。数据来源是源表reactive。
  --结果：第3层，sort_char=5位，(单位类别||单位顺序号||电压等级)第1、2段，即单位类别||单位顺序号=11||101。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_dept;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --按单位类别、单位代码分组统计 开始
  with t as (select corp_group,dept_code,dept_name,sort_no,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                        nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                        nvl(e_static,0)+nvl(u_static,0)) sum_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
                    sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
                    sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
                    sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
                    sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
                    sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
                    sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode sys_dept_code
             from (select decode(branch_class,50,11, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27) corp_group,reactive.dept_code,
                          sub_dept.area_name dept_name,
                          sort_no,e_phaseshiftor,u_phaseshiftor,e_capacitor,u_capacitor,e_reactor,u_reactor,e_other,u_other,e_static,u_static,
                          sysdeptcode sys_dept_code
                   from reactive,sub_dept
                   where tab_year=year and sys_dept_code=sysdeptcode and sub_dept.dept_code=reactive.dept_code and
                         branch_class in (50,60,22,23,11,20,30,24) and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S')
                         and ('41311016130101000 '<>sysdeptcode    --不是河北
                              or
                              exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code) --河北，只统计南网
                             )
                  )
             group by corp_group,dept_code,dept_name,sort_no)
  --按单位类别、单位代码分组统计 结束
  select year,user_dept_code,
         id_start+decode(corp_group,'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept+rn-1 id,
         null parent_id,3 id_level,dept_name item_name,corp_group||'1'||lpad(rn,2,'0') sort_char,
         sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
         u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
  from
      (select t.corp_group,t.dept_code,dept_name,rn,sort_no,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
       from
           (select corp_group,dept_code,row_number() over(partition by corp_group order by sort_no) rn
            from t group by corp_group,dept_code,sort_no) a,t
       where a.dept_code=t.dept_code and t.sys_dept_code=sysdeptcode and a.corp_group=t.corp_group);

  --更新BC3部分插入记录(sort_char为5位且第1位不是0且第3位不是0)的parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char=substr(a.sort_char,1,2) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=5 and substr(sort_char,1,1)<>'0' and substr(sort_char,3,1)<>'0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;


  --------三。2。针对单位类别corp_group in (131,132)即（三）省电力公司，插入一、国家电网公司下（三）省电力公司下的单位明细。2012-12-06--------
  --BX6 按单位类别（131/132）、单位、电压等级、补偿电压等级分组数据，id_level=6。数据来源是源表reactive。
  --插入的sort_char是11位，第1~3位表示单位类别，第4位是1（和BA部分有区别，BA部分sort_char的第4位是0），第5、6位是单位排序号，第7-9是电压等级，第10、11位是补偿电压。
  --2014-1-16 单位类别branch_class=21时，corp_group=133，拆分“2、全资子公司及控股公司”为“2、全资子公司”和“3、控股公司”。
  --结果：第6层，sort_char=11位，单位类别||1/2||单位顺序号||电压等级||补偿电压等级=13||1/2||101||001||04。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_dept*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --按单位类别、1/2、单位代码、电压等级和补偿电压等级分组统计 开始
  with t as (select decode(branch_class,10,131, 70,132, 21,133) corp_group,
                    reactive.dept_code,sort_no,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize) voltage_equalize,voltage,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                        nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                        nvl(e_static,0)+nvl(u_static,0)) sum_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
                    sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
                    sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
                    sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
                    sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
                    sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
                    sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode sys_dept_code
             from reactive,sub_dept
             where tab_year=year and sys_dept_code=sysdeptcode and sub_dept.dept_code=reactive.dept_code and
                   branch_class in (10,70,21) and voltage in ('0','1','2','3','4','5','6','B','C')
                   and ('41311016130101000 '<>sysdeptcode  --不是河北
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --河北，只统计南网
                       )
             group by decode(branch_class,10,131, 70,132, 21,133),reactive.dept_code,sort_no,
                      voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize))
  --按单位类别、1/2、单位代码、电压等级和补偿电压等级分组统计 结束
  select year,user_dept_code,
         id_start+decode(corp_group,'131',0,'132',1,'133',2)*cn_dept*cn_volt*cn_volt_equa+(rn-1)*cn_volt*cn_volt_equa+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(voltage_equalize,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+decode(corp_group,'131',0,'132',1,'133',2)*cn_dept*cn_volt+(rn-1)*cn_volt+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,6 id_level,
         decode(voltage_equalize,
                '0','1000千伏','O','±800千伏','1','750千伏','P','±660千伏','2','500千伏','Q','±500千伏','R','±400千伏','S','±400千伏以下','3','330千伏','4','220千伏','5','110千伏','B','66千伏','6','35千伏','C','20千伏','10千伏及以下') item_name,
         corp_group||'1'||lpad(rn,2,'0')||decode(voltage,'0','000','O','001','1','002','P','003','2','004','Q','005','R','006','S','007','3','008','4','009','5','010','B','011','6','012','C','013','014')||
         decode(voltage_equalize,'0','00','O','01','1','02','P','03','2','04','Q','05','R','06','S','07','3','08','4','09','5','10','B','11','6','12','C','13','14') sort_char,
         sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
         u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
  from
      (select t.corp_group,t.dept_code,rn,voltage_equalize,voltage,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
       from
           (select corp_group,dept_code,row_number() over(partition by corp_group order by sort_no) rn
            from t group by corp_group,dept_code,sort_no) a,t
       where a.dept_code=t.dept_code and t.sys_dept_code=sysdeptcode and a.corp_group=t.corp_group);

  --BX5 按单位类别、单位、电压等级分组数据，id_level=5。
  --插入的sort_char是9位，第1~3位表示单位类别，第4位是1，第5、6位是单位排序号，第7-9表示电压等级。数据来源是BX6部分插入的记录，取的sort_char是11位。
  --结果：第5层，sort_char=9位，(单位类别||1/2/3||单位顺序号||电压等级||补偿电压等级)第1、2、3、4段，即单位类别||1/2||单位顺序号||电压等级=13||1/2/3||101||001。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_dept*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,9),1,3),'131',0,'132',1,'133',2)*cn_dept*cn_volt+
         (substr(substr(sort_char,1,9),5,2)-1)*cn_volt+to_number(substr(substr(sort_char,1,9),8,2)) id,--电压等级
         id_parent_start+decode(substr(substr(sort_char,1,9),1,3),'131',0,'132',1,'133',2)*cn_dept+
         substr(substr(sort_char,1,9),5,2)-1 parent_id,5 id_level,
         decode(substr(substr(sort_char,1,9),8,2),
                '00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,9) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=11 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,9);

  --BX4 按单位类别、单位分组数据，id_level=4。插入的sort_char是6位，第1~3位表示单位类别，第4位是1，第5、6位是单位排序号。数据来源是源表reactive。
  --结果：第4层，sort_char=6位，(单位类别||1/2/3||单位顺序号||电压等级)第1、2、3段，即单位类别||1/2/3||单位顺序号=13||1/2/3||101。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_dept;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --按单位类别、单位代码分组统计 开始
  with t as (select corp_group,dept_code,dept_name,sort_no,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                        nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                        nvl(e_static,0)+nvl(u_static,0)) sum_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
                    sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
                    sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
                    sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
                    sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
                    sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
                    sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode sys_dept_code
             from (select decode(branch_class,10,131,70,132,21,133) corp_group,reactive.dept_code,
                          sub_dept.dept_name,--省电力公司下的单位名称用sub_dept中的dept_name
                          sort_no,e_phaseshiftor,u_phaseshiftor,e_capacitor,u_capacitor,e_reactor,u_reactor,e_other,u_other,e_static,u_static,
                          sysdeptcode sys_dept_code
                   from reactive,sub_dept
                   where tab_year=year and sys_dept_code=sysdeptcode and sub_dept.dept_code=reactive.dept_code and
                         branch_class in (10,70,21) and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S')
                         and ('41311016130101000 '<>sysdeptcode    --不是河北
                              or
                              exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code) --河北，只统计南网
                             )
                  )
             group by corp_group,dept_code,dept_name,sort_no)
  --按单位类别、单位代码分组统计 结束
  select year,user_dept_code,
         id_start+decode(corp_group,'131',0, '132',1,'133',2)*cn_dept+rn-1 id,
         null parent_id,4 id_level,dept_name item_name,corp_group||'1'||lpad(rn,2,'0') sort_char,
         sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
         u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
  from
      (select t.corp_group,t.dept_code,dept_name,rn,sort_no,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
       from
           (select corp_group,dept_code,row_number() over(partition by corp_group order by sort_no) rn
            from t group by corp_group,dept_code,sort_no) a,t
       where a.dept_code=t.dept_code and t.sys_dept_code=sysdeptcode and a.corp_group=t.corp_group);

  --BY5 按单位类别(131/132/133)、电压等级、补偿电压等级分组数据，id_level=5。
  --插入的sort_char是8位，第1~3位表示单位类别，第4-6表示电压等级，第7、8位表示补偿电压。数据来源是BX6部分插入的记录，取sort_char的前3位||后5位。
  --结果：第5层，sort_char=8位,单位类别||1/2/3||电压等级||补偿电压等级=13||1/2/3||001||04。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(sort_char,1,3),'131',0,'132',1,'133',2)*cn_volt*cn_volt_equa+substr(substr(sort_char,7,5),2,2)*cn_volt_equa+substr(substr(sort_char,7,5),4,2) id,
         id_parent_start+decode(substr(sort_char,1,3),'131',0,'132',1,'133',2)*cn_volt+substr(substr(sort_char,7,5),2,2) parent_id,5 id_level,
         decode(substr(substr(sort_char,7,5),4,2),
                '00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,3)||substr(sort_char,7,5) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=11 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,7,5),substr(sort_char,1,3);

  --BY4 按单位类别(131/132/133)、电压等级分组数据，id_level=4。
  --插入的sort_char是6位，第1~3位表示单位类别，第4-6表示电压等级。数据来源是BY5部分插入的记录，取sort_char的前6位。
  --结果：第4层，sort_char=6位,(单位类别||1/2/3||电压等级||补偿电压等级)的第1、2段，即单位类别||1/2/3||电压等级=13||1/2/3||001。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,6),1,3),'131',0,'132',1,'133',2)*cn_volt+substr(substr(sort_char,1,6),5,2) id,
         id_parent_start+decode(substr(substr(sort_char,1,6),1,3),'131',0,'132',1,'133',2) parent_id,4 id_level,
         decode(substr(substr(sort_char,1,6),5,2),
                '00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,6) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
     sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=8 and substr(sort_char,1,2)='13' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,6);

  ----BY3 插入131（三）省电力公司->1、母公司和132（三）省电力公司->2、全资子公司及控股公司，id_level=3。
  --插入的sort_char是3位。数据来源是BY4部分插入的记录，取sort_char的前3位。
  --2014-1-16 单位类别branch_class=21时，corp_group=133，拆分“2、全资子公司及控股公司”为“2、全资子公司”和“3、控股公司”。
  --结果：第3层，sort_char=3位,(单位类别||1/2/3||电压等级)的第1、2段，即单位类别||1/2/3=13||1/2/3。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(sort_char,1,3),'131',0,'132',1,'133',2) id,null parent_id,3 id_level,
         decode(substr(sort_char,1,3),'131','1、母公司', '132','2、全资子公司','133','3、控股公司') item_name,
         substr(sort_char,1,3) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
      sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=6 and substr(sort_char,1,2)='13' and substr(sort_char,4,1)='0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,3);

  --更新BY3部分插入记录(131（三）省电力公司->1、母公司和132（三）省电力公司->2、全资子公司和133（三）省电力公司->3、控股公司)(sort_char为3位且第1~2位是13)的parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char = substr(a.sort_char,1,2) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=3 and substr(sort_char,1,2)='13' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --更新BX4部分插入记录(sort_char为6位且第1~2位是13且第4位是1)的parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char = substr(a.sort_char,1,3) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=6 and substr(sort_char,1,2)='13' and substr(sort_char,4,1)='1' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --------四。插入二、其他下的单位明细corp_group in (23,24,25,26,27)--------
  ----BD 插入“二、其他”下的单位明细。
  --BD4 按单位、电压等级、补偿电压等级分组数据，id_level=4。数据来源是源表reactive。插入的sort_char是9位，第1、2位是21，第3、4位是单位排序号，第5-7位是电压等级，第8、9表示补偿电压等级。
  --结果：第4层，sort_char=9位，2||单位顺序号||电压等级||补偿电压等级=2||101||001||04。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_dept*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --按单位代码、电压等级、补偿电压等级分组统计 开始
  with t as (select reactive.dept_code,sort_no,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize) voltage_equalize,voltage,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                        nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                        nvl(e_static,0)+nvl(u_static,0)) sum_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
                    sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
                    sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
                    sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
                    sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
                    sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
                    sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode sys_dept_code
             from reactive,sub_dept
             where tab_year=year and sys_dept_code=sysdeptcode and sub_dept.dept_code=reactive.dept_code and
                   branch_class in (22,23,11,20,30,24) and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S')
                   and ('41311016130101000 '<>sysdeptcode  --不是河北
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --河北，只统计南网
                       )
             group by reactive.dept_code,sort_no,voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize))
  --按单位代码、电压等级、补偿电压等级分组统计 结束
  select year,user_dept_code,
         id_start+(rn-1)*cn_volt*cn_volt_equa+decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(voltage_equalize,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+(rn-1)*cn_volt+decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,4 id_level,
         decode(voltage_equalize,
                '0','1000千伏','O','±800千伏','1','750千伏','P','±660千伏','2','500千伏','Q','±500千伏','R','±400千伏','S','±400千伏以下','3','330千伏','4','220千伏','5','110千伏','B','66千伏','6','35千伏','C','20千伏','10千伏及以下') item_name,
         '21'||lpad(rn,2,'0')||decode(voltage,'0','000','O','001','1','002','P','003','2','004','Q','005','R','006','S','007','3','008','4','009','5','010','B','011','6','012','C','013','014')||
         decode(voltage_equalize,'0','00','O','01','1','02','P','03','2','04','Q','05','R','06','S','07','3','08','4','09','5','10','B','11','6','12','C','13','14') sort_char,
         sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
         u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
  from
      (select t.dept_code,rn,sort_no,voltage_equalize,voltage,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
       from
           (select dept_code,rownum rn from(select dept_code
            from t group by dept_code,sort_no order by sort_no)
           ) a,t
       where a.dept_code=t.dept_code and t.sys_dept_code=sysdeptcode);

  --BD3 按单位、电压等级分组数据，id_level=3。插入的sort_char是7位，第1、2位是21，第3、4位是单位排序号，第5-7位是电压等级。数据来源是BD4部分插入的记录，取sort_char的前7位。
  --结果：第3层，sort_char=7位，(2||单位顺序号||电压等级||补偿电压等级)第1、2、3段，即2||单位顺序号||电压等级=2||101||001。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_dept*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code, id_start+ (substr(substr(sort_char,1,7),3,2)-1)*cn_volt +
         substr(substr(sort_char,1,7),6,2) id,--取sort_char的第7位，表示电压等级
         id_parent_start+substr(substr(sort_char,1,7),3,2)-1 parent_id,3 id_level,
         decode(substr(substr(sort_char,1,7),6,2),
                '00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
         substr(sort_char,1,7) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=9 and substr(sort_char,1,1)='2' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,7);

  --BD2 按单位分组数据，id_level=2。插入单位节点。插入的sort_char是4位，第1、2位是21，第3、4位是单位排序号。数据来源是源表reactive。
  --结果：第2层，sort_char=4位，2||单位顺序号=2||101。
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_dept;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --按单位代码分组统计 开始
  with t as (select reactive.dept_code,area_name dept_name,sort_no,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                        nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                        nvl(e_static,0)+nvl(u_static,0)) sum_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
                    sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
                    sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
                    sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
                    sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
                    sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
                    sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
                    sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode sys_dept_code
             from reactive,sub_dept
             where tab_year=year and sys_dept_code=sysdeptcode and sub_dept.dept_code=reactive.dept_code and
                   branch_class in(22,23,11,20,30,24) and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S')
                   and ('41311016130101000 '<>sysdeptcode  --不是河北
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --河北，只统计南网
                       )
             group by reactive.dept_code,area_name,sort_no)
  --按单位代码分组统计 结束
  select year,user_dept_code,id_start+rn-1 id,null parent_id,2 id_level,dept_name,'21'||lpad(rn,2,'0') sort_char,
         sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
         u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
  from
      (select t.dept_code,dept_name,rn,sort_no,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
       from
           (select dept_code,rownum rn from(select dept_code
            from t group by dept_code,sort_no order by sort_no)
           ) a,t
       where a.dept_code=t.dept_code and t.sys_dept_code=sysdeptcode);

  --更新BD2部分插入的记录(sort_char为4位且前两位是'21')的parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char='2' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=4 and substr(sort_char,1,2)='21' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --------五。东北公司，在区域公司（分部）下插入超高压局(branch_class=40)、省间联络线(branch_class=45)，它们是主管企业(branch_name)--------
  IF user_dept_code='41211021820000001 ' or user_dept_code='41311026210102900 ' or user_dept_code='41311026220104100 ' or user_dept_code='41311026230103000 ' THEN

     ----1。针对超高压局(branch_class=40)----
     --插入按主管企业(branch_name)分组统计（等同于按单位代码分组统计）。sort_char 5位。数据来源是源表reactive。
     --结果：第3层，sort_char=5位，12||主管企业顺序号=12||101。12就是区域公司（分部）。
     id_start := id_parent_start;
     id_parent_start := id_parent_start + cn_dept;

     insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
                 sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select year,user_dept_code,id_start+(row_number() over(order by branch_name)-1) id,null parent_id,
            3 id_level,branch_name item_name,'121'||lpad(row_number() over(order by branch_name),2,'0') sort_char,
            sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                nvl(e_static,0)+nvl(u_static,0)),
            sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)),
            sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)),
            sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)),sum(e_phaseshiftor),sum(u_phaseshiftor),
            sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)),sum(e_capacitor),sum(u_capacitor),
            sum(nvl(e_reactor,0)+nvl(u_reactor,0)),sum(e_reactor),sum(u_reactor),
            sum(nvl(e_other,0)+nvl(u_other,0)),sum(e_other),sum(u_other),
            sum(nvl(e_static,0)+nvl(u_static,0)),sum(e_static),sum(u_static),sysdeptcode
     from reactive
     where tab_year=year and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S') and branch_class=40 and sys_dept_code=sysdeptcode
           and ('41311016130101000 '<>sysdeptcode  --不是河北
                or
                exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --河北，只统计南网
               )
     group by branch_name;

  --更新超高压局,省间联络线的parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char='12' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=5 and substr(sort_char,1,3)='121' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;


  END IF;

  --------六。河北，增加南网、北网按电压统计。--------
  IF user_dept_code='41311016130101000 ' THEN

     --C4 插入按南/北网，单位，电压等级分组数据，sort_char 6位 ,第一位为9
     --结果：第4层，sort_char=6位，91/92||单位顺序号||电压等级(1位)=91/92||101||4。91/92就是南网/北网。
     id_start := id_parent_start;
     id_parent_start := id_parent_start+2*cn_dept*cn_volt;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     --按南/北网、单位、电压等级分组统计 开始
     with t as(select a.dept_code,nvl(manage_property,0) manage_property,sort_no,voltage,
                      sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                          nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                          nvl(e_static,0)+nvl(u_static,0)) sum_power,
                      sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
                      sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
                      sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
                      sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
                      sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
                      sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
                      sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
                      sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode sys_dept_code
               from reactive a,sub_dept b
               where voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S') and tab_year=year and sys_dept_code=sysdeptcode and a.dept_code=b.dept_code
               group by a.dept_code,manage_property,sort_no,voltage)
     --按南/北网、单位、电压等级分组统计 结束
     select decode(voltage,'0','1000千伏','O','±800千伏','1','750千伏','P','±660千伏','2','500千伏','Q','±500千伏','R','±400千伏','S','±400千伏以下','3','330千伏','4','220千伏','5','110千伏','B','66千伏','6','35千伏','C','20千伏','10千伏及以下') item_name,
            decode(manage_property,0,'911','921')||lpad(rn,2,'0')||decode(voltage,'0','00','O','01','1','02','P','03','2','04','Q','05','R','06','S','07','3','08','4','09','5','10','B','11','6','12','C','13','14') sort_char,
            null item_code,id_start+decode(manage_property,0,0,cn_dept*cn_volt)+(rn-1)*cn_volt+decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
            id_parent_start+decode(manage_property,0,0,cn_dept)+(rn-1) parent_id,
            4 id_level,null sort_no,null sub_sort,user_dept_code dept_code,year tab_year,null gateway_pos,null item_unit,
            sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
            u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
     from
         (select t.manage_property,t.dept_code,rn,voltage,
                 sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code
          from
              (select manage_property,dept_code,row_number() over(partition by manage_property order by sort_no) rn
               from t group by manage_property,dept_code,sort_no) a,t
          where a.dept_code=t.dept_code and t.sys_dept_code=sysdeptcode and a.manage_property=t.manage_property);

     --CA3 插入南/北网、单位分组项：数据来源是源表reactive。
     --结果：第3层，sort_char=5位，91/92||单位顺序号=91/92||101。91/92就是南网/北网。
     id_start := id_parent_start;
     id_parent_start := id_parent_start+2*cn_dept;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select dept_name item_name,
            decode(nvl(manage_property,0),0,'911','921')||lpad(row_number() over(partition by nvl(manage_property,0) order by sort_no),2,'0') sort_char,
            null item_code,id_start+decode(nvl(manage_property,0),0,0,cn_dept)+(row_number() over(partition by nvl(manage_property,0) order by sort_no)-1) id,
            null parent_id,
            3 id_level,null sort_no,null sub_sort,user_dept_code dept_code,year tab_year,null gateway_pos,null item_unit,
            sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+
                nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+
                nvl(e_static,0)+nvl(u_static,0)) sum_power,
            sum(nvl(e_phaseshiftor,0)+nvl(e_capacitor,0)+nvl(e_reactor,0)+nvl(e_other,0)+nvl(e_static,0)) e_power,
            sum(nvl(u_phaseshiftor,0)+nvl(u_capacitor,0)+nvl(u_reactor,0)+nvl(u_other,0)+nvl(u_static,0)) u_power,
            sum(nvl(e_phaseshiftor,0)+nvl(u_phaseshiftor,0)) sum_phase,sum(e_phaseshiftor) e_phase,
            sum(u_phaseshiftor) u_phase,sum(nvl(e_capacitor,0)+nvl(u_capacitor,0)) sum_capacitor,
            sum(e_capacitor) e_capacitor,sum(u_capacitor) u_capacitor,
            sum(nvl(e_reactor,0)+nvl(u_reactor,0)) sum_reactor,sum(e_reactor) e_reactor,sum(u_reactor) u_reactor,
            sum(nvl(e_other,0)+nvl(u_other,0)) sum_other,sum(e_other) e_other,sum(u_other) u_other,
            sum(nvl(e_static,0)+nvl(u_static,0)) sum_static,sum(e_static) e_static,sum(u_static) u_static,sysdeptcode
     from reactive a, sub_dept b
     where voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S') and tab_year=year and sys_dept_code=sysdeptcode and a.dept_code=b.dept_code
     group by a.dept_code,dept_name,nvl(manage_property,0),sort_no;

     --CB3 插入南/北网、电压等级分组项：数据来源是C4部分插入的记录。
     --结果：第3层，sort_char=4位，91/92||0||电压等级(1位)=91/92||0||4。91/92就是南网/北网。
     id_start := id_parent_start;
     id_parent_start := id_parent_start+2*cn_volt;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select decode(substr(sort_char,6,2),'00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
            substr(sort_char,1,2)||'0'||substr(sort_char,6,2) sort_char,null item_code,
            id_start+(substr(substr(sort_char,1,2),2,1)-1)*cn_volt+substr(sort_char,6,2) id,
            id_parent_start +substr(substr(sort_char,1,2),2,1)-1 parent_id,
            3 id_level,null sort_no,null sub_sort,user_dept_code dept_code,year tab_year,
            null gateway_pos,null item_unit,sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
            sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
            sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
            sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
     from pro_reactive
     where length(sort_char)=7 and substr(sort_char,1,1)='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
     group by substr(sort_char,1,2),substr(sort_char,6,2);

     --南北网小计,在南北网下的电压统计数据上统计
     --CB2 插入南/北网分组项：数据来源是CB3部分插入的记录。
     --结果：第2层，sort_char=2位，(91/92||0||电压等级(1位)的第1段，即91/92=91/92。91/92就是南网/北网。
     id_start := id_parent_start;
     id_parent_start := id_parent_start+2;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select decode(substr(sort_char,1,2),'91','1、河北南网小计','2、河北北网小计') item_name,
            substr(sort_char,1,2) sort_char,null item_code,
            id_start+(substr(substr(sort_char,1,2),2,1)-1) id,null parent_id,
            2 id_level,null sort_no,null sub_sort,user_dept_code dept_code,year tab_year,
            null gateway_pos,null item_unit,sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
            sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
            sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
            sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
     from pro_reactive
     where length(sort_char)=5 and substr(sort_char,1,1)='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
     group by substr(sort_char,1,2);

     --在全省总计下按电压统计,基于南北网小计下的电压统计数据，按电压等级分组统计。
     --CC2 插入电压统计分组项：数据来源是CB3部分插入的记录。
     --结果：第2层，sort_char=3位，9||0||电压等级(1位)=9||0||4。9就是南网和北网的上级。
     id_start := id_parent_start;
     id_parent_start := id_parent_start+cn_volt;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select decode(substr(sort_char,4,2),'00','1000千伏','01','±800千伏','02','750千伏','03','±660千伏','04','500千伏','05','±500千伏','06','±400千伏','07','±400千伏以下','08','330千伏','09','220千伏','10','110千伏','11','66千伏','12','35千伏','13','20千伏','10千伏及以下') item_name,
            '90'||substr(sort_char,4,2) sort_char,null item_code,
            id_start+substr(sort_char,4,2) id,
            id_parent_start parent_id,2 id_level,null sort_no,null sub_sort,user_dept_code dept_code,year tab_year,
            null gateway_pos,null item_unit,sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
            sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
            sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
            sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
     from pro_reactive
     where length(sort_char)=5 and substr(sort_char,1,1)='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
     group by substr(sort_char,4,2);

     --C1 全省总计,在全省总计下的电压统计数据上统计。数据来源是CC2部分插入的记录。
     --结果：第1层，sort_char=1位，就是9。
     id_start := id_parent_start;
     --id_parent_start := id_parent_start+1;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select '全省总计' item_name,'9' sort_char,null item_code,id_start id,0 parent_id,
            1 id_level,null sort_no,null sub_sort,user_dept_code dept_code,year tab_year,
            null gateway_pos, null item_unit,sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
            sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
            sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
            sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
     from pro_reactive
     where length(sort_char)=4 and substr(sort_char,1,1)='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

     --更新CA3部分插入记录的parent_id
     update pro_reactive a
     set parent_id=
         (select id from pro_reactive where sort_char=substr(a.sort_char,1,2) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
     where length(sort_char)=5 and substr(sort_char,1,1)='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

     --更新CB2南北网小计统计数据的parent_id
     update pro_reactive a
     set parent_id=
         (select id from pro_reactive where sort_char='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
     where (sort_char='91' or sort_char='92') and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;
  END IF;

  --更新sort_no
  update pro_reactive a
  set sort_no=
      (select rn
       from
           (select id,rownum rn
            from
                (select * from pro_reactive where dept_code=user_dept_code and tab_year=year and sys_dept_code=sysdeptcode order by sort_char)
           ) b
       where b.id=a.id
      )
  where dept_code=user_dept_code and tab_year=year and sys_dept_code=sysdeptcode;

  commit;

end p_pro_reactive;
/
