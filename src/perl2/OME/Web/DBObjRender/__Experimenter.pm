# OME/Web/DBObjRender/__Experimenter.pm
#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:  
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__Experimenter;

=pod

=head1 NAME

OME::Web::DBObjRender::__Experimenter - Specialized rendering for Experimenter Attribute

=head1 DESCRIPTION

Provides custom behavior for rendering an Experimenter Attribute

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use base qw(OME::Web::DBObjRender);

=head2 getObjectLabel

FirstName LastName

=cut

sub getObjectLabel {
	my ($proto,$obj,$format) = @_;

	return $obj->FirstName." ".$obj->LastName;
}

=head2 renderSingle

make email address a link in html format

=cut

sub renderSingle {
	my ($proto,$obj,$format,$fieldnames) = @_;
	my $q       = new CGI;
	my $record  = $proto->SUPER::renderSingle($obj,$format,$fieldnames);

	if( grep( m/^Email$/, @$fieldnames) and $format eq 'html' ) {
		my $emailURL = 'mailto:'.$obj->Email();
		$record->{ 'Email' } = $q->a( { -href => $emailURL }, $obj->Email() );
	}
	
	return %$record if wantarray;
	return $record;
}


=head2 getRefSearchField

returns a dropdown list of Experimenter names valued by id.

=cut

sub getRefSearchField {
	my ($proto, $from_type, $to_type, $accessor_to_type) = @_;
	
	my $factory = OME::Session->instance()->Factory();
	
	my (undef, undef, $from_formal_name) = OME::Web->_loadTypeAndGetInfo( $from_type );

	# Owner list
	my @experimenters = $factory->findAttributes( "Experimenter" );
	my %experimenter_names = map{ $_->id() => $_->FirstName().' '.$_->LastName() } @experimenters;
	my $experimenter_order = [ '', sort( { $experimenter_names{$a} cmp $experimenter_names{$b} } keys( %experimenter_names ) ) ];
	$experimenter_names{''} = 'All';

	my $q = new CGI;

	return $q->popup_menu( 
		-name	=> $from_formal_name."_".$accessor_to_type,
		'-values' => $experimenter_order,
		-labels	 => \%experimenter_names
	);

}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
