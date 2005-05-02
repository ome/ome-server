# OME/Remote/Facades/XMLUtils.pm

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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Remote::Facades::XMLUtils;
use OME;
use strict;
our $VERSION = $OME::VERSION;

use OME::Session;


=head1 NAME

OME::Remote::Facades::XMLUtils 
     utiliites for XML construction.

=head1 DESCRIPTION

Custom construction of XML-RPC construction can benefit from some
    abstraction. This file holds commonly-used utilities that would
    otherwise be repeated in the facades.

    Note that abstraction should probably be used sparingly here, as
    we don't want to undo all of the benefits of hand-coding.
=cut


=head2 getSTXml

We assume that we have a reference to a has with id and name
    fields. Create the appropriate XML-RPC for the ST, 
    returning a null string -
    $OME::Remote::SerializerXMLRPC::NULL_STRING
    if no st is found
=cut
# build xml for an st
	# st xml is 
	#	<struct>
	#  <member>
	#    <name>id</name>
	#	<value>
	#    <int>46</int>
	# 	</value>
	# </member>
	# <member>
	#<name>name</name>
	#<value>
	#<string>StackSigma</string>
	#</value>
	# </member>
	# </struct>
         # or null string if not defined. 

sub getSTXml {
    my $st = shift;
    
    my $xml;
    if (defined($st)) {
	$xml = "<struct><member><name>id</name><value><int>" . $st->{'id'}. 	     
	    "</int></value></member>";
	$xml = $xml . "<member><name>name</name><value>" . $st->{'name'}. 
	    "</value></member></struct>";
    }
   else {
       $xml = "<string>$OME::Remote::SerializerXMLRPC::NULL_STRING</string>";
   }	
    return $xml;
}

=head2 getParamterXml
 
Get the XML-RPC fragment for a formal input or output, including the
 ST 

=cut

# formal output/formal input structure
#     <struct>
#         <member>
#           <name>id</name>
#           <value><int>26</int></value>
#         </member>
#          <member>
#          <name>semantic_type</name>
#         <value>
#			... st structure
#		   </value>
#         </member>
#        <member>  
#         <name>name</name>
#         <value><string>Sigma</string></value>
#        </member>
#      </struct>

sub getParameterXml {
   my ($param,$st) = @_;
 	
 
    my $xml = "<struct><member><name>id</name><value><int> " . $param->{'id'} .
    	 "</int></value></member>";
    $xml = $xml . "<member><name>semantic_type</name>";
   
   my $stxml = getSTXml($st);
   $xml = $xml . "<value>$stxml</value>";

    $xml = $xml . "</member>";
    $xml = $xml . "<member><name>name</name><value><string>" . 
    		$param->{'name'} . "</string></value>";

    $xml = $xml . "</member></struct>";
    return $xml;
}   

1;

__END__
=head1 AUTHOR

Harry Hochheiser (hsh@nih.gov)

=cut
