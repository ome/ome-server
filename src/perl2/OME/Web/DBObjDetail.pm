# OME/Web/DBObjDetail.pm

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


package OME::Web::DBObjDetail;

=pod

=head1 NAME

OME::Web::DBObjDetail - Show detailed information on an object

=head1 DESCRIPTION

Displays detailed information on any DBObject or attribute.

=cut

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Log::Agent;

use OME;
use OME::Web::DBObjRender;
use OME::Web::DBObjTable;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	return $self;
}

{

my $menuText = "DB Detail";
sub getMenuText {
	my $self = shift;
	return $menuText unless ref($self);
	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
	return "$common_name Detail";
}
}

#sub getMenuBuilder { return undef }  # No menu

#sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
	my $self = shift;
	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
    return "$common_name: ".OME::Web::DBObjRender->getObjectLabel($object);
}


sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();

	my $object = $self->_loadObject();
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = $q->startform( { -name => $self->{ form_name } } ).
	           $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	           $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	           $q->hidden({-name => 'action', -default => ''});

	my @relations = $self->_getManyRelations( $object );
	my (@col1, @col2, @col3, @col4);
	
	push( @col3, splice( @relations, 0, 2 ) );
	push( @col4, splice( @relations, 0, 2 ) );

	my $r = POSIX::ceil( scalar( @relations) / 4 );
	push( @col1, splice( @relations, 0, $r ) );
	push( @col2, splice( @relations, 0, $r ) );
	push( @col3, splice( @relations, 0, $r ) );
	push( @col4, splice( @relations, 0, $r ) );

	$html .= $q->table( {-width => '100%', -cellpadding => 10 },
		$q->Tr(
			$q->td(  { -colspan => '2', -width => '50%', -valign => 'top', -align => 'center'}, 
				$self->_getDBObjDetail( $object )
			),
			$q->td(  { -rowspan => '2', -width => '25%', -valign => 'top', -align => 'right' }, [
				join( '', @col3 ),
				join( '', @col4 ),
			] )
		),
		$q->Tr( $q->td(  { -width => '25%', -valign => 'top', -align => 'right' }, [
			join( '', @col1 ),
			join( '', @col2 ),
		] ) )
	);

	$html .= $q->endform();
		
	return ('HTML', $html);
}


sub _getDBObjDetail {
	my ($self, $object) = @_;
	my $q = $self->CGI();

	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );

	my $table_label = 
		( $ST ?
			$q->a( { -href => 'serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType&ID='.$ST->id()},
				   $q->font( { -class => 'ome_header_label' }, $common_name) ):
			$q->font( { -class => 'ome_header_label' }, $common_name)
		).
		$q->font( { -class => 'ome_header_label' }, ": ").
		$q->font( { -class => 'ome_header_title' }, OME::Web::DBObjRender->getObjectLabel($object) );

	my $obj_table;

	my @fieldNames = OME::Web::DBObjRender->getAllFieldNames( $object );
	my %labels  = OME::Web::DBObjRender->getFieldLabels( $object, \@fieldNames );
	my %record  = OME::Web::DBObjRender->renderSingle( $object, 'html', \@fieldNames );

	
	$obj_table .= $q->table( { -class => 'ome_table' },
		$q->caption( $table_label ),
		map(
			$q->Tr( 
				$q->td( { -class => 'ome_td', -align => 'left', -valign => 'top' }, $labels{ $_ } ),
				$q->td( { -class => 'ome_td', -align => 'right', -valign => 'top' }, $record{ $_ } ) 
			),
			@fieldNames
		)
	);
	
	return $obj_table;
}


sub _getManyRelations {
	my ($self, $object) = @_;
	my $q = $self->CGI();
	
	my @relations;

	# print tables for has many relations
	my $manyRefs = $object->getPublishedManyRefs(); 
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );
	foreach my $accessor (keys %$manyRefs ) {
		my $type = $manyRefs->{ $accessor };
		my @objects = $object->$accessor();
		(my $table_name = $accessor ) =~ s/_/ /g;
		$table_name = uc( $table_name );
		push @relations, $q->p( $tableMaker->getList( 
			{
				title            => $table_name, 
				embedded_in_form => $self->{ form_name },
				Length           => 5,
				width            => '100%'
			}, 
			$type, 
			\@objects
		) );
	}

	return @relations;
}

sub _loadObject {
	my $self = shift;
	return $self->{__object} if $self->{__object};
	
	my $q    = $self->CGI();
	my $factory = $self->Session()->Factory();
	
	my $type = $q->param( 'Type' )
		or die "Type not specified";
	my $id   = $q->param( 'ID' )
		or die "ID not specified";

	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	$self->{__object} = $factory->loadObject( $formal_name, $id )
		or die "Could not load DBObject $type, id=$id";
	return $self->{__object};
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
