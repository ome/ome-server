# OME/Web/DBObjCreate.pm

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
# Written by:
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Web::DBObjCreate;

use strict;
use Carp;

use OME;
use OME::Tasks::AnnotationManager;
use Data::Dumper;

our $VERSION = $OME::VERSION;
use base qw(OME::Web);

=pod

=head1 NAME

OME::Web::DBObjCreate - Create new DBObjects

=head1 DESCRIPTION

DBObjCreate displays detailed information on any DBObject or attribute.
It's default behaviors can be overridden by writing subclasses.

Important!! Subclasses should not be accessed directly. All access 
should go through DBObjCreate. Specialization is completely
transparent.

Subclasses follow the naming convention implemented in __specialize.
Subclasses may override one or more of the functions that indicate they
are Overridable.

=head1 METHODS

=cut

my $VALIDATION_INCS = <<END;
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.config.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.core.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.numbers.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.special.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.lang-enUS.js"></script>
<script type="text/javascript" src="/JavaScript/fValidate/fValidate.validators.js"></script>
END

=head2 _get_published_create_types

Returns a list of object types (by their formal names) that is used to
populate a dropdown list of types the user is allowed to create.

Currently it returns Project, Dataset, and all the Global STs,
excluding Experimenter.

=cut

sub _get_published_create_types {
	my $self = shift;
	# _published_create_types gets translated to the 'Create a:' drop-down list
	my $factory = $self->Session->Factory();
	my @globalSTs = $factory->findObjects( 'OME::SemanticType', 
		granularity => 'G',
		__order     => 'name',
		'name'      => [ '!=', 'Experimenter' ],
	);
	return (
		'OME::Project',
		'OME::Dataset',
		map( '@'.$_->name(), @globalSTs )
	);
}

=head2 getMenuText

If called from the Package, will return "Other"
If called from an instance that has a type CGI parameter, will return "[common name]"

Overridable.

=cut

sub getMenuText {
	my $self = shift;
	my $menuText = "Other";
	return $menuText unless ref($self);
	my $q = $self->CGI();
	my $type = $self->_getType();

	my $specializedDetail;
	return $specializedDetail->getMenuText( )
		if( $specializedDetail = $self->__specialize( $type ) and
		    ref( $self ) eq __PACKAGE__ );

	if( $type ) {
 		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
 		$menuText = "$common_name";
 	}
	return $menuText;
}

=head2 getPageTitle

If called from the Package, will return "Create Something"
If called from an instance that has CGI parameters, will return "Create [common name]"

Overridable.

=cut

sub getPageTitle {
	my $self = shift;
	my $pageTitle = "Create Something";
	return $pageTitle unless ref($self);
	my $q = $self->CGI();
	my $type = $self->_getType();

	my $specializedDetail;
	return $specializedDetail->getPageTitle( )
		if( $specializedDetail = $self->__specialize( $type ) and
		    ref( $self ) eq __PACKAGE__ );

	if( $type ) {
 		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
 		$pageTitle = "Create $common_name";
 	}
	return $pageTitle;
}

=head2 getPageBody

Overridable

=cut

sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();
	my $type = $self->_getType();
	my $locked_type = ( $q->param( 'Locked_Type' ) || $q->url_param( 'Locked_Type' ) );

	my $specializedDBObjCreate;
	return $specializedDBObjCreate->getPageBody( )
		if( $specializedDBObjCreate = $self->__specialize( $type ) and
		    ref( $self ) eq __PACKAGE__ );

	# create?
	if( $q->param( 'create' ) ) {
		return $self->_create( );
	} else {
		return $self->_getForm();
	}
}
	
=head2 _getForm

Overridable

=cut

sub _getForm {
	my $self    = shift;
	my $q       = $self->CGI();
	my $factory = $self->Session->Factory();
	my $type = $self->_getType();
	my $locked_type = ( $q->param( 'Locked_Type' ) || $q->url_param( 'Locked_Type' ) );

	my $specializedDetail;
	return $specializedDetail->getPageBody( )
		if( $specializedDetail = $self->__specialize( $type ) and
		    ref( $self ) eq __PACKAGE__ );

  	# load a template
 	my $tmpl_path = $self->_findTemplate( $type, 'create' );
 	$tmpl_path = $self->_baseTemplateDir().'/generic_create.tmpl'
 		unless $tmpl_path;
 	my $tmpl = HTML::Template->new( filename => $tmpl_path, path => $self->_baseTemplateDir(), case_sensitive => 1 );
 	
 	# get data for the template
	my $requests = $self->_parse_tmpl_fields( [ $tmpl->param( ) ]
 	);

	my %tmpl_data = $self->getFormInputsForFields( $type,$requests );


	
	# /field_loop = Iterate over the fields in the type
	my ($package_name, $common_name, $formal_name, $ST);
	($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type ) if $type;
	if( exists $requests->{ '/field_loop' } && $type ) {
		foreach my $request ( @{ $requests->{ '/field_loop' } } ) {
			my $request_string = $request->{ 'request_string' };
			my $inner_requests = $self->_parse_tmpl_fields( [ $tmpl->query( loop =>	$request_string ) ] );
			
			# exclude request: skip some fields
			my %excluded_fields;
			%excluded_fields = map{ $_ => undef } split( /,/, $request->{ exclude } )
				if exists $request->{ exclude };
				
			# grab the published fields that aren't being excluded
			my @fields = sort( 
			    grep( ( not exists$excluded_fields{ $_ }), 
				  $package_name->getPublishedCols() )
			    );

			
			# get form inputs iff requested
			my %rendered_fields;
			%rendered_fields = $self->getFormInputsForFields( $type, \@fields )
				if( $tmpl->query( name => [ $request_string, '/field_input' ] ) );

			# package up stuff for the template
			foreach my $field( @fields ) {
				my %field_entry;
				# /name:
				if( $tmpl->query( name => [ $request_string, '/name' ] ) ) {
					if( $ST ) {
						my $se = $factory->findObject( 'OME::SemanticType::Element',
							semantic_type => $ST,
							name          => $field
						);
						$field_entry{ '/name' } = $q->a( {
							-href   => 'javascript: SEdocPopup( '.$se->id.');',
							-title  => "$field Documentation" },
							$field
						) if $se;
					}
					unless( exists $field_entry{ '/name' } ) {
						$field_entry{ '/name' } = $field;
					} 
				}
				# /sql_type:
				if( $tmpl->query( name => [ $request_string, '/sql_type' ] ) ) {
					my $SQL_data_type = $package_name->getColumnSQLType( $field );
					$field_entry{ '/sql_type' } = $SQL_data_type;
				}
				# Add form input only if requested
				$field_entry{ '/field_input' } = $rendered_fields{ $field }
					if( $tmpl->query( name => [ $request_string, '/field_input' ] ) );
				# shove all this loop crap into the master template hash
				push( @{ $tmpl_data{ $request_string } }, \%field_entry );
			}
		}
	}

	# /types_loop = published types for creation
	# collect data for type selection
	if( exists $requests->{ '/types_loop' } ) {
		if( not $locked_type ) {
			foreach my $request ( @{ $requests->{ '/types_loop' } } ) {
				my $request_string = $request->{ 'request_string' };
				foreach my $formal_name ( $self->_get_published_create_types() ) {
					my ($package_name, $common_name, undef, $ST) = $self->_loadTypeAndGetInfo( $formal_name );
					my $type_data;
					$type_data->{ formal_name } = $formal_name;
					$type_data->{ common_name } = $common_name;
					$type_data->{ selected } = 'selected'
						if( $type && $formal_name eq $type );
					push( @{ $tmpl_data{ $request_string } }, $type_data );
				}
			}
		} else {
			$tmpl_data{ '/locked_type' } = ( $ST ?
				$q->a( {
					-href   => 'javascript: STdocPopup( "'.$ST->name.'");',
					-title  => "$common_name Documentation" },
					$common_name
				) :
				$common_name
			);
		}
	}
	# /documentation_of_type: a link to documentation of the type
	if( exists $requests->{ '/documentation_of_type' } ) {
		$tmpl_data{ '/documentation_of_type' } = $q->a( {
			-href   => 'javascript: STdocPopup( \''.$ST->name.'\');',
			-title  => "$common_name Documentation",
			-class  => 'ome_quiet' },
			"Read Documentation on $common_name"
		) if $ST;
	}

	# coalate html output
 	$tmpl->param( %tmpl_data );
	my $html = 
		$q->startform(  { -name => 'primary', -onsubmit => 'return validateForm( this, false, true );' } ).
		$VALIDATION_INCS.
		$tmpl->output().
 		$q->endform();
	return ( 'HTML', $html );
}

=head2 _create

Accepts no parameters. Responsible for collecting data from $self->CGI
and using it to create a new object. If successful, should return:
	return( 'REDIRECT', $self->getObjDetailURL( $obj ) );


Overrideable.

=cut

sub _create {
	my ( $self ) = @_;
	my $q = $self->CGI();
	my $type = $self->_getType();
	my $session = $self->Session();
	my $factory = $session->Factory();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	my %data_hash;
	foreach( $package_name->getPublishedCols() ) {
		$data_hash{ $_ } = $q->param( $_ )
			if( $q->param( $_ ) );
	}
	
 	my $obj;
 	if( $ST ) {
 		my ($mex, $objs);
 		if( $ST->granularity() eq 'D' ) {
			($mex, $objs) = OME::Tasks::AnnotationManager->
				annotateDataset( $data_hash{ dataset }, $ST, \%data_hash );
 		} elsif( $ST->granularity() eq 'I' ) {
			($mex, $objs) = OME::Tasks::AnnotationManager->
				annotateImage( $data_hash{ image }, $ST, \%data_hash );
 		} elsif( $ST->granularity() eq 'G' ) {
			($mex, $objs) = OME::Tasks::AnnotationManager->
				annotateGlobal( $ST, \%data_hash );
 		} elsif( $ST->granularity() eq 'F' ) {
			($mex, $objs) = OME::Tasks::AnnotationManager->
				annotateFeature( $data_hash{ feature }, $ST, \%data_hash );
		}
		$obj = $objs->[0];
 	} else {
	 	$obj = $factory->newObject( $formal_name, \%data_hash );
	}
 	$session->commitTransaction();
 	
	# Return new object id to a form element of the referring page
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

	# OR
	# refresh the referring page by submitting its form
	if( $q->param( 'refresh_when_done' ) || $q->url_param( 'refresh_when_done' ) ) {
		my $html = <<END_HTML;
<script language="Javascript" type="text/javascript">
	window.opener.document.forms[0].submit();
	window.close();
</script>
END_HTML
		return( 'HTML', $html );
	}

	# OR
	# default: redirect to the object detail
 	return( 'REDIRECT', $self->getObjDetailURL( $obj ) );
}


# return form elements appropriate for accepting field input
sub getFormInputsForFields {
	my ($self, $type, $field_requests, $options) = @_;
	return () unless $type;
	my ( %record, $specializedPkg );
	$options = {} unless $options; # makes things easier
	$field_requests = $self->_parse_tmpl_fields( $field_requests
	    );

	# specialized form fields
	$specializedPkg = $self->__specialize( $type );
	%record = $specializedPkg->_getFormInputsForFields( $type, $field_requests, $options )
		if $specializedPkg and $specializedPkg->can('_getFormInputsForFields');

	# default form fields
	my $q = $self->CGI();
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	foreach my $field ( keys %$field_requests ) {
		foreach my $request ( @{ $field_requests->{ $field } } ) {
			my $request_string = $request->{ 'request_string' };
			my %validate;
			
			# don't override specialized renderings
			next if exists $record{ $request_string };

# Request for things other than form fields

			# /common_name = object's common name
			if( $field eq '/common_name' ) {
				$record{ $request_string } = $common_name;
				next;
			} 

			# /formal_name or /type = object's formal name
			elsif( $field eq '/formal_name' or $field eq '/type' ) {
				$record{ $request_string } = $formal_name;
				next;
			}

			# /type_detail_url = url to detailed description of Semantic Type (won't work for DBObjects)
			elsif( $field eq '/type_detail_url' and $ST ) {
				$record{ $request_string } = $self->getObjDetailURL( $ST );
				next;
			}
						
			# time to get field info
			my $ref_type = $package_name->getColumnType($field );

			next unless $ref_type; # skip if field doesn't
				# exist in this type

			my $SQL_data_type = $package_name->getColumnSQLType( $field );
			
			# field/render-data_type = the sql data type of the field
			if( exists $request->{ '/render' } && $request->{ '/render' } eq 'data_type' ) {
				$record{ $request_string } = $SQL_data_type;
			}
			
			# field/render-name = the name of the field
			elsif( exists $request->{ '/render' } && $request->{ '/render' } eq 'name' ) {
				$record{ $request_string } = $field;
			}
			
# All these others actually get form input fields
			
			# has-one reference
			elsif( $ref_type eq 'has-one' ) {
				my $ref_to=$package_name->getAccessorReferenceType($field);
				$record{ $request_string } = $self->getStuffToPopulateHasOneRef( $field, $ref_to );
			}

			# *many reference
			elsif( $ref_type eq 'has-many' || $ref_type eq "many-to-many" ) {
				my $ref_to = $package_name->getAccessorReferenceType( $field );
				# FIXME: should be a link to a search page to allow multiple selection of ref_to
				# experimenter, dataset, project, etc should default to session's things
				$record{ $request_string } = "* $ref_type ref to $ref_to";
			}

			# data types
			elsif( $SQL_data_type eq 'text' ) {
#				$record{ $request_string } = $q->textfield(
#					-name => $field,
#					-size => 25,
#					%validate );
				$record{ $request_string } = $q->textarea(
					-name    => $field,
					-rows    => 5,
					-columns => 50,
					%validate );
			} elsif( $SQL_data_type eq 'timestamp' ) {
				# FIXME: figure out what format timestamp should be and validate using a regex
				# $validate{ -alt } = 'custom|regex'
				$record{ $request_string } = $q->textfield(
					-name => $field,
					-size => 25,
					%validate ).' Time Stamp';
			} elsif( $SQL_data_type =~ m/^integer|bigint|smallint$/ ) {
				$validate{ -alt } = 'number|1|bok' # optional integer
					if $options->{validate};
				$record{ $request_string } = $q->textfield(
					-name => $field,
					-size => 9,
					%validate ).' Integer (no decimal point)';
			} elsif( $SQL_data_type =~ m/^double precision|real$/ ) {
				$validate{ -alt } = 'number|0|bok' # optional floating point 
					if $options->{validate};
				$record{ $request_string } = $q->textfield(
					-name => $field,
					-size => 9,
					%validate ).' Numeric (decimal allowed)';
			} elsif( $SQL_data_type eq 'boolean' ) {
				$record{ $request_string } = $q->checkbox(
					-name => $field,
					-value => 1,
					%validate );
			}
		}
	}
	
	return %record;
}


=head2 getStuffToPopulateHasOneRef

	my $html_snippet = $self->getStuffToPopulateHasOneRef( $accessor_to_type, $type, $default);

get some html that will let the user pick an object to satisfy a has-one reference.

=cut

sub getStuffToPopulateHasOneRef {
	my ($self, $accessor_to_type, $type) = @_;
	my $factory = $self->Session->Factory();	
	# specialized form fields
	my $specializedPkg = $self->__specialize( $type );
	return $specializedPkg->_getStuffToPopulateHasOneRef( $accessor_to_type, $type )
		if $specializedPkg and $specializedPkg->can('_getStuffToPopulateHasOneRef');

	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $type );
	my $q = $self->CGI();
	my $obj;

	my $newFieldName = "_New". $accessor_to_type;
	my $newField = $q->hidden(-name => $newFieldName);

	# is there a selection? try loading it
	if ($q->param( $newFieldName) && $q->param($newFieldName) ne '') {
	    $obj = $factory->loadObject( $type, $q->param( $newFieldName ) )
		    or die "Could not load object ( type=$type,	id=".$q->param( $accessor_to_type ).")";
	}
	elsif( $q->param( $accessor_to_type ) && $q->param($accessor_to_type ) ne '' ) {
		$obj = $factory->loadObject( $type, $q->param( $accessor_to_type ) )
			or die "Could not load object ( type=$type, id=".$q->param( $accessor_to_type ).")";

	# try a default
	} else {
		$obj = $specializedPkg->_defaultObj( )
			if $specializedPkg and $specializedPkg->can('_defaultObj');
	}

	my $create_link = $q->a( { 
	    -href => "javascript: creationPopup( '$type','$newFieldName' );"}, 
				 "Create a new $common_name" );
	# populate a hash
	my %select_hash;
	if ($obj) {
	    $select_hash{default_value} = $obj->id;
	}

	# get the list of items
	my @itemList  = $factory->findObjects($type);

	# do the rendering.
	my $renderer = $self->Renderer;
	my $options = $renderer->renderArray(\@itemList,'list_of_options',\%select_hash);
	my $select="<SELECT NAME=\"$accessor_to_type\">$options</SELECT>";
	return $newField . $select . " or " . $create_link;
}



# field syntax is: "field/option-value/option-value..."
# magic fields are distinguished from object fields the prefix '/' (i.e. "/magic_field")

# parse field requests into fields & options. store in hash formatted like so:
#	$parsed_field_requests{ $field_named_foo } = \@requests_for_field_named_foo
#	\@requests_for_field_named_foo is a bunch of hashes formated like so:
#	$request{ $option_name } = $option_value;
# also, the orgininal request is stored in:  $request{ 'request_string' }
sub _parse_tmpl_fields {
	my ( $self, $field_requests ) = @_;

	if( ref( $field_requests ) eq 'ARRAY' ) {
		my %parsed_field_requests;
		foreach my $request ( @$field_requests ) {
			my $field;
			my %parsed_request;
			my @items = split( m'/', $request );
			# the first item will be blank for magic fields because magic fields
			# are prefixed with the delimeter
			if( $items[0] eq '' ) {
				shift( @items );
				$field = '/'.shift( @items );
			} else {
				$field = shift( @items );
			}
			foreach my $option ( @items ) {
				my ($name,$val) = split( m/-/, $option );
				$parsed_request{ $name } = $val;
			}
			$parsed_request{ 'request_string' } = $request;
			push( @{ $parsed_field_requests{ $field } }, \%parsed_request );
		}
		$field_requests = \%parsed_field_requests;
	}
	
	return $field_requests;
}

=head2 __specialize

	my $specializedPackage = $self->__specialize( $type );

returns a specialized package (if one exists) for dealing with $type.
returns undef if a specialized prototype does not exist or if it was
called with with a specialized prototype.

DO NOT Override

=cut

sub __specialize {
	my ( $self, $type ) = @_;
	my $q = $self->CGI();
	if( $type ) {
 		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

		# construct specialized package name
		my $specializedPackage = $formal_name;
		($specializedPackage =~ s/::/_/g or $specializedPackage =~ s/@//);
		$specializedPackage = "OME::Web::DBObjCreate::".$specializedPackage;

		# obtain package
		eval( "use $specializedPackage" );
		return $specializedPackage->new( CGI => $self->CGI() )
			unless $@ or ref( $self ) eq $specializedPackage;
	}

	return undef;
}

=head2 _baseTemplateDir

	my $template_dir = $self->_baseTemplateDir();
	
	Returns the directory where specialized templates for this class are stored.

=cut

sub _baseTemplateDir { 
	my $self = shift;
	my $session = $self->Session();
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	return $tmpl_dir."/System/Create/";
}

=head2 _findTemplate

	my $template_path = $self->_findTemplate( $obj, $mode );

returns a path to a custom template (see HTML::Template) for this $obj
and $mode - OR - undef if no matching template can be found

=cut

sub _findTemplate {
	my ( $self, $obj, $mode ) = @_;
	return undef unless $obj;
	my $tmpl_dir = $self->_baseTemplateDir();
	my ($package_name, $common_name, $formal_name, $ST) =
		$self->_loadTypeAndGetInfo( $obj );
	my $tmpl_path = $formal_name; 
	$tmpl_path =~ s/@//g; 
	$tmpl_path =~ s/::/\//g; 
	$tmpl_path .= "/".$mode.".tmpl";
	$tmpl_path = $tmpl_dir.$tmpl_path;
	return $tmpl_path if -e $tmpl_path;
	return undef;
}

sub _getType {
	my $self = shift;
	my $q    = $self->CGI();
	my $type = ( $q->param( '_Type' ) || $q->url_param( 'Type' ) ||
	             $q->param( 'Locked_Type' ) || $q->url_param( 'Locked_Type' ) );
	
	$type = undef 
		if( exists $self->adminObjects()->{ $type } || exists $self->invisibleObjects()->{ $type } );
	return $type;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
