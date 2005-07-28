# OME/Web/GroupAndCategoryCreator.pm

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


package OME::Web::GroupAndCategoryCreator;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;
use OME::Web::DBObjCreate;
use OME::Tasks::CategoryManager;
use base qw(OME::Web);

sub getPageTitle {
    return "OME: Create Category Groups and Categories";
}

{
    my $menu_text = "Create  Groups and Categories";
	sub getMenuText { return $menu_text }
}



# ADD ERROR CHECKING
sub getPageBody {
	my $self = shift ;
	my $q = $self->CGI() ;

	# create?
	if( $q->param( 'create' ) ) {
		return $self->_create( );
	} else {
		return $self->_getForm();
	}
}

sub _getForm {
	my $self = shift ;
	my $q = $self->CGI() ;
	my $session= $self->Session();
        my $factory = $session->Factory();


	# Load & populate the template
	my $tmpl_dir = OME::Web::DBObjCreate->_baseTemplateDir();
	my $filename = $tmpl_dir."GroupAndCategory/create.tmpl";
	my $tmpl = HTML::Template->new( filename => $filename,path => $tmpl_dir,
	                                case_sensitive => 1 );
	my $html =
		$q->startform().
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);
	
}

sub _create {
	my $self = shift ;
	my $q = $self->CGI() ;
	my $session= $self->Session();
        my $factory = $session->Factory();

	# pull stuff from form.
	my @vals;
	# form is group name, desc, cat1 name, desc, cat 2 name,
	# desc, etc.
	push @vals, ($q->param('GroupName'),$q->param('GroupDescription'));

	for (my $i=1; $i < 4; $i++ ) {
	    my $name = "CatName$i";
	    my $desc = "CatDesc$i";
	    push @vals, ($q->param($name),$q->param($desc));
	}
	# create mexs
	my $obj =
	    OME::Tasks::CategoryManager->createGroupAndCategories(@vals);
	$session->commitTransaction();
	# go to appropriate dbobjdetail.
	my $url = OME::Web::DBObjCreate->getObjDetailURL($obj);
	return ('REDIRECT',$url);
    }

    



1;
