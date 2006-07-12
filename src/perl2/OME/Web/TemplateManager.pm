# OME/Web/TemplateManager.pm

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
# Written by: Harry Hochheiser <hsh@nih.gov>
#-------------------------------------------------------------------------------

package OME::Web::TemplateManager;

use OME;

use strict;
use HTML::Template;
use base qw(OME::Web);

our $NO_TEMPLATE="NO_TEMPLATE";

=head1 NAME 

OME::Web::TemplateManager - code for retrieving and instantiating templates

=head1 DESCRIPTION
    OME's Web interface uses set of HTML::Templates
    (http://html-template.sourceforge.net/)  to provide the
    layout for the various web pages. 

    Currently, the templates are stored in subdirectories of the
    Template directory for the installation. This directory is given
    by 

    Procedures in this module handle location of the appropriate
    template file and instanatiation of the template.

    Additional code provides support for listing all of the templates
    that might be used to display objects of a given type.

=head2 rootTemplateDir

	my $template_dir = $self->rootTemplateDir( );
	
	Returns the directory where templates for layouts are stored.
        $Session->Configuration->template_dir.

        This should only be used internally.
=cut

sub rootTemplateDir { 
    my $self = shift;
    my $tmpl_dir = $self->Session()->Configuration()->template_dir();
    return $tmpl_dir;
}


=head2 systemTemplateDir

	my $template_dir = $self->systemTemplateDir( );
	
	Returns the directory where templates core sytem functions are
	located: generally, the "System" subdirectory under
	rootTemplateDir. 

        This should only be used internally.
=cut

sub systemTemplateDir {
    my $self =shift;
    my $tmpl_dir = $self->rootTemplateDir();
    $tmpl_dir .="/System/";
    return $tmpl_dir;
}



=head2 actionTemplateDir

	my $template_dir = $self->actionTemplateDir( );
	
	Returns the directory where templates core sytem functions are
	located: generally, the "Action" subdirectory under
	systemTemplateDir. 

        This should only be used internally.
=cut

sub actionTemplateDir {
    my $self = shift;
    my $tmpl_dir = $self->systemTemplateDir();
    $tmpl_dir .="Actions/";
    return $tmpl_dir;
}


=head2 createTemplateDir

    The directory for creation templates.  Generally, the "Action"
	subdirectory under systemTemplateDir. 

        This should only be used internally.
=cut

sub createTemplateDir { 
    my $self = shift;
    my $tmpl_dir = $self->systemTemplateDir();
    return $tmpl_dir."/Create/";
}



=head2 searchTemplateDir

    The directory for search templates.  Generally, the "Search"
	subdirectory under systemTemplateDir. 

        This should only be used internally.

=cut

sub searchTemplateDir { 
	my $self = shift;
	my $tmpl_dir = $self->systemTemplateDir();
	return $tmpl_dir."Search/";
}


=head2 baseRenderDir 

        The directory for display templates.  The directory will
        returned will vary based on the number of items to be rendered
        - the "arity".  If one object is to be displayed, the
        templates will be found in "Display/One" under the
        systemTemplateDir. Otherwise, the templates will be found
        under "Display/Many".

        This should only be used internally.

=cut

sub baseRenderDir {
    my $self=shift;
    my $arity = shift;
    my $tmpl_dir  = $self->systemTemplateDir();
    $tmpl_dir .= "Display/";
    $tmpl_dir .= 'One/' if( uc( $arity ) eq 'ONE' );
    $tmpl_dir .= 'Many/' if( uc( $arity ) eq 'MANY' );
    return $tmpl_dir;
}


=head1 getActionTemplate

    my $template =
    OME::Web::TemplateManager->getActionTemplate($templateName)


    Get a template from the action directory, by file name.
=cut

sub getActionTemplate {
    my $self=shift;
    my ($tmpl_name) = @_;

    my $tmpl_dir = $self->actionTemplateDir();
    my $template = HTML::Template->new(
	filename => $tmpl_name,
	path => $tmpl_dir,
	case_sensitive => 1);
    return $template;
}


=head1 getActionTemplate

    Return the template used for indicating that the user does not
    have the priveleges to view the specified page.

=cut

sub getAccessDeniedTemplate() {
    my $self=shift;
    return $self->getActionTemplate('DenyAccess.tmpl');
}



=head2 getCreateTemplate
    used by DBObjCreate
=cut

sub getCreateTemplate {
    my $self = shift;
    my $type = shift;

    
    my $tmpl_dir = $self->createTemplateDir();
    return $self->getClassTemplate($tmpl_dir,$type,"create");
}


=head2 getBasicSearchTemplate

    retrieves the basic Search template, which contains most of the
    layout for general searching.

=cut 
sub getBasicSearchTemplate {
    my $self = shift;
    my $tmpl_dir = $self->searchTemplateDir();
    return HTML::Template->new(filename=>'Search.tmpl',
			       path=>$tmpl_dir,
			       case_sensitive=>1);

}
=head2 getSearchTemplate

     get the subtemplate used for class-specific search fields.

=cut

sub getClassSearchTemplate {
    my $self = shift;
    my $type = shift;
    my $tmpl_dir = $self->searchTemplateDir();
    return $self->getClassTemplate($tmpl_dir,$type,"search");
}

=head2  getSearchFieldTemplate

    Retrieves the template containing up and down arrows for sorting
    of search fields.

=cut
sub getSearchFieldTemplate {
    my $self = shift;
    my $tmpl_dir = $self->searchTemplateDir();
    return HTML::Template->new(filename=>'search_field.tmpl',
			       path=>$tmpl_dir,
			       case_sensitive=>1);
}


=head2 getTypePathFragment

    Class-specific templates for searching, creating, and rendering
    objects are found via a regularized path structure under
    /System/Search, System/Create, and System/Display,
    respectively. (There are some subtleties wtih respect to Display
    - see baseRenderDir).
    
    Under these directories, each type of object will have its own
    directory, containing appropriate template files. These
    directories will be named as follows:
    1) for STs, the directory will be named by the ST Name - without
    the leading ampersand.
    2) for OME:: subclasses, the directory structure will be named by
    breaking down the Perl object hierarchy and converting it into a
    directory path structure. Thus, "OME::Dataset" becomes
    "/OME/Dataset. "

    Given a type name, this procedure builds the path fragment needed
    to identify templates for the type.

=cut

sub getTypePathFragment {
    my $self=shift;
    my $type =shift;

    my ($package_name, $common_name, $formal_name, $ST) =
	$self->_loadTypeAndGetInfo( $type );
    my $tmpl_path = $formal_name; 
    $tmpl_path =~ s/@//g; 
    $tmpl_path =~ s/::/\//g; 
    return $tmpl_path;

}

=head2 getClassTemplate

    class specific templates for a given mode, where mode is "create"
    or "search". This procedure will find the appropriate
    class-specific type when available. If none is available, a
    generic template will be provided.

=cut

sub getClassTemplate {
    my $self=shift;
    my ($tmpl_dir,$type,$mode) =  @_;

    my $tmpl_path;
    if ($type) {
	$tmpl_path = $self->getTypePathFragment($type);
    }
    $tmpl_path = $tmpl_dir . $tmpl_path."/".$mode.".tmpl";
    if (!($tmpl_path && -e $tmpl_path)) {
	# no template found. use generic 
	$tmpl_path = $tmpl_dir. "/generic_".$mode.".tmpl";
    }
    return HTML::Template->new(filename=>$tmpl_path,path=>$tmpl_dir,
			       case_sensitive=>1);

}
    

=head2 getRenderingTemplate

    Similar to getClassTemplate, this procedure finds the appropraite
    rendering template for a given "mode" and "arity". In this case, 
    $mode refers to the type of rendering being used.

    As with getClassTemplate, a generic template will be returned if a
    class specific template is not available.


=cut
sub getRenderingTemplate {
    my $self=shift;
    my ($obj,$mode,$arity) = @_;

    my $tmpl_dir  = $self->baseRenderDir($arity);

    my $tmpl_path;
    if ($obj) {
	$tmpl_path = $self->getTypePathFragment($obj);
	$tmpl_path = $tmpl_dir . $tmpl_path . "/".$mode.".tmpl";
    }
    if (!($tmpl_path && -e $tmpl_path)) {
	# cant' find specific.
	$tmpl_path =$tmpl_dir . "/generic_".$mode.".tmpl";
    }
    return HTML::Template->new(filename=>$tmpl_path,path=>$tmpl_dir,
			       case_sensitive=>1);

}

=head2 getTemplatelist

    Some pages include an option for choosing the template to be used
    for viewing the object that is being displayed. Given type and an
    object count, this procedure wil identify the names of all of the
    templates (both generic and class specific) that can be used to
    view objects of that type.

=cut

sub getTemplateList {

    my ($self,$type,$arity) = @_;
    my %template_names;

    # Find generic templates
	my $generic_path = $self->baseRenderDir( $arity );
	opendir( DH, $generic_path );
	while( defined (my $file = readdir DH )) {
		if( $file =~ m/^generic_([^\.]+)\.tmpl$/ ) {
			$template_names{ $1 } = undef;
		}
	}
	closedir( DH);

	# Find specialized templates
	if( $type ) {
		#my $specializedPath =
		#$self->_specializedDisplayTemplateDir( $type, $arity
		#);
	        my $pathFragment = $self->getTypePathFragment($type);
		my $specializedPath = $generic_path . $pathFragment;
		print STDERR "specialized path is $specializedPath\n";
		if( $specializedPath ) {
			opendir( DH, $specializedPath );
			while( defined (my $file = readdir DH )) {
				if( $file =~ m/^([^\.]+)\.tmpl$/ ) {
					$template_names{ $1 } = undef;
				}
			}
			closedir( DH);
		}
	}

	# Return the list of unique templates available for this type.
	return sort( keys( %template_names ) );
}


=head2 getAnnotationTemplate

    Given a template name, retrieve and in object of type
    AnnotationTemplate  and return an instantiation of that template

=cut

sub getAnnotationTemplate {
    my ($self,$tmplName)  = @_;
    return $self->getTemplateFromST('@AnnotationTemplate',$tmplName);
}

=head2 getBrowseTemplate

    Given a template name, retrieve and in object of type
    BrowseTemplate  and return an instantiation of that template

=cut

sub getBrowseTemplate {
    my ($self,$tmplName)  = @_;
    return $self->getTemplateFromST('@BrowseTemplate',$tmplName);
}


=head2 getDisplayTemplate

    Given a template name, retrieve and in object of type
    DisplayeTemplate  and return an instantiation of that template

=cut

sub getDisplayTemplate {
    my ($self,$tmplName)  = @_;
    return $self->getTemplateFromST('@DisplayTemplate',$tmplName);
}

=head2 getTemplateFromST

    Given a type name and a template name, return the template of that
    type and name, and instantiate it.

=cut 
sub getTemplateFromST {
    my ($self,$st,$tmplName) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();

    return  $OME::Web::TemplateManager::NO_TEMPLATE
	unless ($tmplName);

    my $tmpl;
    my $tmpl_dir = $self->rootTemplateDir();
    my $tmplAttr = $factory->findObject($st,{Name=>$tmplName});
    if ($tmplAttr) {
	$tmpl = HTML::Template->new( filename => $tmplAttr->Template(),
				     path => $tmpl_dir,
				     case_sensitive => 1 );
    }
    return $tmpl;
}
    

=head2 getTemplatesByType
    
    Find all of the templates of type $st that have ObjectType $st.
=cut

sub getTemplatesByType {
    my ($self,$st,$type,$arity) = @_;
    
    my $session= $self->Session();
    my $factory = $session->Factory();

    my $hash;
    $hash->{ObjectType} = $type;
    $hash->{__order} = 'Name';
    $hash->{Arity} = $arity if ($arity);
    my @tmpls = $factory->findObjects($st,$hash);
    return \@tmpls;
}

=head2 getCategoryGroupAnnotationTemplates

    Find all of the AnnotationTemplate instances associated with
    CategoryGroup. 

=cut
sub getCategoryGroupAnnotationTemplates {
    my $self=shift;
    return $self->getTemplatesByType('@AnnotationTemplate','@CategoryGroup');
}

=head2 getCategoryGroupBrowseTemplates

    Find all of the BrowseTemplate instances associated with
    CategoryGroup. 

=cut

sub getCategoryGroupBrowseTemplates {
    my $self=shift;
    return $self->getTemplatesByType('@BrowseTemplate','@CategoryGroup');
}

=head2 getImageDisplayTemplates

    Find all of the DisplayTemplate instances associated with one
    OME::Image.

=cut

sub getImageDisplayTemplates {
    my $self = shift;
    return
    $self->getTemplatesByType('@DisplayTemplate','OME::Image','one');
}
1;
