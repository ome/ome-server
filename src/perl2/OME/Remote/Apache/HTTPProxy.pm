# ======================================================================
# 
# This is a semi-heavily modified version of the SOAP::Lite (version 0.55)
# XMLRPC::Transport::HTTP::Apache module. As this is purely a proxy class
# which modifies the symbol table, all that has been done is to fit the module
# into the OME remote framework OME::Remote::Apache* set of classes.
# 
# -Chris Allan <callan@blackcat.ca>
#
# ** Original Copyright **
#
# Copyright (C) 2000-2001 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# ======================================================================

package OME::Remote::Apache::HTTPProxy;
                                                                                
use base qw(OME::Remote::Apache::Transport);
                                                                                
sub initialize; *initialize = \&XMLRPC::Server::initialize;
sub make_fault; *make_fault = \&XMLRPC::Transport::HTTP::CGI::make_fault;
sub make_response; *make_response = \&XMLRPC::Transport::HTTP::CGI::make_response;
                                                                                
# ======================================================================

1;
