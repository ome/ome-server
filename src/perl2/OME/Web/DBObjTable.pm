# OME/Web/NewTable.pm

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


package OME::Web::NewTable;

=pod

=head1 NAME

OME::Web::NewTable

=head1 DESCRIPTION

Build a table with information about any DBObject or attribute.

=cut

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Log::Agent;

use OME;
use OME::Web::RenderData;

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

sub getMenuBuilder { return undef }  # No menu

sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
	my $self = shift;
	my $q    = $self->CGI();
	my $type = $q->param( 'Type' )
		or die "Type not specified";
	$type = _getTypeName( $type );
    return "$type Table";
}

sub getPageBody {
	my $self = shift;
	my $q    = $self->CGI();
	my $factory = $self->Session()->Factory();
	
	my $type = $q->param( 'Type' )
		or die "Type not specified";

	# collect search params
	my @searchParamNames = grep( /^$type.+/, $q->param( ) );
	my %searchParams = map{ $_ => $q->param( $_ ) } @searchParamNames;
	foreach my $key (keys %searchParams) {
		# get the key's Real name
		(my $newkey = $key) =~ s/^($type)_//;
		# copy the key into the real name unless the value is blank
		$searchParams{ $newkey } = $searchParams{ $key }
			unless not defined $searchParams{ $key } or $searchParams{ $key } eq '';
		# delete the old key
		delete $searchParams{ $key };
	}


	# get objects
	my @objects;
	my $typeAttr;
	if( $type =~ /^@/ ) {
		my $stName = substr($type,1);
		@objects = $factory->findAttributesLike( $stName, %searchParams );
		$typeAttr = $factory->findObject( "OME::SemanticType", name => $stName);
	} else {
		@objects = $factory->findObjectsLike( $type, %searchParams );
	}

	my $type_name = _getTypeName($type);
	my $table_name = $type_name."_TABLE";
	my $table_label = ( $typeAttr ?
		$q->a( { href => 'serve.pl?Page=OME::Web::ObjectDetail&Type=OME::SemanticType&ID='.$typeAttr->id() },
		       $type_name ) :
		$type_name
	);
		

	my $html;

	my @fieldNames = OME::Web::RenderData->getFieldNames( $type );
	my %labels     = OME::Web::RenderData->getFieldLabels( $type, \@fieldNames );
	my %searches   = OME::Web::RenderData->getSearchFields( $type, \@fieldNames );
	my @records    = OME::Web::RenderData->render( \@objects, 'html', \@fieldNames );
	
	# table data
	my @table_data;
	foreach my $record ( @records ) {
		push( @table_data, 
			$q->td( { class => 'ome_td' }, 
				[ map( $record->{$_}, @fieldNames ) ] 
			)
		);
	}
	
	$html .= 
		$q->startform({-name => $table_name}).
		$q->table( { class => 'ome_table' },
			# Table title
			$q->caption( $table_label ),
			$q->Tr( [
				# Table headers
				$q->td( { class => 'ome_td' },
					[ map( $labels{ $_ }, @fieldNames ) ]
				),
				# Search fields
				$q->td( { class => 'ome_td' },
					[ map( $searches{ $_ }, @fieldNames ) ]
				),
				# Table data
				@table_data,
				$q->hidden({-name => 'action', -default => ''}),
				$q->hidden({-name => 'Type', -default => '$type'}),
				$self->__getOptionsTD( [ 'Search' ], scalar( @fieldNames ), $table_name ),
			]
			)
		).
		$q->endform()
	;

	return ('HTML', $html);
}


sub _getTypeName {
	my $type = shift;
	$type =~ s/^@// or
	( $type =~ s/OME::// and $type =~ s/::/ /g );
	return $type;
}

sub __getOptionsTD {
	my ($self, $options, $span, $table_name) = @_;
	my $q = $self->CGI();

	$span = 1 unless ($span);

	# Build our buttons
	my $option_buttons = join( ' | ', 
	 	map( 
			$q->a( {
				-href => "#",
				-onClick => "document.forms['$table_name'].action.value='$_'; document.forms['$table_name'].submit(); return false",
				-class => 'ome_widget'
			}, $_ ),
			@$options
		)
	);

	# Build our table and return it
	if ($option_buttons) {
    	return $q->td( {
				-colspan => $span,
				-align => 'right',
				-bgcolor => '#EFEFEF',
				-class => 'ome_menu_td',
			},
			$option_buttons,
		);
	}

	return;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
