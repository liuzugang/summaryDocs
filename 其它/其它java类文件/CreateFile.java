package control.word;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class CreateFile {

	public static String head = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"
			+ "<html>"
			+ "<head>"
			+ "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">"
			+ "</head>" + "<body>";

	public static String hail = "</body> </html>";

	public static void main(String[] args) {

		// Ҫ��ȡ���ļ�
		String path = "c:/CarInformationManager.java";// �����ļ�·��
		// Ҫд�뵽���ļ�
		String toPath = "c:/data.html";
		try {
			// Ҫд�뵽�ļ���String
			String content = readFile(path);
			BufferedWriter bw = new BufferedWriter(new FileWriter(toPath));
			//content = new String(content.getBytes("utf-8"),"iso-8859-1");
			// ���html�е�ͷ��β
			bw.write(CreateFile.head + content + CreateFile.hail);
			

			// �ر���
			bw.close();
			System.out.println("�ļ����ݣ�\n" + content);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * *��ȡָ�����ı��ļ������������� * *@parampath�ļ�·�� *@return�ļ�����
	 * *@throwsIOException����ļ������ڡ���ʧ�ܻ��ȡʧ��
	 */
	private static String readFile(String path) throws IOException {
		String content = "";
		BufferedReader reader = null;
		
		// �Ƿ���ע��������
		boolean flag = false;
		// �õ���ע����Ϣ�Ƿ��Ѿ����
		boolean flag_out = true;
		// ���
		String introduction = "";
		// ����
		String author = "";
		// ���
		String out = "";
		// ����
		List<String> inList = new ArrayList<String>();
		// ע�������ڵ�����
		int h = 0;
		
		try {
			reader = new BufferedReader(new FileReader(path));
			String line;
			while ((line = reader.readLine()) != null) {
				// iso-8859-1
				// utf-8
				// gbk
				// gb2312
				line = new String(line.trim().getBytes("utf-8"),"utf-8");
				//System.out.println(line);
				// ��Ҫ����ע������
				if(line.startsWith("/**")){
					flag = true;
					h = h+1;
					inList = new ArrayList<String>();
					introduction = "";
					author = "";	
					out = "";

					continue;
				// ��Ҫ�뿪ע������
				}else if(line.startsWith("*/")){
					flag = false;
					h = h+1;
					h = 0;
					continue;
				}
				
				// �����ע��������
				if(flag){
					flag_out = false;
					h = h+1;
					// �����ע�������ڵĵڶ���
					if(h==2){
						introduction = line.replace("*", "").replace(" ", "");
					}
					
					// ���������
					if(line.replace("*", "").trim().startsWith("@author")){
						author = line.replace("@author", "").replace(" ", "").replace("*", "");
					}
					
					// ���������
					if(line.replace("*", "").trim().startsWith("@param")){
						inList.add(line.replace("@param", "").replace(" ", "").replace("*", "").replace("	", " "));
					}
					
					// ��������
					if(line.replace("*", "").trim().startsWith("@return")){
						out = line.replace("@return", "").replace("*", "");
					}
				// �������ע��������
				// ������//,@,/*��ͷ   ����*/��β	���ǿ���
				// ��������������
				}else if(introduction.equals("")==false&&line.startsWith("//")==false&&line.startsWith("@")==false&&line.startsWith("/*")==false&&line.endsWith("*/")==false&&line.trim().equals("")==false){
					//���������
					if(line.contains("class")){
						//System.out.println(line);
						flag_out = true;
					//����ǳ�Ա��
					}else{
						//����ǳ�Ա������
						if(line.contains("(")||line.contains(")")||line.contains("{")){
							if(flag_out==false){
								//�ӿڷ���
								content = content + new String("<font face='����' style='font-weight:bold'>�ӿڷ���:</font>".getBytes("utf-8"))+line.replace("{", "")+ "\n"+ "</br>";
								//����
								content = content + new String("<font face='����' style='font-weight:bold'>����:</font>".getBytes("utf-8"))+introduction+ "\n"+ "</br>";
								//����
								if(inList.size()!=0){
									content = content + new String("<font face='����' style='font-weight:bold'>����:</font>".getBytes("utf-8"));
									for(String inStr: inList){
										content = content + inStr + new String(";".getBytes("utf-8"));
									}
									content = content + "\n"+ "</br>" ;
								}
								//���
								content = content + new String("<font face='����' style='font-weight:bold'>���:</font>".getBytes("utf-8"));
								content = content + out.trim() + "</br>" + "</br>"+ "\n"+ "\n"+ "\n"; 
								//�޸������ʶ
								flag_out = true;
							}
						//����ǳ�Ա����
						}else{
							//�޸������ʶ
							flag_out = true;
						}
					}
				}
				// content += line + "\n";
			}
		} finally {
			if (reader != null) {
				reader.close();
			}
		}
		return content;
	}
}
