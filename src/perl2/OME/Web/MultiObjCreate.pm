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
page title, and getReturnType() will provide the type of the "main"
ST that refers to the others that are being created. Another call -
populateTemplate - includes specific code needed to populate drop-down
and additional fields on the template. See ExperimentProtocol.pm for
an example. 

The corresponding template will have input fields for fields in the
various STs. Each of these fields will have the form
@TypeName.fieldName, where type is the type name (one of the items in
getSTsToCreate()), and field name is the semantic element that will
be populated from the input field. This syntax can be extended
arbitrarily.Additional field involving STs that will be read from the
database - but not created - might also be specified.  

For example, in the create.tmpl for ExperimentProtocol,
(src/html/Templates/Create/ExperimentProtocol/create.tmpl), the text
area for  "@ExperimentProtocol.Name" indicates the name field for
experimentProtocol,
"@ExperimentalProtocol.SamplePreparation.description" coresponds
to the description field  of the SamplePreparation ST, associated with
this protocol. ExperimentProtocol.Owner corresponds to selectable
items from the Experimenter ST. In ExperimentProtocol.pm,
ExperimentProtocol is defined as the "main" type.

The links that will be established between the ST instances are given
by the dotted pair notation. Furthermore, new objects will be created
only when necessary.  Thus, if the owner field is populated as a
pull-down containing instances of Experimenter, no new instances will
be created.

Another assumption involves the action parameter used on the form. We
assume that the template specifies a button with the name
"action",  and a value with the name of a procedure in this
class. There is currently only one button, corresponding to the
action "create", but this functionality can be extended by simply
adding of another button in the template and a corresponding procedure
in this class.

Backlinks and lists are currently not supported.

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

    # specialized in subclasses to have type-specific behavior.
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

}

=head2 populateDropDown

Create  the HTML needed for a drop-down list of a given name and type.
=cut
sub populateDropDown {
   my $self = shift;
   my $type = shift;
   my $field = shift;
   my $params = shift;
   my $session= $self->Session();
   my $factory = $session->Factory();

   my @vals = $factory->findObjects($type);
   my $content = $self->Renderer()->renderArray(
       \@vals,
       'dropdown_select',
       {type=> $type,
	field_name=>$field}
   );
   $params->{$field} = $content;
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

    # find correct st to return, and go to its detail page.

    # create the STs.
    # result is a hash with keys being the STs that we are
    # creating and vals being the objects .

    my $results = OME::Tasks::MultipleSTAnnotationManager->
	createGroupAnnotations($vals);

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
values for each ST being a hash that is keyed by field name. This
proceeds recursively down the dotted pair names, until each field
ends in a scalar (float, string, etc. value) from a text field or a
semantic type values  from a pull-down or other input field.
value being the value of that particular field.    

=cut

sub getSTVals {
    my $self = shift;
    my $q = $self->CGI();

    my @params =  grep /@/, $q->param;

    my %res;
    print STDERR  "in getSTVals\n";
    my @fields;
    my  $obj;
    my $paramVal;
    my $field;
    foreach my $param (@params) {

	$paramVal = $q->param($param);
	# trim whitespcae
	$paramVal =~ s/^\s+(\S*)\s+$/$1/;

	# skip params with no contents.
	if (defined ($paramVal) && length($paramVal) > 0 ) {
	    # split by "." to find pieces of the param
	    $param =~ s/@(.*)/$1/;
	    @fields = split '\.' , $param;
	    # popuplate these fields in the hash.
	    $self->getSubFields(\%res,\@fields,$paramVal);
	}
    }
    return \%res;
}

=head2 getSubFields

To find the subfields, iterate down the list. For any given field
    name, there are two possibilities:

    1) the field has already been defined (probably by a prior
    value). In this case, recursively call getSubFields. When we get
    to the last field, set it to the param values.

    2) The field has not been defined. In this case, recursively go 
    down the dotted-pair list of fields and create them as needed.
    
=cut
sub getSubFields {
    my $self = shift;
    my $res = shift;
    my $fields = shift;
    my $val = shift;

    my $field  = shift @$fields;
    if (scalar (@$fields) ==0) {
	$res->{$field} = $val;
    }
    else { # more to go, recurse
	if (defined $res->{$field}) {
	    $self->getSubFields($res->{$field},$fields,$val);
	}
	else {
	    $res->{$field} = $self->buildSubFields($fields,$val);
	}
    }
}

=head2 buildSubFields

 Recursively create sub-fields in the dotted-pair list, until we
 bottom out at the last field. At that point, set it to have the
 specified value.

=cut
sub buildSubFields {
    my $self = shift;
    my $fields = shift;
    my $val = shift;
    
    my %res;
    my $field = shift @$fields;
    if (scalar(@$fields) ==0) {
	$res{$field} = $val;
    }
    else {
	$res{$field} = buildSubFields($fields,$val);
    }
    return \%res;
}

1;
