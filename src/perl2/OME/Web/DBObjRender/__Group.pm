# OME/Web/DBObjRender/__Group.pm
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


package OME::Web::DBObjRender::__Group;

=pod

=head1 NAME

OME::Web::DBObjRender::__Group - specialized rendering of Group ST

=head1 DESCRIPTION

Provides custom behavior for rendering Group ST

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use base qw(OME::Web::DBObjRender);

# Class data - override default behavior
__PACKAGE__->_fieldLabels( {
});


=head2 getRefSearchField

returns a dropdown list of Group names valued by id.

=cut

sub getRefSearchField {
	my ($proto, $from_type, $to_type, $accessor_to_type, $default) = @_;
	
	my $factory = OME::Session->instance()->Factory();
	
	my (undef, undef, $from_formal_name) = OME::Web->_loadTypeAndGetInfo( $from_type );

	# Group list
	my @groups = $factory->findAttributes( "Group" );
	my %group_names = map{ $_->id() => $_->Name() } @groups;
	my $group_order = [ '', sort( { $group_names{$a} cmp $group_names{$b} } keys( %group_names ) ) ];
	$group_names{''} = 'All';

	my $q = new CGI;

	return $q->popup_menu( 
		-name	  => $from_formal_name."_".$accessor_to_type,
		'-values' => $group_order,
		-labels	  => \%group_names, 
		-default  => $default
	);

}



=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
