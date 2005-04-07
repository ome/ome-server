# OME/Remote/Facade.pm

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Remote::DeserializerXMLRPC;
use base qw(XMLRPC::Deserializer);

use Carp;
use strict;
use OME;
our $VERSION = $OME::VERSION;


sub decode_value {
  my $self = shift;
  my $ref = shift;
  my($name, $attrs, $children, $value) = @$ref;

  if ($value eq '*([-NULL-])*') {
      return undef;
  } elsif ($name eq 'value') {
    $children ? scalar(($self->decode_object($children->[0]))[1]) : $value;
  } elsif ($name eq 'array') {
    return [map {scalar(($self->decode_object($_))[1])} @{o_child($children->[0]) || []}];
  } elsif ($name eq 'struct') { 
    return {map {
      my %hash = map {o_qname($_) => $_} @{o_child($_) || []};
      #----- scalar is required here, because 5.005 evaluates 'undef' in list context as empty array
      (o_chars($hash{name}) => scalar(($self->decode_object($hash{value}))[1]));
    } @{$children || []}};
  } elsif ($name eq 'base64') {
    require MIME::Base64; 
    MIME::Base64::decode_base64($value);
  } elsif ($name =~ /^(?:int|i4|boolean|string|double|dateTime\.iso8601|methodName)$/) {
    return $value;
  } elsif ($name =~ /^(?:params)$/) {
    return [map {scalar(($self->decode_object($_))[1])} @{$children || []}];
  } elsif ($name =~ /^(?:methodResponse|methodCall)$/) {
    return +{map {$self->decode_object($_)} @{$children || []}};
  } elsif ($name =~ /^(?:param|fault)$/) {
    return scalar(($self->decode_object($children->[0]))[1]);
  } else {
    die "wrong element '$name'\n";
  }
}


1;

=head1 AUTHOR

Ilya Goldberg (igg@nih.gov)

=cut
