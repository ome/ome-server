#include <stdio.h>
#include "../auth.h"

/* 
 * Compile arguments:
 * gcc `xml2-config --cflags --libs` -o authtest authtest.c ../auth.o
 *
 */

int main (int argc, char *argv[])
{
	auth_ctx *ctx;
	unsigned char *sid;

	if (argc < 3) {
		printf("Usage: %s <username> <password>\n", argv[0]);
		return -1;
	}

	ctx = auth_ctx_new();

	if ((sid = user_data_auth(ctx, argv[1], argv[2])) == NULL) {
		printf("Authentication failed.\n");
		auth_ctx_free(ctx);
		return -1;
	}

	printf("Authentication successful: %s\n", sid);

	auth_ctx_free(ctx);

	return 0;
}
