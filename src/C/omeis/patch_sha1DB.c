#include "Pixels.h"
#include "sha1DB.h"
#include "digest.h"

/*
	Under certain conditions, pixels were deleted but they still
	are referenced by their SHA1 in the DB.
	
	This program deletes the SHA1 reference (modify line 21
	and recompile).
*/
int main (void)

{
	OID ID=0;
	u_int8_t sha1[20];
	char sha1_str[40];
	
	sprintf(sha1_str,"b587b611b4d781e7e90723ffe5acb877d0ea7687");
	convert_md(sha1_str, sha1);
	ID = sha1DB_get("Pixels/sha1DB.idx", sha1);
	
	if (!ID) {
		printf ("No Pixels ID with SHA1 %s\n", sha1_str);
		return;
	}
	sha1DB_del("Pixels/sha1DB.idx", sha1);
	
	return 1;
}