#include <stdio.h>
#include "../auth.h"

/* 
 * Compile arguments:
 * gcc `xml2-config --cflags --libs` -o authtest2 authtest2.c ../auth.o
 *
 */

int main (int argc, char *argv[])
{
	auth_ctx *ctx;

	if (argc < 2) {
		printf("Usage: %s <sid>\n", argv[0]);
		return -1;
	}

	ctx = auth_ctx_new();

	if ((sid_auth(ctx, argv[1]))) {
		printf("Authentication successful: %s\n", argv[1]);
		auth_ctx_free(ctx);
		return 0;
	}
	
	printf("Authentication failed: %s\n", argv[1]);

	auth_ctx_free(ctx);

	return -1;
}
