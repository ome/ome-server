/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */




/*------------------------------------------------------------------------------
 *
 * Written by:	Chris Allan <callan@blackcat.ca>   03/2004
 * 
 *------------------------------------------------------------------------------
 */

#ifndef __OME_AUTH_H__
#define __OME_AUTH_H__

/********
********* DEFINES
********/

/* ____________
 * HTTP request
 *
 * Stores all the goodies we need or may need for an HTTP payload.
 *
 */

#define RF_HOST "localhost"     /* Remote framework host (host.domain.gtld) */
#define RF_PORT 8002            /* Remote framework port */

#define SOCK_BUF_LEN 1024       /* Read length for each recv */

#define MAX_FIELD_LEN 256       /* Should be more than enough,
								   if it's more it's corrupt */
#define MAX_CONTENT_TYPE_LEN 8  /* Care less about anything more than "text/xml" */


typedef struct {
	unsigned char *http_payload;
	unsigned char *http_content;
	unsigned char content_type[MAX_CONTENT_TYPE_LEN + 1];
	unsigned int content_len;
} http_request;

/* ____________
 * Auth context
 *
 * I'm leaving the cgi_path in for when some brave soul wants to implement URI
 * parsing. Otherwise, all it does it store the socket.
 *
 */

typedef struct {
	int rf_sock;              /* Remote framework socket */
	unsigned char *cgi_path;  /* POST path to the RF CGI */
} auth_ctx;

/********
********* PROTOTYPES
********/

auth_ctx *
auth_ctx_new (void);

void
auth_ctx_free (auth_ctx *ctx);

unsigned char *
user_data_auth (auth_ctx *ctx, unsigned char *username, unsigned char *password);

#endif /* __OME_AUTH_H__ */
