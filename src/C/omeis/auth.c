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
	
/* STDLIB */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>

/* LIBXML2 */
#include <libxml/parser.h>
#include <libxml/tree.h>

/* INTERNAL */
#include "auth.h"

const char * user_data_xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodCall><methodName>createSession</methodName><params><param><value><string></string></value></param><param><value><string></string></value></param></params></methodCall>";

const char * sid_xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodCall><methodName>authenticateSession</methodName><params><param><value><string></string></value></param></params></methodCall>";

/* _______
 * getline
 *
 * Specifically designed line retrieval function for HTTP fields.
 *
 * XXX Note that this returns *READ* length not actual line length. *DO NOT*
 * use the return value for memory allocation, you will be sorry.
 *
 */
static int
getline (char *line, int n, char *buf)
{
	register int i = 0;
	char *pos, *prev;

	do {
		pos  = buf + i;
		prev = pos - 1;

		if (*pos == '\n')
			break;

		*(line + i) = *pos;
		++i;
	} while (i < n);

	if (i == n)
		return -1;           /* Corrupt fields too long, this is *very* nasty */
	else if (*prev == '\r' && i == 1)
		return 0;            /* Empty line with CR */
	else if (*prev == '\r')
		line[i - 1] = '\0';  /* Strip CR but keep length */
	else
		line[i] = '\0';      /* NULL terminate network data */

	return i;
}

/* __________
 * set_params
 *
 * Finds and sets the parameters of an XML-RPC, XML document according to the
 * length and parameter list specified.
 *
 * The schema is:
 *
 * <params>
 *   <param>
 *     <value>
 *       <type>
 *       </type>
 * 	   </value>
 *   <param>
 *   ...
 * </params>
 *
 * If type is missing then then it is string. Exhaustive list of possible types
 * available at http://www.xml-rpc.org/
 *
 */
static int
set_params (xmlNodePtr root, unsigned char *plist[], int len)
{
	xmlNodePtr param = NULL, value, string;
	int i;
	
	/* Find "param" node */
	for ( ; root != NULL ; root = root->next)
		if (!xmlStrcmp(root->name, (const xmlChar *) "params"))
			param = root->xmlChildrenNode; 

	/* Fail if we can't find it */
	if (param == NULL) {
		fprintf(stderr, \
				"Serious error finding 'params' node in XML file.\n");
		return -1;
	}
	
	for (i = 0; i < len; i++) {
		if ((value = param->xmlChildrenNode) == NULL) {
			fprintf(stderr, \
					"Serious error finding 'value' node in XML file.\n");
			return -1;
		}
		else if ((string = value->xmlChildrenNode))
			xmlNodeSetContent(string, (const xmlChar *) plist[i]);
		else
			xmlNodeSetContent(value, (const xmlChar *) plist[i]);

		param = param->next;
	}

	return 1;
}

/*
 * parse_xmlrpc_xml
 *
 * Parses a RAW XML-RPC XML file from memory and returns a libxml2 document.
 * Also checks the root node against that which has been passed to it for an
 * extra bit of sanity.
 *
 * XXX Note that the caller is responsible for free'ing the return value.
 *     xmlFreeDoc(doc);
 *
 */
static xmlDocPtr
parse_xmlrpc_xml (const unsigned char *xml_in, const unsigned char *root)
{
	xmlDocPtr doc;
	xmlNodePtr cur;

	if ((doc = xmlParseMemory (xml_in, strlen(xml_in))) == NULL) {
        fprintf(stderr, "failed to parse the including file\n");
		return NULL;
	}
	
	cur = xmlDocGetRootElement(doc);
	
	if (cur == NULL) {
		fprintf(stderr, "empty document\n");
		xmlFreeDoc(doc);
		return NULL;
	}
	
	if (xmlStrcmp(cur->name, (const xmlChar *) root)) {
		fprintf(stderr,"document of the wrong type, root node != %s", root);
		xmlFreeDoc(doc);
		return NULL;
	}

	return doc;
}

/* _________________
 * user_data_get_xml
 *
 * Sets the username and password of a "user_data" XML-RPC query and then
 * returns the contents of the updated XML file.
 *
 * XXX Note that the caller is responsible for free'ing the return value.
 *
 */
static unsigned char *
user_data_get_xml (const unsigned char *xml_in,
                   unsigned char *username,
                   unsigned char *password)
{
	xmlDocPtr doc;
	xmlNodePtr cur;
	unsigned char *plist[2];
	xmlChar *xml_out;
	int len;

	/* Get our parameter list ready */
	plist[0] = username;
	plist[1] = password;

	if ((doc = parse_xmlrpc_xml(xml_in, "methodCall")) == NULL)
		return NULL;  /* the bogus document will already have been freed */

	cur = xmlDocGetRootElement(doc);  /* Safe, already been verified */
	
	/* Set parameter list from root node */
	set_params(cur->xmlChildrenNode, plist, 2);

	xmlDocDumpMemory(doc, &xml_out, &len);  /* Yes, len is unused */
	xmlFreeDoc(doc);

	return (unsigned char *) xml_out;
}

/* ___________
 * sid_get_xml
 *
 * Sets the SID of a "sid" XML-RPC query and then returns the contents of the
 * updated XML file.
 *
 * XXX Note that the caller is responsible for free'ing the return value.
 *
 */
static unsigned char *
sid_get_xml (const unsigned char *xml_in, unsigned char *sid)
{
	xmlDocPtr doc;
	xmlNodePtr cur;
	unsigned char *plist[1];
	xmlChar *xml_out;
	int len;

	/* Get our parameter list ready */
	plist[0] = sid;

	if ((doc = parse_xmlrpc_xml(xml_in, "methodCall")) == NULL)
		return NULL;  /* the bogus document will already have been freed */

	cur = xmlDocGetRootElement(doc);  /* Safe, already been verified */
	
	/* Set parameter list from root node */
	set_params(cur->xmlChildrenNode, plist, 1);

	xmlDocDumpMemory(doc, &xml_out, &len);  /* Yes, len is unused */
	xmlFreeDoc(doc);

	return (unsigned char *) xml_out;
}

/* ___________________
 * user_data_parse_xml
 *
 * Parses the XML retrieved from a "user_data" XML-RPC authentication query and
 * returns the SID retrieved.
 *
 * XXX Note that the caller is responsible for free'ing the return value.
 *
 */
static unsigned char *
user_data_parse_xml (const unsigned char *xml)
{
	xmlDocPtr doc;
	xmlNodePtr cur;
	xmlChar *key = NULL;

	if ((doc = parse_xmlrpc_xml(xml, "methodResponse")) == NULL)
		return NULL;  /* the bogus document will already have been freed */

	cur = xmlDocGetRootElement(doc);
	
	for (cur = cur->xmlChildrenNode ; cur != NULL ; cur = cur->next)
		if (!xmlStrcmp(cur->name, (const xmlChar *) "params")) {
			cur = cur->xmlChildrenNode;
			key = xmlNodeGetContent(cur);

			break;
		}

	xmlFreeDoc(doc);

	return (unsigned char *) key;
}

/* _____________
 * sid_parse_xml
 *
 * Parses the XML retrieved from a "sid" XML-RPC authentication query and
 * returns either 0 (authentication failed) or 1 (authentication successful).
 *
 */
static int
sid_parse_xml (const unsigned char *xml)
{
	xmlDocPtr doc;
	xmlNodePtr cur;
	xmlChar *key = NULL;

	if ((doc = parse_xmlrpc_xml(xml, "methodResponse")) == NULL)
		return -1;  /* the bogus document will already have been freed */

	cur = xmlDocGetRootElement(doc);

	for (cur = cur->xmlChildrenNode ; cur != NULL ; cur = cur->next)
		if (!xmlStrcmp(cur->name, (const xmlChar *) "params")) {
			cur = cur->xmlChildrenNode;
			key = xmlNodeGetContent(cur);

			break;
		}

	if (atoi(key) == 1) {
		xmlFree(key);
		return 1;
	} else {
		xmlFree(key);
		return 0;
	}
}


/* __________________
 * parse_http_request
 *
 * Parses HTTP POST/GET headers retrieving the contents of an http_request
 * structure.
 *
 */
static int
parse_http_request (unsigned char *payload, http_request *request)
{
	unsigned char *http_header, *http_content;
	unsigned char *pos;
	unsigned char field[MAX_FIELD_LEN + 1];
	unsigned char content_type[MAX_CONTENT_TYPE_LEN + 1];
	unsigned int content_len = 0;
	int len;

	http_header = payload;

	while ((len = getline(field, MAX_FIELD_LEN, http_header)) > 0) {
		/* FIXME These really should be case insensitive checks */
		if (strstr(field, "Content-Length")) {
			pos = strstr(field, ":");
			while (isspace(*(++pos)));  /* Iterate over spaces */
			content_len = atoi(pos);
		} else if (strstr(field, "Content-Type")) {
			pos = strstr(field, ":");
			while (isspace(*(++pos)));  /* Iterate over spaces */
			strncpy(content_type, pos, MAX_CONTENT_TYPE_LEN);
			content_type[MAX_CONTENT_TYPE_LEN] = '\0';  /* NULL terminte */
		}

		http_header += len + 1;
	}

	if (len < 0) {
		fprintf(stderr, "Problems parsing HTTP header.\n");
		return -1;
	}

	while (*(++http_header) != '\n');  /* Seek to next LF */
	http_content = http_header + 1;    /* Jump to the first character of the content */

	request->http_payload = payload;
	request->http_content = http_content;

	if (content_len != strlen(http_content)) {
		fprintf(stderr, "Real (%d) and supplied (%d) content lengths differ.", \
				(int) strlen(http_content), content_len);
		return -1;
	}
	
	request->content_len = content_len;
	strcpy(request->content_type, content_type);

	return 1;
}


/* ____________
 * do_http_post
 *
 * Performs the actual action of an HTTP post. This is where select() calls
 * should be made in the near future to avoid deadlocks.
 *
 */
static unsigned char *
do_http_post (auth_ctx *ctx, unsigned char *post_data, int post_len)
{
	unsigned char buf[SOCK_BUF_LEN];
	unsigned char *payload = NULL;
	int payload_len = 0;
	int sock;
	size_t rlen;

	sock = ctx->rf_sock;

	send(sock, post_data, post_len, 0);

	do {
		if ((rlen = recv(sock, buf, SOCK_BUF_LEN, 0)) > 0) {
			payload = realloc(payload, payload_len + rlen + 1);
			strncpy(payload + payload_len, buf, rlen);
			payload_len += rlen;
		}
	} while (rlen != 0);

	payload[payload_len] = '\0';  /* Null terminate network data */

	return payload;
}

/* ____________
 * auth_ctx_new
 *
 * Makes a new auth context logging in using the RF_* defines. This would be a
 * good place to hide URI parsing when/if someone ends up implementing it.
 *
 */
auth_ctx *
auth_ctx_new (void)
{
	auth_ctx *ctx;
	int rf_sock;
	struct sockaddr_in rf_sock_in;
	struct hostent *rf_hostent;

	ctx = (auth_ctx *) calloc(1, sizeof(auth_ctx));

	if ((rf_hostent = gethostbyname(RF_HOST)) == NULL) {
		printf("Couldn't resolve %s!\n", RF_HOST);
		exit(-1);
	}

	if ((rf_sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) == -1) {
		perror("Error during socket initialization");
		exit(-1);
	}

	rf_sock_in.sin_addr = *((struct in_addr *)rf_hostent->h_addr);
	rf_sock_in.sin_port = htons(RF_PORT);
	rf_sock_in.sin_family = AF_INET;

	if (connect(rf_sock, (struct sockaddr *) &rf_sock_in, sizeof(struct sockaddr)) == -1) {
		perror("Error connecting to remote framework");
		exit(-1);
	}

	ctx->rf_sock = rf_sock;

	return ctx;
}

/* _____________
 * auth_ctx_free
 *
 * Frees an auth content created with auth_ctx_new.
 *
 */
void
auth_ctx_free (auth_ctx *ctx)
{
	close(ctx->rf_sock);

	free(ctx);
}

/* ______________
 * user_data_auth
 *
 * The interface to "user_data" authentication, takes a username and password,
 * puts them through their paces and returns a valid SID or a NULL pointer on 
 * error.
 *
 */
unsigned char *
user_data_auth (auth_ctx *ctx, unsigned char *username, unsigned char *password)
{
	unsigned char *post_xml, *post_data, content_len[23], *header;
	int post_data_len, post_xml_len, header_len;
	unsigned char *http_payload = NULL;
	unsigned char *sid = NULL;
	http_request r;

	post_xml     = user_data_get_xml(user_data_xml, username, password);
	post_xml_len = strlen(post_xml);
	
	assert(post_xml_len < 1024);

	header       = "POST / HTTP/1.0\n";
	header_len   = strlen(header);
	header_len  += sprintf(content_len, "Content-Length: %d\n\n", post_xml_len);

	post_data     = malloc(header_len + post_xml_len + 2);  /* The 2 is LF and \0 */
	post_data_len = sprintf(post_data, "%s%s%s", header, content_len, post_xml);
	
	free(post_xml);

	http_payload = do_http_post(ctx, post_data, post_data_len);

	free(post_data);
	
	if (parse_http_request(http_payload, &r) < 0)
		return NULL;

	if ((sid = user_data_parse_xml(r.http_content)) == NULL)
		return NULL;

	free(http_payload);

	return sid;
}

/* ________
 * sid_auth
 *
 * The interface to "sid" authentication, takes a sid and validates it against
 * the remote framework; returns 1 on success, 0 on failure and < 0 on error.
 *
 */

int
sid_auth (auth_ctx *ctx, unsigned char *sid)
{
	unsigned char *post_xml, *post_data, content_len[23], *header;
	int post_data_len, post_xml_len, header_len, retval;
	unsigned char *http_payload = NULL;
	http_request r;

	post_xml     = sid_get_xml(sid_xml, sid);
	post_xml_len = strlen(post_xml);

	assert(post_xml_len < 1024);

	header       = "POST / HTTP/1.0\n";
	header_len   = strlen(header);
	header_len  += sprintf(content_len, "Content-Length: %d\n\n", post_xml_len);

	post_data     = malloc(header_len + post_xml_len + 2);  /* The 2 is LF and \0 */
	post_data_len = sprintf(post_data, "%s%s%s", header, content_len, post_xml);
	
	free(post_xml);
	
	http_payload = do_http_post(ctx, post_data, post_data_len);

	free(post_data);
	
	if (parse_http_request(http_payload, &r) < 0)
		return -1;

	retval = sid_parse_xml(r.http_content);

	free(http_payload);

	return retval ? 1 : 0;
}
