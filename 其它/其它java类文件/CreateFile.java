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

		// 要读取的文件
		String path = "c:/CarInformationManager.java";// 定义文件路径
		// 要写入到的文件
		String toPath = "c:/data.html";
		try {
			// 要写入到文件的String
			String content = readFile(path);
			BufferedWriter bw = new BufferedWriter(new FileWriter(toPath));
			//content = new String(content.getBytes("utf-8"),"iso-8859-1");
			// 添加html中的头和尾
			bw.write(CreateFile.head + content + CreateFile.hail);
			

			// 关闭流
			bw.close();
			System.out.println("文件内容：\n" + content);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * *读取指定的文本文件，并返回内容 * *@parampath文件路径 *@return文件内容
	 * *@throwsIOException如果文件不存在、打开失败或读取失败
	 */
	private static String readFile(String path) throws IOException {
		String content = "";
		BufferedReader reader = null;
		
		// 是否在注释区域内
		boolean flag = false;
		// 得到的注释信息是否已经输出
		boolean flag_out = true;
		// 简介
		String introduction = "";
		// 作者
		String author = "";
		// 输出
		String out = "";
		// 输入
		List<String> inList = new ArrayList<String>();
		// 注释区域内的行数
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
				// 将要进入注释区域
				if(line.startsWith("/**")){
					flag = true;
					h = h+1;
					inList = new ArrayList<String>();
					introduction = "";
					author = "";	
					out = "";

					continue;
				// 将要离开注释区域
				}else if(line.startsWith("*/")){
					flag = false;
					h = h+1;
					h = 0;
					continue;
				}
				
				// 如果在注释区域内
				if(flag){
					flag_out = false;
					h = h+1;
					// 如果是注释区域内的第二行
					if(h==2){
						introduction = line.replace("*", "").replace(" ", "");
					}
					
					// 如果是作者
					if(line.replace("*", "").trim().startsWith("@author")){
						author = line.replace("@author", "").replace(" ", "").replace("*", "");
					}
					
					// 如果是输入
					if(line.replace("*", "").trim().startsWith("@param")){
						inList.add(line.replace("@param", "").replace(" ", "").replace("*", "").replace("	", " "));
					}
					
					// 如果是输出
					if(line.replace("*", "").trim().startsWith("@return")){
						out = line.replace("@return", "").replace("*", "");
					}
				// 如果不在注释区域内
				// 即不以//,@,/*开头   不以*/结尾	不是空行
				// 即方法或类名称
				}else if(introduction.equals("")==false&&line.startsWith("//")==false&&line.startsWith("@")==false&&line.startsWith("/*")==false&&line.endsWith("*/")==false&&line.trim().equals("")==false){
					//如果是类体
					if(line.contains("class")){
						//System.out.println(line);
						flag_out = true;
					//如果是成员体
					}else{
						//如果是成员方法体
						if(line.contains("(")||line.contains(")")||line.contains("{")){
							if(flag_out==false){
								//接口方法
								content = content + new String("<font face='宋体' style='font-weight:bold'>接口方法:</font>".getBytes("utf-8"))+line.replace("{", "")+ "\n"+ "</br>";
								//描述
								content = content + new String("<font face='宋体' style='font-weight:bold'>描述:</font>".getBytes("utf-8"))+introduction+ "\n"+ "</br>";
								//输入
								if(inList.size()!=0){
									content = content + new String("<font face='宋体' style='font-weight:bold'>输入:</font>".getBytes("utf-8"));
									for(String inStr: inList){
										content = content + inStr + new String(";".getBytes("utf-8"));
									}
									content = content + "\n"+ "</br>" ;
								}
								//输出
								content = content + new String("<font face='宋体' style='font-weight:bold'>输出:</font>".getBytes("utf-8"));
								content = content + out.trim() + "</br>" + "</br>"+ "\n"+ "\n"+ "\n"; 
								//修改输出标识
								flag_out = true;
							}
						//如果是成员变量
						}else{
							//修改输出标识
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
