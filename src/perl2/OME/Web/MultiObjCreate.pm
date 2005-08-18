# OME/Web/MultiObjCreate.pm
#-------------------------------------------------------------------------------
#
# Copyright (C) 2005 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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

package OME::Web::MultiObjCreate;
=pod

=head1 NAME

OME::Web::MultiObjCreate - Create Multi instances of Semantic Types 

=head1 DESCRIPTION

Certain OME tasks require the creation of multiple STs at the same
time. In general, this will be the case for annotations that involve
one semantic type instance along with several referents. This should
be supported in as generic a manner as possible.

This class does the work of creating the form and processing its
input. Subclasses of MultiObjCreate will specify parameters needed for
specific instances of this form. 

In general, we assume that this is an abstract class: subclasses will
implement three methods: getPageTitle() will, as always, specify the
page title. getSTsToCreate() will return a list of STs being created
on this page, and getReturnType() will provide the type of the "main"
ST that refers to the others that are being created. See
ExperimentProtocol.pm for an example.

The corresponding template will have input fields for fields in the
 various STs. Each of these fields will have the form
 TypeName.fieldName, where type is the type name (one of the items in
 getSTsToCreate()), and field name is the semantic element that will
 be populated from the input field. Additional field involving STs
 that will be read from the database - but not created - might also be
 specified. 

For example, in the create.tmpl for ExperimentProtocol,
(src/html/Templates/Create/ExperimentProtocol/create.tmpl), the text
area for  "ExperimentProtocol.Name" indicates the name field for
experimentProtocol, "SamplePreparation.description" coresponds to the
description field  of the SamplePreparation ST, and "Experimenter"
corresponds to selectable items from the Experimenter ST. In
ExperimentProtocol.pm, ExperimentProtocol is defined as the "main"
type,  while Husbandry, SamplePreparation, and ExperimentProtocol are
listed as STs to create. Since Experimenter is not on this list, we
know that values are not being created for this ST - they are simply
being referred to by one or more of the other STs.

The links that will be established between the ST instances are
implicit. For each of the STS that are created, all of the reference
fields will be examined. Specifically, any given reference field will
be checked to see if it's type is included in the list of types being
created in this form. If it is, the appropriate reference will be
made.  

In the ExperimentProtocol case, this means that
"ExperimentProtocol.SamplePreparation" will be set to contain the
value for SamplePreparation that has just been created, and
"ExperimentProtocol.Owner" will be set to the experimenter chosen from
the drop-down.

Once all of these links are constructed, the newly created objects
will be commited.

Another assumption involves the action parameter used on the form. We
assume that the template specifies a button with the name
"action",  and a value with the name of a procedure in this
class. There is currently only one button, corresponding to the
action "create", but this functionality can be extended by simply
adding of another button in the template and a corresponding procedure
in this class 

=cut

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::MultipleSTAnnotationManager;
use OME::Web;
use OME::Web::DBObjCreate;
use base qw(OME::Web);

=head2 getPageBody

Overrides the base method, If the CGI param 'action' is set, calls the
corresponding procedure. Otherwise, returns the form.


=cut

# ADD ERROR CHECKING
sub getPageBody {
    my $self = shift ;
    my $q = $self->CGI() ;

    # create?
    if( $q->param( 'action' ) ) {
	my $actionName =  $q->param('action');
	return $self->$actionName();
    } else {
	return $self->_getForm();
    }
}

=head2 getForm

Create the input form from the template.

=cut
sub _getForm {
    my $self = shift ;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();


    # Load & populate the template
    my $tmpl_dir = OME::Web::DBObjCreate->_baseTemplateDir();
    my $stname = $self->getReturnType();
    my $filename = $tmpl_dir."$stname/create.tmpl";
    my $tmpl = HTML::Template->new( filename => $filename,path => $tmpl_dir,
				    case_sensitive => 1 );
    my %tmpl_params;

    $self->populateTemplate(\%tmpl_params);

    $tmpl->param( %tmpl_params );

    my $html =
	$q->startform().
	$tmpl->output().
	$q->endform();

    return ('HTML',$html);
    
}

=head2 populateTemplate

For STs that involve input fields based on existing values of
other STs, we may need to support programmatic creation of
drop-downs or other fields. Assume that this will be  over-ridden
by  subclasses.

=cut
sub populateTemplate {

    my $self = shift;
    my $tmpl_params = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
 
    $tmpl_params->{Experimenter}  = 
	$self->populateDropDown('@Experimenter','Experimenter');
}

=head2 populateDropDown

Create  the HTML needed for a drop-down list of a given name and type.
=cut
sub populateDropDown {
   my $self = shift;
   my $type = shift;
   my $field = shift;
   my $session= $self->Session();
   my $factory = $session->Factory();

   my @vals = $factory->findObjects($type);
   my $content = $self->Renderer()->renderArray(
       \@vals,
       'dropdown_select',
       {type=> $type,
	field_name=>$field}
   );
   return $content;
}


=head2 create 

    this is the workhorse procedure that does the job of creating the STs

=cut


sub create {
    my $self = shift ;
    my $session= $self->Session();
    my $factory = $session->Factory();

    # pull stuff from form. - the hash of hashes.
    my $vals = $self->getSTVals();



    # create the STs.
    # result is a hash with keys being the STs that we are
    # creating and vals being the objects .

    #debug
    print STDERR "pre-create age is " .
	$vals->{DevelopmentalStage}->{Age} . "\n";

    my $results = OME::Tasks::MultipleSTAnnotationManager->
	createGroupAnnotations($vals);
    
    
    # now , we must look at cgi params and stuff anything else into
    # results that hasn't been set already. This will allow us to
    # create referencs to other STs on form.
    $self->getFormVals($results);

    #debug
    print STDERR "age is " . $results->{DevelompentalStage}->{Age} ."\n";


    # complete all of the linkages
    $self->completeLinkages($results);

    # store the objects and 
    $self->storeObjects($results);
    
    #commit transcations
    $session->commitTransaction();

    # find correct st to return, and go to its detail page.
    my ($returnST) = $self->getReturnType();
    my $obj = $results->{$returnST};
    my $url = OME::Web::DBObjCreate->getObjDetailURL($obj);
    return('REDIRECT',$url);
};


=head2 getSTVals

This procedure iterates over the STs that are being created, 
finding all of the relevant values in the CGI parameters, and building
up a hash of hashes. The outer hash is keyed by ST name, with the
values for each ST being a hash that is keyed by field name, and the
value being the value of that particular field.    

=cut

sub getSTVals {
    my $self = shift;
    my $q = $self->CGI();

    my @stList = $self->getSTsToCreate();
    my @params =  $q->param;

    my %res;
    foreach my $st (@stList) {
	print STDERR "getSTVals. filling in fields for $st\n";
	my %stSpec;
	# find things in param that start with same start
	#-  put them into a hash -key by script value name (minus
	# st name), value is value.
	# thus, if st is "ExperimentProtocol", find all fields that
	# start with  "ExperimentProtocol", strip that off and add
	# key, value to hash
	
	# find the relevant things, iterate over them.
	my (@vars) = grep /$st\.[^.]*/, @params;
	foreach my $var (@vars) {
	    print STDERR "\t found parm $var\n";
	    # strip off st name
	    $var =~ /$st\.([^.]*)/;
	    my $field = $1;
	    print STDERR "\tFound field $field\n";
	    my $val = $q->param($var);
	    print STDERR "\t setting to $val\n";

	    # we don't want this val if it's the name of another st.
	    # other STs need to be included in this list as their own
	    # hash,
	    # which will then be tied together later.
	    $stSpec{$field}=$val unless grep (/$val/, @stList);
	}
	# then, key the whole thing by the ST name.
	$res{$st} = \%stSpec;
    }

    return \%res;
}

=head2 getFormVals

Looks at all of the CGI variables, finding those that have not been
already populated in the accumulated results hash, and those that are
not subfields of an st that might be in the results hash.

This is needed to include references to STs that might be found on the
form,  but are not being created in the form.

=cut 
sub getFormVals { 

    my $self = shift;
    my $results = shift;
    my $q = $self->CGI();
    my @params = $q->param;
    
    foreach my $param (@params) {
	# don't want any vals that correspond to STs being created
	next if (defined $results->{$param});
	# or subfields of those STs.
	next if $param =~  /\w+\.\w+/;
	# else, add it to the results hash.
	$results->{$param} = $q->param($param) unless
	    (defined $results->{$param});
    }

}

=head2 completeLinkages

Collect up the various STs and create the appropriate references as
need be.

=cut


sub completeLinkages {

    my $self = shift;
    my $results = shift;

    print STDERR "Creating linkages \n";
    # at this point, results is a hash that is keyed by the type
    # involved, with the value being the relevant ST.
    
    # look at each type
    my(@types) = keys %$results;



    foreach my $type (@types)  {
	# for each type, link it against all of the others.
	$self->completeTypeLinkages($type,$results,\@types);
    }
}
=head2 completeTypeLinkages

Complete the linkages for a given type.

=cut
sub completeTypeLinkages {

    my $self = shift;
    my $session= $self->Session();
    my ($type,$results,$typesRef) =@_;

    # ok . type is the type being linked, and "TypesRef" is all
    # others.
    print STDERR "Completing linkages for $type\n";

    # get the types by name for my type.
    # this is a hash where key is the name of a field, and value is
    # the type of that field.
    my $fields = $self->getTypesByName($type);
    return unless (defined  $fields);

    # so, we want to 1)find the object in results for current ST
    # set the field value  (from fields) for each named field to be
    # the object of the named st that is found in the hash.
    
    # this is the object in resultss that we're getting at.
    my $obj = $results->{$type};
    
    foreach my $field (keys %$fields) {
	my $fieldType = $fields->{$field};

	# only bother to do this if there is something of the type to
	# be set that we have found in the form results.
	if (defined $results->{$fieldType})  {
	    print STDERR "Setting value \n";
	    # $obj->$field is the st that will have the value.
	    # using it as a proc means set that value to be $results->{$fieldType}.
	    $obj->$field( $results->{$fieldType} );
	}
    }
}




=head getTypesByName

Finds all of the STs that a given ST refers to, 
returns a hash with keys being field names in the ST and values being
the type of those fields

=cut

sub getTypesByName {
    my $self = shift;
    my $stname = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $st = $factory->findObject("OME::SemanticType", name=>$stname);
    return undef unless (defined $st);
    
    # load the type
    my $type = $st->getAttributeTypePackage();

    # get the columns
    my @columns = $type->getColumns();
   

    my %res;

    foreach my $column (@columns) {
	# get the type of the column
	my ($accType) = $type->getAccessorReferenceType($column);
	if (defined $accType &&
	    $accType =~ m/OME::SemanticType::__(.*)/) {
	    # save it in hash.
	    $res{$column} = $1;
	}
    }
    return \%res;
}

=head2 storeObjects 

Complete the storage of the objects 
=cut

sub storeObjects {

    my $self =shift;
    my $results = shift;
    my @sts = $self->getSTsToCreate();
    foreach my $st (@sts) {
	$results->{$st}->storeObject();
    }
}

sub getSTsToCreate{ 
}

sub getReturnType {
}


1;
