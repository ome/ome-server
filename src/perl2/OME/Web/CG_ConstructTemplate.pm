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
use OME::Util::Templates;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: Select Category Groups";
}

{
	my $menu_text = "Select Category Groups to Display";
	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift ;
	my $q = $self->CGI() ;
	my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;
    my $debug;
	
	
	my @construct_requests = $q->param( 'selected_objects' );
	# $debug .= join("<br>", @construct_requests)."<br>";
	my @categoryGroups = $factory->findObjects ('@CategoryGroup', __order => 'Name');
	
	my $tmpl_dir = $self->actionTemplateDir();
	
	if (scalar(@construct_requests) == 0) {
		$tmpl_data{ 'checkbox_and_cg' } = $self->Renderer()->renderArray(\@categoryGroups, 'Checkboxes_and_Object');
	}
		
	# Create three new template files - annotate, browse, display
	else {
		my $templateName = $q->param( 'TemplateName' );
		my $filename = $templateName;
		$filename =~ s/\.tmpl$//;
		$filename =~ s/ /_/g;

		# Make this file an attribute of the ST AnnotationTemplate
		my $module = $factory->findObject( 'OME::Module', name => 'Global import' )
			or die "couldn't load Global import module";
		my $mex = OME::Tasks::ModuleExecutionManager->createMEX($module,'G' )
			or die "Couldn't get mex for Global import";
			
		# Put mex ID on the end of the filename to ensure a unique file
		$filename .= "_".$mex->id;
		my $tmpl_dir = $self->actionTemplateDir();
		my $annotator_path = "$tmpl_dir"."Annotator/CategoryGroup/$filename.tmpl";
		my $browse_path = "$tmpl_dir"."../Browse/CategoryGroup/$filename.tmpl";
		my $display_path = "$tmpl_dir"."../Display/One/OME/Image/$filename.tmpl";
		
		# WARNING TO TELL USER OF A NAME COLLISION
		
		my %annotator_data_hash = (
			Name       => $templateName,
#			Arity      => $arity,
			ObjectType => '@CategoryGroup',
			Template   => $annotator_path,
#			ImplementedBy => ?
		);
		
		my %browse_data_hash = (
			Name       => $templateName,
#			Arity      => $arity,
			ObjectType => '@CategoryGroup',
			Template   => $browse_path,
#			ImplementedBy => ?
		);
		
		my %display_data_hash = (
			Name       => $templateName,
			Arity      => "one",
			Mode       => "ref",
			ObjectType => 'OME::Image',
			Template   => $display_path
		);
		
		my $new_tmpl = $factory->newAttribute( "AnnotationTemplate", undef, $mex, \%annotator_data_hash ) 
			or die "Couldn't make a new AnnotationTemplate for $annotator_path";
		my $id = $new_tmpl->id;

		open (TMPL, "> $annotator_path") or die "Couldn't open template $annotator_path: $!\n";
		print TMPL "<input type=\"hidden\" name=\"images_to_annotate\" value=\"<TMPL_VAR NAME=image_id_list>\">
<input type=\"hidden\" name=\"currentImageID\" value=\"<TMPL_VAR NAME=current_image_id>\">
<input type=\"hidden\" name=\"SaveAndNext\">
<input type=\"hidden\" name=\"AddToCG\">
<TMPL_VAR NAME=image_large><br>
<table class=\"ome_table\">\n";
		my $concatenated_ids = join(",", @construct_requests);
		print TMPL "<TMPL_VAR NAME=\"CategoryGroup.load/id-[$concatenated_ids]\">\n";
		my @comments;
		foreach my $req (@construct_requests) {
			my $cg = $factory->findObject( '@CategoryGroup', { id => $req } );
			my $name = $cg->Name;
			push (@comments, "$req=$name");
		}
		my $concatenated_comments = join(",", @comments);
		print TMPL "<!-- $concatenated_comments -->\n";
		print TMPL "<a href = \"javascript:selectMany('OME::Image', 'images_to_annotate');\" class=\"ome_widget\">Search for images to annotate</a><br>
<tr>
	<td class=\"ome_td\"><center>CategoryGroup</center></td>
	<td class=\"ome_td\"><center>Categories</center></td>
	<td class=\"ome_td\"><center>Add New Category</center></td>
</tr>
<TMPL_LOOP NAME=cg.loop>
	<tr>
		<td class=\"ome_td\" align=\"left\"><TMPL_VAR NAME=cg.Name></td>
		<td class=\"ome_td\" align=\"left\"><SELECT name=\"FromCG<TMPL_VAR NAME='cg.id'>\"><OPTION value=\"\">Do Not Annotate</option><TMPL_VAR NAME=cg.rendered_cats></select></td>
		<td class=\"ome_td\" align=\"left\"><input type=\"text\" size=\"15\" name=\"CategoryAddTo<TMPL_VAR NAME='cg.id'>\" alt=\"blank\"></td>
	</tr>
</TMPL_LOOP>
</table>
<input type=\"button\" value='Add Categories' onclick=\"javascript: document.forms[0].AddToCG.value='AddToCG'; document.forms[0].submit();\">
<input type=\"button\" value='Save & Next' onclick=\"javascript: document.forms[0].SaveAndNext.value='SaveAndNext'; document.forms[0].submit();\"><br><br>
Images left to annotate:<br>
<TMPL_VAR NAME=image_thumbs><br>";
		close TMPL;
		$session->commitTransaction();
		
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
			<TMPL_VAR NAME=cg.rendered_cats></SELECT><br>
		</td>
	</TMPL_LOOP>
	<td valign=\"top\">
		<TMPL_VAR NAME=image_thumbs><br>
		<!-- fix this, it's just a hack -->
		<a href = \"\" class=\"ome_widget\">Deselect All</a>
	</td>
</tr>
</table>

<!--table>
	<tr>
		<td valign=\"top\">
			<center><TMPL_VAR NAME=cg[1].Name><br>
			<SELECT name=\"FromCG<TMPL_VAR NAME='cg[1].id'>\" onclick=\"javascript: document.forms[0].GetThumbs.value='GetThumbs'; document.forms[0].submit();\" size = \"30\">
			<TMPL_VAR NAME=cg[1].rendered_cats></SELECT><br>
		</td>
		<td valign=\"top\">
			<table>
				<tr>
					<td>
						<table>
							<tr>
								<td>
									<center><TMPL_VAR NAME=cg[2].Name><br>
									<SELECT name=\"FromCG<TMPL_VAR NAME='cg[2].id'>\" onclick=\"javascript: document.forms[0].GetThumbs.value='GetThumbs'; document.forms[0].submit();\" size = \"8\">
									<TMPL_VAR NAME=cg[2].rendered_cats></SELECT><br>
								</td>
								<td>
									<center><TMPL_VAR NAME=cg[3].Name><br>
									<SELECT name=\"FromCG<TMPL_VAR NAME='cg[3].id'>\" onclick=\"javascript: document.forms[0].GetThumbs.value='GetThumbs'; document.forms[0].submit();\" size = \"8\">
									<TMPL_VAR NAME=cg[3].rendered_cats></SELECT><br>
								</td>
								<td>
									<center><TMPL_VAR NAME=cg[4].Name><br>
									<SELECT name=\"FromCG<TMPL_VAR NAME='cg[4].id'>\" onclick=\"javascript: document.forms[0].GetThumbs.value='GetThumbs'; document.forms[0].submit();\" size = \"8\">
									<TMPL_VAR NAME=cg[4].rendered_cats></SELECT><br>
								</td>
								<td valign=\"top\">
									<!-- fix this, it's just a hack -->
									<a href = \"\" class=\"ome_widget\">Deselect All</a>
								</td>
							</tr>
						</table>
					</td>
				</tr>
				<tr><td><TMPL_VAR NAME=image_thumbs></td></tr>
			</table>
			
		</td>
	</tr>
</table-->";
		$session->commitTransaction();
		close TMPL;
		
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
		return ('REDIRECT',$self->pageURL("OME::Web::CG_Annotator&Template=$id"));
	}
	
	
	# Load & populate the template
	my $tmpl = HTML::Template->new( filename => "CG_ConstructTemplate.tmpl",
									path => $tmpl_dir,
	                                case_sensitive => 1 );
	$tmpl->param( %tmpl_data );

	my $html =
		$debug.
		$q->startform().
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);

}

1;