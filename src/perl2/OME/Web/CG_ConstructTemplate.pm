# OME/Web/CG_ConstructTemplate.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
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
# Written by:    Arpun Nagaraja <arpun@mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Web::CG_ConstructTemplate;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Util::Dev::Templates;
use OME::Web::Search;

use base qw(OME::Web::Authenticated);

sub getPageTitle {
	return "OME: Select Category Groups";
}

{
	my $menu_text = "Select Category Groups to Display";
	sub getMenuText { return $menu_text }
}

sub getAuthenticatedTemplate {
    print STDERR "getting construct template\n";
    return OME::Web::TemplateManager->getActionTemplate('CG_ConstructTemplate.tmpl');
}

=head2 getLocation
=cut

sub getLocation {
	my $self = shift;
	my $template = OME::Web::TemplateManager->getLocationTemplate('CG_ConstructTemplate.tmpl');
	return $template->output();
}


sub getPageBody {
	my $self = shift ;
	my $tmpl = shift;
	my $q = $self->CGI() ;
	my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;
	
	my @construct_requests = $q->param( 'selected_objects' );

	# If the user selected "All", then @construct_requests will contain one entry
	# that is blank. In the lines below, we will expand that to all the CategoryGroups
	if( (scalar(@construct_requests) == 1 ) && ($construct_requests[0] eq '' ) ) {
		my @categoryGroups = $factory->findObjects( '@CategoryGroup' );
		@construct_requests = map( $_->id, @categoryGroups );
	}

	# Construct the object selection field if nothing has been selected
	if (scalar(@construct_requests) == 0) {
		$tmpl_data{ 'checkbox_and_cg' } = $self->SearchUtil()->getObjectSelectionField( 
			'@CategoryGroup', 'selected_objects', { list_length => 10 } );
	}
		
	# Create three new template files - annotate, browse, display
	else {
		my $templateName = $q->param( 'TemplateName' );
		my $filename = $templateName;
		
		# Effort to standardize the file names - remove ".tmpl" extension
		# if it exists (it will be added later) and replace all spaces and 
		# nasty charachers with _
		$filename =~ s/\.tmpl$//;
		$filename =~ s/[ !@#$%^&*()<>?;:'"\/\\|`~=+]/_/g;

		my $module = $factory->findObject( 'OME::Module', name => 'Global import' )
			or die "couldn't load Global import module";
		my $mex = OME::Tasks::ModuleExecutionManager->createMEX($module,'G' )
			or die "Couldn't get mex for Global import";
			
		# Put mex ID on the end of the filename to ensure a unique file
		$filename .= "_".$mex->id;
		my $tmpl_dir = OME::Web::TemplateManager->localTemplateDir();
	#	my $annotator_path = "$tmpl_dir"."/Actions/Annotator/CategoryGroup/$filename.tmpl";
		#my $browse_path = "$tmpl_dir"."/Browse/CategoryGroup/$filename.tmpl";
		#my $display_path = "$tmpl_dir"."/Display/One/OME/Image/$filename.tmpl";

		my $annotator_name = "Actions/Annotator/CategoryGroup/$filename.tmpl";
		my $browse_name = "Browse/CategoryGroup/$filename.tmpl";
		my $display_name =
		"Display/One/OME/Image/$filename.tmpl";
		my $annotator_path = $tmpl_dir."/".$annotator_name;
		my $browse_path = $tmpl_dir."/".$browse_name;
		my $display_path = $tmpl_dir."/".$display_name;
		# WARNING TO TELL USER OF A NAME COLLISION
		
		my %annotator_data_hash = (
			Name       => $templateName,
#			Arity      => $arity,
			ObjectType => '@CategoryGroup',
			Template   => $annotator_name,
			ImplementedBy => "CG_Annotator.pm"
		);
		
		my %browse_data_hash = (
			Name       => $templateName,
#			Arity      => $arity,
			ObjectType => '@CategoryGroup',
			Template   => $browse_name,
			ImplementedBy => "CG_Browse.pm"
		);
		
		my %display_data_hash = (
			Name       => $templateName,
			Arity      => "one",
			Mode       => "ref",
			ObjectType => 'OME::Image',
			Template   => $display_name
		);
		
		# Make this file an attribute of the ST AnnotationTemplate
		my $new_tmpl = $factory->newAttribute( "AnnotationTemplate", undef, $mex, \%annotator_data_hash ) 
			or die "Couldn't make a new AnnotationTemplate for $annotator_path";
		my $id = $new_tmpl->id;

		open (TMPL, "> $annotator_path") or die "Couldn't open template $annotator_path: $!\n";
		print TMPL "<input type=\"hidden\" name=\"images_to_annotate\" value=\"<TMPL_VAR NAME=image_id_list>\">
<input type=\"hidden\" name=\"currentImageID\" value=\"<TMPL_VAR NAME=current_image_id>\">
<input type=\"hidden\" name=\"SaveAndNext\">
<input type=\"hidden\" name=\"AddToCG\"><br>
<TMPL_VAR NAME=current_image/render-large><br>
<table class=\"ome_table\">\n";
		
		# Print the line that lists the ids that will be loaded
		my $concatenated_ids = join(",", @construct_requests);
		print TMPL "<TMPL_VAR NAME=\"CategoryGroup.load/id-[$concatenated_ids]\">\n";
		
		# Get the name for each ID, so the user knows which ID is associated
		# with which name
		my @comments;
		foreach my $req (@construct_requests) {
			my $cg = $factory->findObject( '@CategoryGroup', { id => $req } );
			my $name = $cg->Name;
			push (@comments, "$req=$name");
		}
		my $concatenated_comments = join(",", @comments);
		print TMPL "<!-- $concatenated_comments -->\n";
		print TMPL "<a href = \"javascript:selectMany('OME::Image', 'images_to_annotate');\"><br>Search for images to annotate</a><br><br>
<tr>
	<td class=\"ome_td\"><center>CategoryGroup</center></td>
	<td class=\"ome_td\"><center>Categories</center></td>
	<td class=\"ome_td\"><center>Add New Category</center></td>
	<td class=\"ome_td\"><center>Info</center></td>
</tr>
<TMPL_LOOP NAME=cg.loop>
	<tr>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg.Name></td>
		<td class=\"ome_td\" align=\"left\"><SELECT name=\"FromCG<TMPL_VAR NAME='cg.id'>\"><OPTION value=\"\">Do Not Annotate</option><TMPL_VAR NAME=cg.cat/render-list_of_options></select></td>
		<td class=\"ome_td\" align=\"left\"><input type=\"text\" size=\"15\" name=\"CategoryAddTo<TMPL_VAR NAME='cg.id'>\" alt=\"blank\"></td>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg.classification></td>
	</tr>
</TMPL_LOOP>
</table>
<input type=\"button\" value='Add Categories' onclick=\"javascript: document.forms[0].AddToCG.value='AddToCG'; document.forms[0].submit();\">
<input type=\"button\" value='Save & Next' onclick=\"javascript: document.forms[0].SaveAndNext.value='SaveAndNext'; document.forms[0].submit();\"><br><br>
Images left to annotate:<br>
<TMPL_VAR NAME=image_thumbs><br>";
		close TMPL;
		$session->commitTransaction();
		
		# Now create the Browse template attribute
		$factory->newAttribute( "BrowseTemplate", undef, $mex, \%browse_data_hash ) 
			or die "Couldn't make a new BrowseTemplate for $browse_path";
		
		open (TMPL, "> $browse_path") or die "Couldn't open template $browse_path: $!\n";
		print TMPL "<input type=\"hidden\" name=\"GetThumbs\">
<input type=\"hidden\" name=\"queryMGI\">
<TMPL_VAR NAME=\"CategoryGroup.load/id-[$concatenated_ids]\">
<!-- $concatenated_comments -->

<table>
<tr>
	<TMPL_LOOP NAME=cg.loop>
		<td align=\"left\">
			<center><TMPL_VAR NAME=cg.Name></center>
			<SELECT name=\"FromCG<TMPL_VAR NAME='cg.id'>\" onclick=\"javascript: document.forms[0].GetThumbs.value='GetThumbs'; document.forms[0].submit();\" size = \"30\">
			<TMPL_VAR NAME=cg.cat/render-list_of_options></SELECT><br>
		</td>
	</TMPL_LOOP>
	<td valign=\"top\">
		<TMPL_VAR NAME=image_thumbs><br>
		<!-- fix this, it's just a hack -->
		<a href = \"\" class=\"ome_widget\">Deselect All</a>
	</td>
</tr>
</table>";
		$session->commitTransaction();
		close TMPL;
		
		# Make Display template attribute
		$factory->newAttribute( "DisplayTemplate", undef, $mex, \%display_data_hash ) 
			or die "Couldn't make a new DisplayTemplate attribute for $display_path";
		
		open (TMPL, "> $display_path") or die "Couldn't open template $display_path: $!\n";
		print TMPL "<TMPL_VAR NAME=image/render-large>\n";
		print TMPL "<TMPL_VAR NAME=\"CategoryGroup.load/id-[$concatenated_ids]\">
<!-- $concatenated_comments -->\n";
		print TMPL "<table class=\"ome_table\">
	<tr>
		<td class=\"ome_td\" align=\"left\"><center>CategoryGroup</td>
		<td class=\"ome_td\" align=\"left\"><center>Category</td>
	</tr>
<TMPL_LOOP NAME=cg.loop>
	<tr>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg/render-ref></td>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg.cat/render-ref></td>
	</tr>
</TMPL_LOOP>
<!--
	<tr>
		<td class=\"ome_td\" align=\"left\"><center>CategoryGroup</td>
		<td class=\"ome_td\" align=\"left\"><center>Category</td>
	</tr>
	<tr>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[1]/render-ref></td>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[1].cat/render-ref></td>
	</tr>
	<tr>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[2]/render-ref></td>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[2].cat/render-ref></td>
	</tr>
	<tr>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[3]/render-ref></td>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[3].cat/render-ref></td>
		<td class=\"ome_td\" align=\"left\"></td>
	</tr>
	<tr>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[4]/render-ref></td>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg[4].cat/render-ref></td>	
		<td class=\"ome_td\" align=\"left\"></td>
	</tr> -->
</table>";
		close TMPL;
		
		$mex->status( 'FINISHED' );
		$mex->storeObject();
		$session->commitTransaction();
		
		# Change this to redirect to the page the user came from?
		return ('REDIRECT',$self->pageURL("OME::Web::CG_Annotator&Template=$templateName"));
	}
	
	
	# Load & populate the template
	$tmpl->param( %tmpl_data );

	my $html =
		$q->startform( { -name => 'primary' } ).
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);

}

1;
