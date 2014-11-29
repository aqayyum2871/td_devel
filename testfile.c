#include <stdio.h>
#include <string.h>

#pragma pack(1)
struct rec
	{
		unsigned short len;
		unsigned char nuller;
		unsigned short lenf1;
		char f1[10];
		unsigned short lenf2;
		char f2[5];
		unsigned short lenf3;
		char f3[8];
		unsigned short lenf4;
		char f4[32];
	};
#pragma pack()

int main(void) {

	FILE *ptr_myfile;
	struct rec my_record;
	int i;
	char text[100] = "AbCdEfGhIjKlMnOpQrStUvWxYz0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ";

	ptr_myfile=fopen("test.bin","w");
	
	if (!ptr_myfile) {
			printf("Unable to open file!");
			return(1);
	}

	my_record.nuller = 0x00;
	for (i = 0; i < sizeof(my_record.f1) -1; i++) {
		my_record.f1[i] = text[i];
	}
	my_record.f1[sizeof(my_record.f1)-1] = 0x00;
	my_record.lenf1 = sizeof(my_record.f1);
	for (i = 0; i < sizeof(my_record.f2) -1; i++) {
		my_record.f2[i] = text[i];
	}
	my_record.f2[sizeof(my_record.f2)-1] = 0x00;
	my_record.lenf2 = sizeof(my_record.f2);
	for (i = 0; i < sizeof(my_record.f3) -1; i++) {
		my_record.f3[i] = text[i];
	}
	my_record.f3[sizeof(my_record.f3)-1] = 0x00;
	my_record.lenf3 = sizeof(my_record.f3);
	for (i = 0; i < sizeof(my_record.f4) -1; i++) {
		my_record.f4[i] = text[i];
	}
	my_record.f4[sizeof(my_record.f4)-1] = 0x00;
	my_record.lenf4 = sizeof(my_record.f4);
	my_record.len = my_record.lenf1 + my_record.lenf2 + my_record.lenf3 + my_record.lenf4 + 9;
	//my_record.len = my_record.lenf1 + my_record.lenf2 + my_record.lenf3 + my_record.lenf4;

	fwrite(&my_record, sizeof(struct rec), 1, ptr_myfile);

	fclose(ptr_myfile);

	return (0);
}
