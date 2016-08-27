create or replace procedure p_pro_reactive
(year in number,sysdeptcode in char)
is
  user_dept_code char(18);
  id_start number(6);--����ͳ��ʱid��ʼֵ
  id_parent_start number(6);--����ͳ��ʱparent_id��ʼֵ
  cn_volt number(3);--��ѹ�ȼ���ֵ����
  cn_volt_equa number(3);--������ѹ�ȼ���ֵ����
  cn_branch_class number(3);--��λ�����ֵ����
  cn_dept number(3);--��λ����
begin
  user_dept_code := sysdeptcode;
  cn_volt := 15;
  cn_volt_equa := 15;
  --2014-1-16 ����2��ȫ���ӹ�˾���عɹ�˾�����Ϊ��2��ȫ���ӹ�˾���͡�3���عɹ�˾��������һ����λ���cn_branch_class=:9->cn_branch_class:=10
  cn_branch_class := 10;
  cn_dept := 99;

  --2014-1-16 ��ѹ�ȼ�����Ϊ0�ĵ�ѹ�ȼ������ɡ��ظ�ѹ���޸�Ϊ��1000ǧ����
  --2014-1-16 ����������ʡ������˾���µġ�2��ȫ���ӹ�˾���عɹ�˾�����Ϊ��2��ȫ���ӹ�˾���͡�3���عɹ�˾��
  --ɾ�������ϴ�ͳ�Ƶ�����
  delete from pro_reactive where tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  ----һ����������ܼƼ���ϸ
  --A3 ����ѹ�ȼ���������ѹ�ȼ��������ݣ�id_level=3�������sort_char��5λ����1-3λ��ʾ��ѹ�ȼ�����4��5λ��ʾ������ѹ��������Դ��Դ��reactive��
  --�������3�㣬sort_char=5λ����ѹ�ȼ�||������ѹ=001||04��
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
                  '0','1000ǧ��','O','��800ǧ��','1','750ǧ��','P','��660ǧ��','2','500ǧ��','Q','��500ǧ��','R','��400ǧ��','S','��400ǧ������','3','330ǧ��','4','220ǧ��','5','110ǧ��','B','66ǧ��','6','35ǧ��','C','20ǧ��','10ǧ��������') item_name,
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
  and ('41311016130101000 '<>sysdeptcode  --���Ǻӱ�
       or
       exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --�ӱ���ֻͳ������
      )
  group by voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize);

  --A2 ����ѹ�ȼ��������ݣ�id_level=2�������sort_char��3λ����ʾ��ѹ�ȼ���������Դ��A1���ֲ���ļ�¼��ȡ��sort_char��5λ��
  --�������2�㣬sort_char=3λ��(��ѹ�ȼ�||������ѹ=001||04)�ĵ�1�Σ�������ѹ�ȼ�=001��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code, id_start+to_number(substr(sort_char,1,3)) id,--ȡ5λ��sort_char�ĵ�3λ����ʾ��ѹ�ȼ�
         id_parent_start parent_id,2,
         decode(substr(sort_char,1,3),
                '000','1000ǧ��','001','��800ǧ��','002','750ǧ��','003','��660ǧ��','004','500ǧ��','005','��500ǧ��','006','��400ǧ��','007','��400ǧ������','008','330ǧ��','009','220ǧ��','010','110ǧ��','011','66ǧ��','012','35ǧ��','013','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,3) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,3);

  --A1 �����ܼ��id_level=1��1����¼��sort_charΪ0��������Դ��A2���ֲ���ļ�¼��ȡ��sort_char��3λ��
  --�������1�㣬sort_char=0��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 1;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code, id_start id,0 parent_id, 1,'�����ܼ�' item_name,'0' sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=3 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --------��������һ�����ҵ�����˾/��������������ϸcorp_group in (11,12,13,14,23,24,25,26,27)����ȫ���ĵ�λ���--------
  --BA4 ����λ��𡢵�ѹ�ȼ���������ѹ�ȼ��������ݣ�id_level=4�������sort_char��7λ��
  --��1��2λ��ʾ��λ��𣨵�һλΪ1����2��1��ʾ��һ�����ҵ�����˾����2��ʾ������������������3-5��ʾ��ѹ�ȼ�����6��7λ��ʾ������ѹ�ȼ���������Դ��Դ��reactive��
  --2014-1-16��λ����н�ȫ���ӹ�˾�Ϳعɹ�˾��֣�branch_class=21ʱΪ�عɹ�˾
  --�������4�㣬sort_char=7λ����λ���||��ѹ�ȼ�||������ѹ�ȼ�=11||001||04��
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
                           '0','1000ǧ��','O','��800ǧ��','1','750ǧ��','P','��660ǧ��','2','500ǧ��','Q','��500ǧ��','R','��400ǧ��','S','��400ǧ������','3','330ǧ��','4','220ǧ��','5','110ǧ��','B','66ǧ��','6','35ǧ��','C','20ǧ��','10ǧ��������') item_name,
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
  and ('41311016130101000 '<>sysdeptcode  --���Ǻӱ�
       or
       exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --�ӱ���ֻͳ������
      )
  group by substr(decode(branch_class,50,11, 40,12, 45,12, 10,131, 70,132, 21,133, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27),1,2),
           voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize);

  --BA3 ����λ��𡢵�ѹ�ȼ��������ݣ�id_level=3�������sort_char��5λ��
  --��1��2��ʾ��λ��𣨵�һλΪ1����2��1��ʾ��һ�����ҵ�����˾����2��ʾ������������������3-5λ��ʾ��ѹ�ȼ���������Դ��BA4���ֲ���ļ�¼��ȡ��sort_char��5λ��
  --�������3�㣬sort_char=5λ��(��λ���||��ѹ�ȼ�||������ѹ�ȼ�)�ĵ�1��2�Σ�������λ���||��ѹ�ȼ�=11||001��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,5),1,2),
                         '11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_volt+to_number(substr(substr(sort_char,1,5),3,3)) id,--ȡ7λ��sort_char�ĵ�5λ����ʾ��ѹ�ȼ�
         id_parent_start+decode(substr(substr(sort_char,1,5),1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8) parent_id,
         3 id_level,decode(substr(substr(sort_char,1,5),3,3),/*decode(substr(sort_char,3,3),*/
                           '000','1000ǧ��','001','��800ǧ��','002','750ǧ��','003','��660ǧ��','004','500ǧ��','005','��500ǧ��','006','��400ǧ��','007','��400ǧ������','008','330ǧ��','009','220ǧ��','010','110ǧ��','011','66ǧ��','012','35ǧ��','013','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,5) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=7 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,5);
--commit;return;--testlzg
  --BA2 ����λ���������ݣ�id_level=2�������sort_char��2λ����1��2��ʾ��λ��𣨵�һλΪ1����2��1��ʾ��һ�����ҵ�����˾����2��ʾ����������������
  --������Դ��BA3���ֲ���ļ�¼��ȡ��sort_char��5λ����Щ��¼�ĸ��ڵ��ǲ����ڵģ�����Ϊ999991��ʾ��һ�����ҵ�����˾����999992��ʾ������������,�������sort_char����B1���·���
  --�������2�㣬sort_char=2λ��(��λ���||��ѹ�ȼ�)�ĵ�1�Σ�������λ���=11��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(sort_char,1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8) id,
         decode(substr(sort_char,1,2),'11',999991, '12',999991, '13',999991, 999992) parent_id,2 id_level,  --parent_id��B1���ּ�¼����󣬻���updateһ��
         decode(substr(sort_char,1,2),'11','��һ���ܲ�','12','�������ֲ�','13','������ʡ������˾','14','���ģ�����ʡ��˾','23','��һ���ι�','24','����������',
                '25','�������ط�������˾','26','���ģ��û�','27','���壩�糧') item_name,substr(sort_char,1,2) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=5 and substr(sort_char,1,1)<>'0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,2);

  --BB3 ����λ���ĵ�һλ����һλΪ1����2��1��ʾ��һ�����ҵ�����˾����2��ʾ������������������ѹ�ȼ���������ѹ�ȼ��������ݣ�id_level=3��
  --�����sort_char��6λ����1λΪ1��2��1��ʾ��һ�����ҵ�����˾����2��ʾ������������������2-4��ʾ��ѹ�ȼ�����5��6λ��ʾ������ѹ��������Դ��BA4���ֲ���ļ�¼��ȡ��sort_char��7λ��
  --�������3�㣬sort_char=6λ,��λ����1λ||��ѹ�ȼ�||������ѹ�ȼ�=1||001||04��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 2*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+(substr(sort_char,1,1)-1)*cn_volt*cn_volt_equa+to_number(substr(substr(sort_char,3,5),1,3))*cn_volt_equa+to_number(substr(substr(sort_char,3,5),4,2)) id,
         id_parent_start+(substr(sort_char,1,1)-1)*cn_volt+substr(substr(sort_char,3,5),3,1) parent_id,3 id_level,
         decode(substr(substr(sort_char,3,5),4,2),
                '00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,1)||substr(sort_char,3,5) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=7 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,3,5),substr(sort_char,1,1);

  --BB2 ����λ���ĵ�һλ����һλΪ1����2��1��ʾ��һ�����ҵ�����˾����2��ʾ������������������ѹ�ȼ��������ݣ�id_level=2��
  --�����sort_char��4λ����1λΪ1��2��1��ʾ��һ�����ҵ�����˾����2��ʾ������������������2-4��ʾ��ѹ�ȼ���������Դ��BB3���ֲ���ļ�¼��ȡ��sort_char��6λ��
  --�������2�㣬sort_char=4λ,(��λ����1λ||��ѹ�ȼ�||������ѹ�ȼ�)�ĵ�1��2�Σ�����λ����1λ||��ѹ�ȼ�=1||001��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 2*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+(substr(substr(sort_char,1,4),1,1)-1)*cn_volt+to_number(substr(substr(sort_char,1,4),2,3)) id,
         id_parent_start+substr(substr(sort_char,1,4),1,1)-1 parent_id,2 id_level,
         decode(substr(substr(sort_char,1,4),2,3),
                '000','1000ǧ��','001','��800ǧ��','002','750ǧ��','003','��660ǧ��','004','500ǧ��','005','��500ǧ��','006','��400ǧ��','007','��400ǧ������','008','330ǧ��','009','220ǧ��','010','110ǧ��','011','66ǧ��','012','35ǧ��','013','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,4) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
     sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=6 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,4);

  ----B1 ����һ�����ҵ�����˾����������������λ���ĵ�һλ����һλΪ1����2��1��ʾ��һ�����ҵ�����˾����2��ʾ���������������������ݣ�id_level=1��
  --�����sort_char��1λ���ֱ�Ϊ'1'��'2'�����롰һ�����ҵ�����˾���͡�������������������¼�����ڵ�id����0��������Դ��BB2���ֲ���ļ�¼��ȡ��sort_char��4λ��
  --�������1�㣬sort_char=1λ,(��λ����1λ||��ѹ�ȼ�)�ĵ�1�Σ�����λ����1λ=1��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 2;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+substr(sort_char,1,1)-1,0 parent_id,1 id_level,
         decode(substr(sort_char,1,1),'1','һ�����ҵ�����˾', '2','��������') item_name,
         substr(sort_char,1,1) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
      sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=4 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,1);

  --����BA2���ֲ����¼(sort_charΪ2λ�ҵ�1λ����0)��parent_id��ȡ��B1����ļ�¼��
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char=substr(a.sort_char,1,1) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=2 and substr(sort_char,1,1)<>'0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;
 
  --------��������һ�����ҵ�����˾/���������µĵ�λ����µĵ�λ��ϸ--------
  --------����1����Ե�λ���corp_group in (11,14,23,24,25,26,27)������131��132��������13������12��12ֻ�ڶ�����˾�е�λ��ϸ��--------

  ----BC ����һ�����ҵ�����˾/���������µĵ�λ���corp_group in (11,14,23,24,25,26,27) �µĵ�λ��ϸ(����12��13)��
  --BC5 ����λ��𡢵�λ����ѹ�ȼ���������ѹ�ȼ��������ݣ�id_level=5��������Դ��Դ��reactive��
  --�����sort_char��10λ����1��2λ��ʾ��λ��𣬵�3λ��1����BA����������BA����sort_char�ĵ�3λ��0������4��5λ�ǵ�λ����ţ���6-8�ǵ�ѹ�ȼ�����9��10λ�ǲ�����ѹ��
  --�������5�㣬sort_char=10λ����λ���||��λ˳���||��ѹ�ȼ�||������ѹ�ȼ�=11||101||001||04��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_dept*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --����λ��𡢵�λ���롢��ѹ�ȼ��Ͳ�����ѹ�ȼ�����ͳ�� ��ʼ
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
                   and ('41311016130101000 '<>sysdeptcode  --���Ǻӱ�
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --�ӱ���ֻͳ������
                       )
             group by decode(branch_class,50,11, 60,14, 22,23, 23,24, 11,25, 20,25, 30,26, 24,27),reactive.dept_code,sort_no,
                      voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize))
  --����λ��𡢵�λ���롢��ѹ�ȼ��Ͳ�����ѹ�ȼ�����ͳ�� ����
  select year,user_dept_code,
         id_start+decode(corp_group,'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept*cn_volt*cn_volt_equa+(rn-1)*cn_volt*cn_volt_equa+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(voltage_equalize,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+decode(corp_group,'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept*cn_volt+(rn-1)*cn_volt+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,5 id_level,
         decode(voltage_equalize,
                '0','1000ǧ��','O','��800ǧ��','1','750ǧ��','P','��660ǧ��','2','500ǧ��','Q','��500ǧ��','R','��400ǧ��','S','��400ǧ������','3','330ǧ��','4','220ǧ��','5','110ǧ��','B','66ǧ��','6','35ǧ��','C','20ǧ��','10ǧ��������') item_name,
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

  --BC4 ����λ��𡢵�λ����ѹ�ȼ��������ݣ�id_level=4��
  --�����sort_char��8λ����1��2λ��ʾ��λ��𣬵�3λ��1����4��5λ�ǵ�λ����ţ���6-8��ʾ��ѹ�ȼ���������Դ��BC5���ֲ���ļ�¼��ȡ��sort_char��10λ��
  --�������4�㣬sort_char=8λ��(��λ���||��λ˳���||��ѹ�ȼ�||������ѹ�ȼ�)��1��2��3�Σ�����λ���||��λ˳���||��ѹ�ȼ�=11||101||001��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_dept*cn_volt;


  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,8),1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept*cn_volt+
         (substr(substr(sort_char,1,8),4,2)-1)*cn_volt+substr(substr(sort_char,1,8),7,2) id,--��ѹ�ȼ�
         id_parent_start+decode(substr(substr(sort_char,1,8),1,2),'11',0, '12',1, '13',2, '14',3, '23',4, '24',5, '25',6, '26',7, '27',8)*cn_dept+
         substr(substr(sort_char,1,8),4,2)-1 parent_id,4 id_level,
         decode(substr(substr(sort_char,1,8),7,2),
                '00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,8) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=10 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,8);
  --commit;return;--testlzg
  --BC3 ����λ��𡢵�λ�������ݣ�id_level=3�������sort_char��5λ����1��2λ��ʾ��λ��𣬵�3λ��1����4��5λ�ǵ�λ����š�������Դ��Դ��reactive��
  --�������3�㣬sort_char=5λ��(��λ���||��λ˳���||��ѹ�ȼ�)��1��2�Σ�����λ���||��λ˳���=11||101��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_branch_class*cn_dept;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --����λ��𡢵�λ�������ͳ�� ��ʼ
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
                         and ('41311016130101000 '<>sysdeptcode    --���Ǻӱ�
                              or
                              exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code) --�ӱ���ֻͳ������
                             )
                  )
             group by corp_group,dept_code,dept_name,sort_no)
  --����λ��𡢵�λ�������ͳ�� ����
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

  --����BC3���ֲ����¼(sort_charΪ5λ�ҵ�1λ����0�ҵ�3λ����0)��parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char=substr(a.sort_char,1,2) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=5 and substr(sort_char,1,1)<>'0' and substr(sort_char,3,1)<>'0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;


  --------����2����Ե�λ���corp_group in (131,132)��������ʡ������˾������һ�����ҵ�����˾�£�����ʡ������˾�µĵ�λ��ϸ��2012-12-06--------
  --BX6 ����λ���131/132������λ����ѹ�ȼ���������ѹ�ȼ��������ݣ�id_level=6��������Դ��Դ��reactive��
  --�����sort_char��11λ����1~3λ��ʾ��λ��𣬵�4λ��1����BA����������BA����sort_char�ĵ�4λ��0������5��6λ�ǵ�λ����ţ���7-9�ǵ�ѹ�ȼ�����10��11λ�ǲ�����ѹ��
  --2014-1-16 ��λ���branch_class=21ʱ��corp_group=133����֡�2��ȫ���ӹ�˾���عɹ�˾��Ϊ��2��ȫ���ӹ�˾���͡�3���عɹ�˾����
  --�������6�㣬sort_char=11λ����λ���||1/2||��λ˳���||��ѹ�ȼ�||������ѹ�ȼ�=13||1/2||101||001||04��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_dept*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --����λ���1/2����λ���롢��ѹ�ȼ��Ͳ�����ѹ�ȼ�����ͳ�� ��ʼ
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
                   and ('41311016130101000 '<>sysdeptcode  --���Ǻӱ�
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --�ӱ���ֻͳ������
                       )
             group by decode(branch_class,10,131, 70,132, 21,133),reactive.dept_code,sort_no,
                      voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize))
  --����λ���1/2����λ���롢��ѹ�ȼ��Ͳ�����ѹ�ȼ�����ͳ�� ����
  select year,user_dept_code,
         id_start+decode(corp_group,'131',0,'132',1,'133',2)*cn_dept*cn_volt*cn_volt_equa+(rn-1)*cn_volt*cn_volt_equa+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(voltage_equalize,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+decode(corp_group,'131',0,'132',1,'133',2)*cn_dept*cn_volt+(rn-1)*cn_volt+
         decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,6 id_level,
         decode(voltage_equalize,
                '0','1000ǧ��','O','��800ǧ��','1','750ǧ��','P','��660ǧ��','2','500ǧ��','Q','��500ǧ��','R','��400ǧ��','S','��400ǧ������','3','330ǧ��','4','220ǧ��','5','110ǧ��','B','66ǧ��','6','35ǧ��','C','20ǧ��','10ǧ��������') item_name,
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

  --BX5 ����λ��𡢵�λ����ѹ�ȼ��������ݣ�id_level=5��
  --�����sort_char��9λ����1~3λ��ʾ��λ��𣬵�4λ��1����5��6λ�ǵ�λ����ţ���7-9��ʾ��ѹ�ȼ���������Դ��BX6���ֲ���ļ�¼��ȡ��sort_char��11λ��
  --�������5�㣬sort_char=9λ��(��λ���||1/2/3||��λ˳���||��ѹ�ȼ�||������ѹ�ȼ�)��1��2��3��4�Σ�����λ���||1/2||��λ˳���||��ѹ�ȼ�=13||1/2/3||101||001��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_dept*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,9),1,3),'131',0,'132',1,'133',2)*cn_dept*cn_volt+
         (substr(substr(sort_char,1,9),5,2)-1)*cn_volt+to_number(substr(substr(sort_char,1,9),8,2)) id,--��ѹ�ȼ�
         id_parent_start+decode(substr(substr(sort_char,1,9),1,3),'131',0,'132',1,'133',2)*cn_dept+
         substr(substr(sort_char,1,9),5,2)-1 parent_id,5 id_level,
         decode(substr(substr(sort_char,1,9),8,2),
                '00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,9) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=11 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,9);

  --BX4 ����λ��𡢵�λ�������ݣ�id_level=4�������sort_char��6λ����1~3λ��ʾ��λ��𣬵�4λ��1����5��6λ�ǵ�λ����š�������Դ��Դ��reactive��
  --�������4�㣬sort_char=6λ��(��λ���||1/2/3||��λ˳���||��ѹ�ȼ�)��1��2��3�Σ�����λ���||1/2/3||��λ˳���=13||1/2/3||101��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_dept;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --����λ��𡢵�λ�������ͳ�� ��ʼ
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
                          sub_dept.dept_name,--ʡ������˾�µĵ�λ������sub_dept�е�dept_name
                          sort_no,e_phaseshiftor,u_phaseshiftor,e_capacitor,u_capacitor,e_reactor,u_reactor,e_other,u_other,e_static,u_static,
                          sysdeptcode sys_dept_code
                   from reactive,sub_dept
                   where tab_year=year and sys_dept_code=sysdeptcode and sub_dept.dept_code=reactive.dept_code and
                         branch_class in (10,70,21) and voltage in ('0','1','2','3','4','5','6','B','C','O','P','Q','R','S')
                         and ('41311016130101000 '<>sysdeptcode    --���Ǻӱ�
                              or
                              exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code) --�ӱ���ֻͳ������
                             )
                  )
             group by corp_group,dept_code,dept_name,sort_no)
  --����λ��𡢵�λ�������ͳ�� ����
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

  --BY5 ����λ���(131/132/133)����ѹ�ȼ���������ѹ�ȼ��������ݣ�id_level=5��
  --�����sort_char��8λ����1~3λ��ʾ��λ��𣬵�4-6��ʾ��ѹ�ȼ�����7��8λ��ʾ������ѹ��������Դ��BX6���ֲ���ļ�¼��ȡsort_char��ǰ3λ||��5λ��
  --�������5�㣬sort_char=8λ,��λ���||1/2/3||��ѹ�ȼ�||������ѹ�ȼ�=13||1/2/3||001||04��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(sort_char,1,3),'131',0,'132',1,'133',2)*cn_volt*cn_volt_equa+substr(substr(sort_char,7,5),2,2)*cn_volt_equa+substr(substr(sort_char,7,5),4,2) id,
         id_parent_start+decode(substr(sort_char,1,3),'131',0,'132',1,'133',2)*cn_volt+substr(substr(sort_char,7,5),2,2) parent_id,5 id_level,
         decode(substr(substr(sort_char,7,5),4,2),
                '00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,3)||substr(sort_char,7,5) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=11 and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,7,5),substr(sort_char,1,3);

  --BY4 ����λ���(131/132/133)����ѹ�ȼ��������ݣ�id_level=4��
  --�����sort_char��6λ����1~3λ��ʾ��λ��𣬵�4-6��ʾ��ѹ�ȼ���������Դ��BY5���ֲ���ļ�¼��ȡsort_char��ǰ6λ��
  --�������4�㣬sort_char=6λ,(��λ���||1/2/3||��ѹ�ȼ�||������ѹ�ȼ�)�ĵ�1��2�Σ�����λ���||1/2/3||��ѹ�ȼ�=13||1/2/3||001��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(substr(sort_char,1,6),1,3),'131',0,'132',1,'133',2)*cn_volt+substr(substr(sort_char,1,6),5,2) id,
         id_parent_start+decode(substr(substr(sort_char,1,6),1,3),'131',0,'132',1,'133',2) parent_id,4 id_level,
         decode(substr(substr(sort_char,1,6),5,2),
                '00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,6) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
     sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=8 and substr(sort_char,1,2)='13' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,6);

  ----BY3 ����131������ʡ������˾->1��ĸ��˾��132������ʡ������˾->2��ȫ���ӹ�˾���عɹ�˾��id_level=3��
  --�����sort_char��3λ��������Դ��BY4���ֲ���ļ�¼��ȡsort_char��ǰ3λ��
  --2014-1-16 ��λ���branch_class=21ʱ��corp_group=133����֡�2��ȫ���ӹ�˾���عɹ�˾��Ϊ��2��ȫ���ӹ�˾���͡�3���عɹ�˾����
  --�������3�㣬sort_char=3λ,(��λ���||1/2/3||��ѹ�ȼ�)�ĵ�1��2�Σ�����λ���||1/2/3=13||1/2/3��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + 3;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code,
         id_start+decode(substr(sort_char,1,3),'131',0,'132',1,'133',2) id,null parent_id,3 id_level,
         decode(substr(sort_char,1,3),'131','1��ĸ��˾', '132','2��ȫ���ӹ�˾','133','3���عɹ�˾') item_name,
         substr(sort_char,1,3) sort_char,
     sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
      sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
     sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
     sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=6 and substr(sort_char,1,2)='13' and substr(sort_char,4,1)='0' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,3);

  --����BY3���ֲ����¼(131������ʡ������˾->1��ĸ��˾��132������ʡ������˾->2��ȫ���ӹ�˾��133������ʡ������˾->3���عɹ�˾)(sort_charΪ3λ�ҵ�1~2λ��13)��parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char = substr(a.sort_char,1,2) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=3 and substr(sort_char,1,2)='13' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --����BX4���ֲ����¼(sort_charΪ6λ�ҵ�1~2λ��13�ҵ�4λ��1)��parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char = substr(a.sort_char,1,3) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=6 and substr(sort_char,1,2)='13' and substr(sort_char,4,1)='1' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --------�ġ�������������µĵ�λ��ϸcorp_group in (23,24,25,26,27)--------
  ----BD ���롰�����������µĵ�λ��ϸ��
  --BD4 ����λ����ѹ�ȼ���������ѹ�ȼ��������ݣ�id_level=4��������Դ��Դ��reactive�������sort_char��9λ����1��2λ��21����3��4λ�ǵ�λ����ţ���5-7λ�ǵ�ѹ�ȼ�����8��9��ʾ������ѹ�ȼ���
  --�������4�㣬sort_char=9λ��2||��λ˳���||��ѹ�ȼ�||������ѹ�ȼ�=2||101||001||04��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_dept*cn_volt*cn_volt_equa;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --����λ���롢��ѹ�ȼ���������ѹ�ȼ�����ͳ�� ��ʼ
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
                   and ('41311016130101000 '<>sysdeptcode  --���Ǻӱ�
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --�ӱ���ֻͳ������
                       )
             group by reactive.dept_code,sort_no,voltage,decode(voltage_equalize,'D','7','E','7','8','7',voltage_equalize))
  --����λ���롢��ѹ�ȼ���������ѹ�ȼ�����ͳ�� ����
  select year,user_dept_code,
         id_start+(rn-1)*cn_volt*cn_volt_equa+decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14)*cn_volt_equa+
         decode(voltage_equalize,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) id,
         id_parent_start+(rn-1)*cn_volt+decode(voltage,'0',0,'O',1,'1',2,'P',3,'2',4,'Q',5,'R',6,'S',7,'3',8,'4',9,'5',10,'B',11,'6',12,'C',13,14) parent_id,4 id_level,
         decode(voltage_equalize,
                '0','1000ǧ��','O','��800ǧ��','1','750ǧ��','P','��660ǧ��','2','500ǧ��','Q','��500ǧ��','R','��400ǧ��','S','��400ǧ������','3','330ǧ��','4','220ǧ��','5','110ǧ��','B','66ǧ��','6','35ǧ��','C','20ǧ��','10ǧ��������') item_name,
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

  --BD3 ����λ����ѹ�ȼ��������ݣ�id_level=3�������sort_char��7λ����1��2λ��21����3��4λ�ǵ�λ����ţ���5-7λ�ǵ�ѹ�ȼ���������Դ��BD4���ֲ���ļ�¼��ȡsort_char��ǰ7λ��
  --�������3�㣬sort_char=7λ��(2||��λ˳���||��ѹ�ȼ�||������ѹ�ȼ�)��1��2��3�Σ���2||��λ˳���||��ѹ�ȼ�=2||101||001��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_dept*cn_volt;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  select year,user_dept_code, id_start+ (substr(substr(sort_char,1,7),3,2)-1)*cn_volt +
         substr(substr(sort_char,1,7),6,2) id,--ȡsort_char�ĵ�7λ����ʾ��ѹ�ȼ�
         id_parent_start+substr(substr(sort_char,1,7),3,2)-1 parent_id,3 id_level,
         decode(substr(substr(sort_char,1,7),6,2),
                '00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
         substr(sort_char,1,7) sort_char,
         sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
         sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
         sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
         sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
  from pro_reactive
  where length(sort_char)=9 and substr(sort_char,1,1)='2' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode
  group by substr(sort_char,1,7);

  --BD2 ����λ�������ݣ�id_level=2�����뵥λ�ڵ㡣�����sort_char��4λ����1��2λ��21����3��4λ�ǵ�λ����š�������Դ��Դ��reactive��
  --�������2�㣬sort_char=4λ��2||��λ˳���=2||101��
  id_start := id_parent_start;
  id_parent_start := id_parent_start + cn_dept;

  insert into pro_reactive(tab_year,dept_code,id,parent_id,id_level,item_name,sort_char,
              sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
              u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
  --����λ�������ͳ�� ��ʼ
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
                   and ('41311016130101000 '<>sysdeptcode  --���Ǻӱ�
                        or
                        exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --�ӱ���ֻͳ������
                       )
             group by reactive.dept_code,area_name,sort_no)
  --����λ�������ͳ�� ����
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

  --����BD2���ֲ���ļ�¼(sort_charΪ4λ��ǰ��λ��'21')��parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char='2' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=4 and substr(sort_char,1,2)='21' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

  --------�塣������˾��������˾���ֲ����²��볬��ѹ��(branch_class=40)��ʡ��������(branch_class=45)��������������ҵ(branch_name)--------
  IF user_dept_code='41211021820000001 ' or user_dept_code='41311026210102900 ' or user_dept_code='41311026220104100 ' or user_dept_code='41311026230103000 ' THEN

     ----1����Գ���ѹ��(branch_class=40)----
     --���밴������ҵ(branch_name)����ͳ�ƣ���ͬ�ڰ���λ�������ͳ�ƣ���sort_char 5λ��������Դ��Դ��reactive��
     --�������3�㣬sort_char=5λ��12||������ҵ˳���=12||101��12��������˾���ֲ�����
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
           and ('41311016130101000 '<>sysdeptcode  --���Ǻӱ�
                or
                exists(select dept_code from sub_dept where manage_property=0 and dept_code=reactive.dept_code)  --�ӱ���ֻͳ������
               )
     group by branch_name;

  --���³���ѹ��,ʡ�������ߵ�parent_id
  update pro_reactive a
  set parent_id=
      (select id from pro_reactive where sort_char='12' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
  where length(sort_char)=5 and substr(sort_char,1,3)='121' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;


  END IF;

  --------�����ӱ���������������������ѹͳ�ơ�--------
  IF user_dept_code='41311016130101000 ' THEN

     --C4 ���밴��/��������λ����ѹ�ȼ��������ݣ�sort_char 6λ ,��һλΪ9
     --�������4�㣬sort_char=6λ��91/92||��λ˳���||��ѹ�ȼ�(1λ)=91/92||101||4��91/92��������/������
     id_start := id_parent_start;
     id_parent_start := id_parent_start+2*cn_dept*cn_volt;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     --����/��������λ����ѹ�ȼ�����ͳ�� ��ʼ
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
     --����/��������λ����ѹ�ȼ�����ͳ�� ����
     select decode(voltage,'0','1000ǧ��','O','��800ǧ��','1','750ǧ��','P','��660ǧ��','2','500ǧ��','Q','��500ǧ��','R','��400ǧ��','S','��400ǧ������','3','330ǧ��','4','220ǧ��','5','110ǧ��','B','66ǧ��','6','35ǧ��','C','20ǧ��','10ǧ��������') item_name,
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

     --CA3 ������/��������λ�����������Դ��Դ��reactive��
     --�������3�㣬sort_char=5λ��91/92||��λ˳���=91/92||101��91/92��������/������
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

     --CB3 ������/��������ѹ�ȼ������������Դ��C4���ֲ���ļ�¼��
     --�������3�㣬sort_char=4λ��91/92||0||��ѹ�ȼ�(1λ)=91/92||0||4��91/92��������/������
     id_start := id_parent_start;
     id_parent_start := id_parent_start+2*cn_volt;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select decode(substr(sort_char,6,2),'00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
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

     --�ϱ���С��,���ϱ����µĵ�ѹͳ��������ͳ��
     --CB2 ������/���������������Դ��CB3���ֲ���ļ�¼��
     --�������2�㣬sort_char=2λ��(91/92||0||��ѹ�ȼ�(1λ)�ĵ�1�Σ���91/92=91/92��91/92��������/������
     id_start := id_parent_start;
     id_parent_start := id_parent_start+2;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select decode(substr(sort_char,1,2),'91','1���ӱ�����С��','2���ӱ�����С��') item_name,
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

     --��ȫʡ�ܼ��°���ѹͳ��,�����ϱ���С���µĵ�ѹͳ�����ݣ�����ѹ�ȼ�����ͳ�ơ�
     --CC2 �����ѹͳ�Ʒ����������Դ��CB3���ֲ���ļ�¼��
     --�������2�㣬sort_char=3λ��9||0||��ѹ�ȼ�(1λ)=9||0||4��9���������ͱ������ϼ���
     id_start := id_parent_start;
     id_parent_start := id_parent_start+cn_volt;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select decode(substr(sort_char,4,2),'00','1000ǧ��','01','��800ǧ��','02','750ǧ��','03','��660ǧ��','04','500ǧ��','05','��500ǧ��','06','��400ǧ��','07','��400ǧ������','08','330ǧ��','09','220ǧ��','10','110ǧ��','11','66ǧ��','12','35ǧ��','13','20ǧ��','10ǧ��������') item_name,
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

     --C1 ȫʡ�ܼ�,��ȫʡ�ܼ��µĵ�ѹͳ��������ͳ�ơ�������Դ��CC2���ֲ���ļ�¼��
     --�������1�㣬sort_char=1λ������9��
     id_start := id_parent_start;
     --id_parent_start := id_parent_start+1;
     insert into pro_reactive(item_name,sort_char,item_code,id,parent_id,id_level,sort_no,sub_sort,dept_code,
                 tab_year,gateway_pos,item_unit,sum_power,e_power,u_power,sum_phase,e_phase,u_phase,sum_capacitor,e_capacitor,
                 u_capacitor,sum_reactor,e_reactor,u_reactor,sum_other,e_other,u_other,sum_static,e_static,u_static,sys_dept_code)
     select 'ȫʡ�ܼ�' item_name,'9' sort_char,null item_code,id_start id,0 parent_id,
            1 id_level,null sort_no,null sub_sort,user_dept_code dept_code,year tab_year,
            null gateway_pos, null item_unit,sum(sum_power),sum(e_power),sum(u_power),sum(sum_phase),sum(e_phase),
            sum(u_phase),sum(sum_capacitor),sum(e_capacitor),sum(u_capacitor),
            sum(sum_reactor),sum(e_reactor),sum(u_reactor),sum(sum_other),
            sum(e_other),sum(u_other),sum(sum_static),sum(e_static),sum(u_static),sysdeptcode
     from pro_reactive
     where length(sort_char)=4 and substr(sort_char,1,1)='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

     --����CA3���ֲ����¼��parent_id
     update pro_reactive a
     set parent_id=
         (select id from pro_reactive where sort_char=substr(a.sort_char,1,2) and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
     where length(sort_char)=5 and substr(sort_char,1,1)='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;

     --����CB2�ϱ���С��ͳ�����ݵ�parent_id
     update pro_reactive a
     set parent_id=
         (select id from pro_reactive where sort_char='9' and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode)
     where (sort_char='91' or sort_char='92') and tab_year=year and dept_code=user_dept_code and sys_dept_code=sysdeptcode;
  END IF;

  --����sort_no
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
