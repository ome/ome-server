# OME/Web/DBObjCreate/Category.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjCreate::Category;

=pod

=head1 NAME

OME::Web::DBObjDBObjCreate::Category

=head1 DESCRIPTION

implements _create. Forces name to be entered and CategoryGroup to be entered.

=cut

use strict;
use OME;
use OME::Dataset;
our $VERSION = $OME::VERSION;

use base qw(OME::Web::DBObjCreate);

sub _create {
	my ( $self, $tmpl ) = @_;
	my $q = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();

	my %data_hash;
	foreach( 'Name', 'Description', 'CategoryGroup' ) {
		$data_hash{ $_ } = $q->param( $_ )
			if( $q->param( $_ ) && $q->param( $_ ) ne '' );
	}
	if( not exists $data_hash{ CategoryGroup } ) {
		my ($returnType, $body) = $self->_getForm( $tmpl );
		$body = 
			"<font color='red'>Please select a Category Group</font><br>".
			$body;
		return( $returnType, $body );
	}
	
	my ($mex, $objs) = OME::Tasks::AnnotationManager->
		annotateGlobal( "Category", \%data_hash );
 	$session->commitTransaction();
 	my $obj = $objs->[0];
 	
	if( $q->param( 'return_to' ) || $q->url_param( 'return_to' ) ) {
		my $return_to = ( $q->param( 'return_to' ) || $q->url_param( 'return_to' ) );
		my $id = $obj->id;
		my $html = <<END_HTML;
<script language="Javascript" type="text/javascript">
	window.opener.document.forms[0].$return_to.value = $id;
	window.opener.document.forms[0].submit();
	window.close();
</script>
END_HTML
		return( 'HTML', $html );
	}

 	return( 'REDIRECT', $self->getObjDetailURL( $obj ) );
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
