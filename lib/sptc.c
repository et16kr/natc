#include <stdio.h>

void main(int argc, char** argv)
{
	FILE* fp;
	FILE* new_fp;
	char buffer[1024];
	char* t_buffer;
	char* rtn_str;
	char file_name[30];
	int file_num;

	file_num = 0;

	if (argc < 4)
		return;
	new_fp = NULL;
	fp = fopen(argv[1],"r");
	if (fp == NULL)
		return;

	rtn_str = fgets(buffer, 1024, fp);
	
	while (rtn_str != NULL)
	{
		if (strncmp(buffer, "--!!!", 5)==0)
		{
			file_num++;
			if (new_fp != NULL)
				fclose(new_fp);
			sprintf(file_name,"%s/%s%012d.sql", argv[2], argv[3],file_num);
			//printf(">>>> %s\n", file_name);
			//fflush(stdout);
			t_buffer= &buffer[5];
			printf("%s\t	%s", file_name, t_buffer);
			new_fp = fopen(file_name, "w");
		}
		else
		{
			fprintf(new_fp, "%s", buffer);
			//printf("%s", buffer);
		}
		rtn_str = fgets(buffer, 1024, fp);
	}
}
