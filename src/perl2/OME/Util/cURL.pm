# OME/Util/cURL.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Ilya Goldberg <igg@nih.gov>  (6/2006)
#
#-------------------------------------------------------------------------------

package OME::Util::cURL;

=head1 NAME

OME::Util::cURL - interface to libcurl using Inline::C

=head1 SYNOPSIS

  use OME::Util::cURL;
  my $curl = OME::Util::cURL->new();
  
  # Upload a file (note that the 'File' key's value stores a path)
  my $response = $curl->POST (
  	'http://localhost/cgi-bin/omeis',{
  	'Method' => 'UploadFile',
  	'File' => $file,
  });
  my $status = curl_status();
  
  # Upload a buffer (note that the 'File' key's value stores a reference to data)
  my $response = $curl->POST (
  	'http://localhost/cgi-bin/omeis',{
  	'Method' => 'UploadFile',
  	'File' => \$data,
  });
  my $status = curl_status();
  
  # GET request
  my $response = $curl->GET ('http://localhost/cgi-bin/omeis');
  # GET request with response sent to a file
  my $response = $curl->GET_file (
  	"http://localhost/cgi-bin/omeis?FileInfo&FileID=$fileID",'filename');
  my $status = curl_status();

=head1 DESCRIPTION

This class provides a Perl interface to the libcurl library.  This class contains
a couple specializations having to do with Files and Pixels in POST requests.
For various reasons, the cached compiled code is stored in /var/tmp/Inline
This directory must exist, and be readable by the proocess invoking OME::Util::cURL.
If the cache is empty, the directory must be writeable also.

=head2 new

  my $curl = OME::Util::cURL->new();

This allocates a curl handle by calling curl_easy_init, and blesses the result into
the OME::Util::cURL class.  The $curl object should be reused for connections because
it will use keep_alive and other schemes to make things fast.  The recommended approach
is to declare the handle as a package global (using 'my', not 'our'), then re-using it
for the life of the package (or script) using a construction like:

  my $curl   # outside of any brackets - outermost scope, package global
  ...        # code, methods, etc go here
  $curl = OME::Util::cURL->new() unless $curl;  # when needing to use $curl


=head2 POST

  my $response = $curl->POST ($url,{ SomeName => 'a value' })

Implements cURL's multi-part/formdata HTTP POST (sometimes referred to as rfc1867-style posts).
The keys of the parameter hash are the form element names, and the values are the corresponding values.

Three keys of the parameter hash (File, Pixels and __file) are treated specially:

  File   => $file_path   # The value is a file path
                         # the file is uploaded to the server
  File   => \$data       # The value is a reference
                         # the data being referenced is uploaded to the server
  # The same applies to the Pixels key.
  __file => $file_path   # The response is saved in the specified file
                         # an empty string is returned by the call

=head2 GET

  my $response = $curl->GET ($url)

Returns the result of the URL request.

=head2 GET_file

  my $response = $curl->GET_file ($url,$file_path)

Returns the result of the URL request in the specified file.

=cut

use strict;
use warnings;

use OME;
our $VERSION = $OME::VERSION;

use Inline (Config => DIRECTORY => '/var/tmp/Inline');
use Inline (
	C => 'DATA', LIBS => ['-lcurl'],
#	CLEAN_AFTER_BUILD => 0,
);


Inline->init;


1;

__DATA__

__C__

#include <curl/curl.h>
#include <curl/easy.h>

static size_t my_curl_write(char *buffer, size_t size,
							size_t nitems, void *response) {
	sv_catpvn((SV *)(response), buffer, nitems);
	return nitems;
}

SV *new(char* class)
{
SV *obj_ref, *obj;
CURL *curl = NULL;


	/* initialize curl */
	curl = curl_easy_init();
	if (! curl)
		croak("Could not initialize cURL");

	curl_easy_setopt(curl, CURLOPT_MUTE, 1);
	
	/* bless it into the class */
	obj_ref = newSV(0);
	sv_setref_pv(obj_ref, class, (void*) curl);
	SvREADONLY_on(obj_ref);

	return (obj_ref);

}


SV *POST (SV *obj, char *url, SV *aref)
{
CURL *curl = (CURL *)( SvIV(SvRV(obj)) );
SV *response=NULL;
struct curl_httppost *post=NULL;
struct curl_httppost *last=NULL;
HV *param=NULL;
I32 retlen=0;
SV  *item=NULL, *uploadRef=NULL;
char *name=NULL, *contents=NULL, *uploadName=NULL, *uploadFile=NULL;
size_t uploadSize;
FILE *outfile=NULL;

	if (! curl)
		croak("Calling POST on an unblessed reference");

	
	/* Check the parameters */
	if (! SvROK(aref) || SvTYPE(SvRV(aref))!= SVt_PVHV)
		croak("aref is not a HASH reference");
	param = (HV*)SvRV(aref);

	/* Iterate over the parameter hash */
	hv_iterinit (param);
	item = hv_iternextsv(param, &name, &retlen);
	while (item) {
		if ( strcmp (name,"File") && strcmp (name,"Pixels") && strcmp (name,"__file") ) {
		/* This is not an upload parameter (File or Pixels)*/
			contents = SvPV_nolen(item);
			curl_formadd(&post, &last,
				CURLFORM_COPYNAME, name,
				CURLFORM_COPYCONTENTS, contents, CURLFORM_END);
		} else if (! strcmp (name,"__file") ) {
			outfile = fopen (SvPV_nolen(item),"w+");
			if (!outfile) croak("could not open specified output file");
		} else if ( SvROK(item) ) {
		/* File or Pixels with a reference means we upload the buffer refered to */
			uploadName = name;
			uploadRef = (SV*) SvRV(item);
		} else if ( SvPOK (item) ) {
		/* File or Pixels with a scalar means we upload the file */
			uploadName = name;
			uploadFile = SvPV_nolen(item);
		}
		/* get the next parameter */
		item = hv_iternextsv(param, &name, &retlen);
	}

	/* Add the file upload at the end */
	if (uploadFile) {
		curl_formadd(&post, &last,
			CURLFORM_COPYNAME, uploadName,
			CURLFORM_FILE, uploadFile, CURLFORM_END);
	} else if (uploadRef) {
	/* upload buffer */
		curl_formadd(&post, &last,
			CURLFORM_COPYNAME, uploadName,
			CURLFORM_BUFFER, "data",
			CURLFORM_BUFFERPTR, SvPVX(uploadRef),
			CURLFORM_BUFFERLENGTH, SvLEN (uploadRef),
			CURLFORM_END);

	}

	/* Set the curl form info */
	curl_easy_setopt(curl, CURLOPT_URL, url);
	curl_easy_setopt(curl, CURLOPT_HTTPPOST, post);

	/* Make a new SV for our response */
	response =  newSVpvf("");
	
	if (! outfile) {
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_curl_write);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, response);
	} else {
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, outfile);
	}
	curl_easy_perform(curl);

	/* free the post data */
	curl_formfree(post);
	if (outfile) {
		fclose (outfile);
		outfile = NULL;
	}
	return (response);
}



SV *GET (SV *obj, char *url)
{
CURL *curl = (CURL *)( SvIV(SvRV(obj)) );
SV *response=NULL;

	if (! curl)
		croak("Calling GET on an unblessed reference");

	/* Set the curl options */
	curl_easy_setopt(curl, CURLOPT_URL, url);
	curl_easy_setopt(curl, CURLOPT_HTTPGET, 1);

	/* Make a new SV for our response */
	response =  newSVpvf("");
	
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_curl_write);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, response);

	curl_easy_perform(curl);

	return (response);
}


void GET_file (SV *obj, char *url, char *file)
{
CURL *curl = (CURL *)( SvIV(SvRV(obj)) );
SV *response=NULL;
FILE *outfile=NULL;


	if (! curl)
		croak("Calling GET_file on an unblessed reference");

	if ( file && strlen (file) ) {
		outfile = fopen (file,"w+");
		if (!outfile) croak("could not open specified output file");
	}

	/* Set the curl options */
	curl_easy_setopt(curl, CURLOPT_URL, url);
	curl_easy_setopt(curl, CURLOPT_HTTPGET, 1);

	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, outfile);

	curl_easy_perform(curl);

	/* cleanup */
	fclose (outfile);
	outfile = NULL;
}

SV *status (SV *obj)
{
CURL *curl = (CURL *)( SvIV(SvRV(obj)) );
long response_code;

	if (! curl)
		croak("Calling status on an unblessed reference");

	curl_easy_getinfo (curl,CURLINFO_HTTP_CODE,&response_code);
	return ( newSViv(response_code) );
}

void DESTROY (SV *obj)
{
CURL *curl = (CURL *)( SvIV(SvRV(obj)) );
	if (curl) {
		curl_easy_cleanup(curl);
	}
}


