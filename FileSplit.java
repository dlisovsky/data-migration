/* package whatever; // don't place package name! */

import java.util.*;
import java.lang.*;
import java.io.*;

/* Name of the class has to be "Main" only if the class is public. */
class FileSplit
{
	public static void main (String[] args) throws java.lang.Exception
	{
		Scanner sc = new Scanner(System.in);
		System.out.println("Enter count of parts:");
		int count = sc.nextInt();

		System.out.println("Enter source file name:");
		String fileFullName= sc.next();
		String fileName = fileFullName.substring(0, fileFullName.lastIndexOf("."));
		File f=new File(fileFullName);
		try(FileReader reader = new FileReader(f))
		{
			char[] buffer = new char[(int)f.length()];
		    // считаем файл полностью
		    reader.read(buffer);
			String[] inStrAr = new String(buffer).split("\r\n");
	
			String header = inStrAr[0];
			
			int countLines = inStrAr.length / count + 1;

			int i = 0;
			int fileNum = 1;
			String text = "";
			for (String str : inStrAr) {
				
				if (i < countLines) {
					text += str + "\r\n";
					i++;
				} else {
					text += str + "\r\n";
					if (fileNum != 1) {
						text = header + "\r\n" + text;
					}
					
					File newFile = new File(fileName+"_parts\\"+fileName+"_" + fileNum + ".txt");
					File directory = new File(newFile.getParentFile().getAbsolutePath());
					if (!directory.exists()) directory.mkdirs();
					if (newFile.createNewFile()) {
						System.out.println("New file "+fileName+"_" + fileNum + ".txt created.");
					} else {
						System.out.println("File "+fileName+"_" + fileNum + ".txt exists.");
					}
					try(FileWriter writer = new FileWriter(newFile, false))
			        {
			           // запись всей строки
			            writer.write(text);
			            writer.flush();
						text = "";
			        }
			        catch(IOException ex){
			            System.out.println(ex.getMessage());
			        } 				
					fileNum++;	
					i = 0;
				}
			}
				if (text != ""){

					if (fileNum != 1) {
						text = header + "\r\n" + text;
					}
					
					File newFile = new File(fileName+"_parts\\"+fileName+"_" + fileNum + ".txt");
					if (newFile.createNewFile()) {
						System.out.println("New file "+fileName+"_" + fileNum + ".txt created.");
					} else {
						System.out.println("File "+fileName+"_" + fileNum + ".txt exists.");
					}
					try(FileWriter writer = new FileWriter(newFile, false))
			        {
			           // запись всей строки
			            writer.write(text);
			            writer.flush();
						text = "";
			        }
			        catch(IOException ex){
			            System.out.println(ex.getMessage());
			        } 		
				}					
		}
		catch(IOException ex){
		    System.out.println(ex.getMessage());
		}
	}
}