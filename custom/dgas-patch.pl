#!/usr/bin/perl
# A patch script to modify an existing OME configuration to run in the
# dgas model - guest access, table viewer, etc.

#-------------------------------------------------------------------------------
#
# Copyright (C) 2006 Open Microscopy Environment
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

=head1 NAME

dgas-patch.pl: A script for patching an OME installation to provide
    the image table functionality developed for Minoru Ko's
    Developmental Genetics and Aging Section

=head1 DESCRIPTION

    Minoru Ko's group has a need for viewing mouse embryo images in a
    2-dimensional grid, with genes and probes on one axis and embryo
    stage in another (see Yoshikawa, et al., Gene Expression Patterns
    6(2), January 2006 for examples). This functionality requires
    several extensions to the core OME code, including new data types
    and instances, and  OME::Web subclasses (with related templates)
    for web displays and image annotation support. Furthermore, a
    working installation requires populated data - both images and
    annotations in the form of appropriate semantic types.

    Much of the code that provides this functionality is silently
    present in the OME distribution: without any configuration, this
    code will be ignored. This script - dgas-patch.pl - builds upon
    this basis, configuring the system to provide the data types,
    images, and annotations necessary for a complete installation.

    Installations of this sort often are likely to require
    site-specific customizations. These notes will describe what the
    current script does, where it is tied to site-specific needs, and
    how it might be generalized to other cases.

    After some configuration bookkeeping - getting some appropriate
    user ids, deleting any ".omelogin" files, and verifying that the
    script is being run as root, this script gets down to its main
    work.

    PATCHING OME::Web::Access::Manager  OME::Web::AccessManager is the
    class that is used to identify the files that are used to
    construct the page header and menu.  The patch creates a backup
    copy of this file and replaces "OME::Web::GuestHeaderBuilder" -
    the generic guest header - with
    "OME::Web::TableBrowse::HeaderBuilder", a special purpose
    header. Similarly, the GuestMenuBuilder reference is modified to
    be undefined, guaranteeing that guest users will not have a menu. 

    Possible site-specific customizations of this code can take one of
    two forms:  1) The contents of OME::Web::TableBrowse::
    HeaderBuilder can be revised to provide a revised header, or 2)
    a new version of HeaderBuilder can be created in a new file, and
    the code in this script revised to point to this new file instead.

    A backup copy of the original AccessManager.pm is saved as
    AccessManager.pm.bak.

    COPYING HEADER IMAGES;  The page header created by
    OME::Web::TableBrowse::HeaderBuilder includes two images -
    nia1.jpg and nih1.jpg - that are found in the /custom directory
    along with this script. These files are copied to the /images
    subdirectory of the OME distribution, thus ensuring their
    availability for the header.

    Changes to the names of files copied should be coordinated with
    any changes to the guest header files specified in AccessManager.pm.
        
    PATCHING OME::Web::Home: By default, the OME web page is available
    to both authenticated and guest users. This patch modifies Home.pm
    to make it a subclass of OME::Web::Authenticated, instead of
    OME::Web. As a result, subsequent requests to Home.pm will fail
    unless they are accompanied by an authenticated login.
    
    This functionality can be modified or simply commented out as
    necessary.

    A NOTE ON USER IDS: Up until this point, the script must run as
    root. Subseqeuent changes must be run as the OME_USER as stored in
    the environment. Without this change, the login code will attempt
    to connect to the database as 'root', which is probably not what
    is desired. Modifying the user id to that of the OME_USER will
    lead to database login with the appropriate non-root user.

    ENABLING GUEST ACCESS: The tabular displays of image data are
    intended for use by non-authenticated guest users. Modifying the
    configuration to enable guest access will turn on this
    functionality. This code should probably not be modified.
    
    CONFIGURING TEMPLATES: Instances of the BrowseTemplate,
    DisplayTemplate, and AnnotationTemplate types are used to provide
    the layout of the viewing and annotation displays. All of the
    appropriate template files are included in the distribution: code
    in this script creates the semantic type instances that point to
    these files for future use.

    Any of the basic template files referred to in the script below
    can be modified as need be to support alternative
    layouts. However, these changes must be made carefully: any
    modifications to the template variables may break the code that is
    found in ImageAnnotationTable, ImageDetailAnnotator,
    GeneStageAnnotator, or ImageAnnotationDetail. A safer approach
    might be to copy the template files specified in this script and
    to modify this script to point to the modified copies.\
    
    In any case, the Name fields for the BrowseTemplate and
    DisplayTemplate instances must contain the same value. In the
    current code, this value is 'GeneProbeTable'. If this name is
    changed for one template, it must be changed for both.  This name
    synchronization is needed to guarantee that thumbnails in the
    table display provide access to the appropriate corresponding
    detail display.

    No such requirement exists for the AnnotationTemplate.

    IMPORTING TYPE DEFS:  The file
    "src/xml/OME/Annotations/MouseAnnotations.ome" contains XML
    definitions of several semantic types (along with instances of
    those types) that are used to support the tabular display. This
    file is imported using OME's XML import facilities.

    Site-specific modifications might involve alternative type
    structures and details. The best approach to such changes will
    likely involve creating a new .xml file with the appropriate
    definitions and modifying this script to import that file.
    
    IMPORTING IMAGES: Obviously, some images must be imported to
    populate the database. The image import code in this script grabs
    all of the ".tif" files from /Images/yong/Blastocyst", the
    directory used by Ko's group. Customizations of this script should
    change the directory and possibly the underlying logic of the
    image import code.

    IMPORTING ASSOCIATIONS:  Image annotations that form the basis for
    the tabular display are given in the dgas.xls spreadsheet that is
    found in the /custom directory alongside this script. 

    This spreadsheet contains annotations in 5 columns;
    1) Image name. This name corresponds to the name given on import
    i.e, the filename without the .tif extension
    2) the name of a gene
    3) the name of a probe
    4) an embryo stage
    5) a probe type.

    The code for importing associations will read this spreadsheet,
    using the rows to create appropriate instances of types such as
    Gene, Probe, Embryostage, and ProbeType, along with instances of
    linking type such as ProbeGene, ImageProbe, and ImageEmbryoStage.

    Importing of spreadsheet associations will also create appropriate
    links to the NIA Mouse gene index. Specificlly, we assume that the gene
    name is the key for the MGI, and we create an ExternalLinkTemplate
    with the base pattern for the MGI. Appropriate ExternalLink and
    GeneExternalLink instances are then created for each gene.

    The name of the spreadsheet, its contents, and the logic used to
    create the types and associations, should be modified to meet
    site-specific needs.

=cut

#*********
#********* INCLUDES
#*********

use warnings;
use strict;
use Getopt::Long;
use FindBin;
use File::Spec::Functions qw(catdir catfile splitpath);
use lib catdir ($FindBin::Bin,'src','perl2');
use Carp;
use Text::Wrap;
use Data::Dumper;
use English;
use Spreadsheet::ParseExcel;


use OME::SessionManager;
use OME::Factory;
use OME::Tasks::ImageTasks;
use OME::Tasks::DatasetManager;
use OME::Tasks::ModuleExecutionManager;
use OME::Install::Environment;
use OME::Install::Util;

# configuration values
my $IMAGE_DIR="/Images/yong/Blastocyst/";

# mgi template
my   $MGI_TEMPLATE_PATTERN = 
    "http://lgsun.grc.nia.nih.gov/geneindex5/bin/giU.cgi?search_term=~ID~";

=head2 verifyEnvironment

    The patch script must be executed as root. This procedure will
    verify that it is running as root and exit (with a warning) if
    not.

=cut 
sub verifyEnvironment() {
    
    # verify that we're running as root. barf if not.
    # Set the cwd to wherever we ran the script from
    chdir ($FindBin::Bin);

    # Root check
   usage (<<ERROR) unless $EUID == 0;

The patch must be run as the root user:
> sudo perl dgas-patch.pl
    *** Enter your password when asked ***
Or, if you can't run sudo:
> su
    *** Enter the root user's password when asked
> perl dgas-patch.pl
ERROR

# The patch cannot be run from a directory owned by root
usage (<<ERROR) if (stat ('.'))[4] == 0;
The patch cannot be run from a directory owned by root.
Please download and unpack the OME distribution as a regular user,
in a regular home directory.  Run the installer as root, and then
run the patch as root.
ERROR

}

=head2 usage

   Notes on running this program.

=cut

sub usage {

    my $error = shift;
    my $usage = "";

    $usage = <<USAGE;
OME DGAS  patch script. Configures an existing OME installation to run the DGAS 
image annotation tables.

Usage:
  $0 [options]

Options:

Report bugs to <ome-devel\@lists.openmicroscopy.org.uk>.

USAGE
    $usage .= "**** ERROR: $error\n\n" if $error; 

    print STDERR $usage;
    exit (1) if $error;
    exit (0);
}


=head2 cleanupLoginFile
    
    remove /.omelogin from the current home directory.
=cut

sub cleanupLoginFile { 
    #  kill the login file, hiding any complaints.
    my $homeDir = $ENV{"HOME"} || ".";
    my $loginFile = "$homeDir/.omelogin";
    system("rm $loginFile > /dev/null 2>&1");

}

=head2 enableGuestAccess

    Modify the configuration to turn on guest access
=cut
sub enableGuestAccess() {
    my $factory = shift;
    my $var = $factory->findObject('OME::Configuration::Variable',
				   configuration_id=>1,
				   name=>'allow_guest_access');
    
    if (!$var) {
	croak "Configuration for  guest access cannot be found. Please re-run the installation script.\n";
    }

    $var->value(1);
    $var->storeObject();

    $factory->commitTransaction();
}

=head2  patchAccessManager

    In OME::Web::AccessManager, all instances of
    OME::Web::GuestHeaderBuilder must be converted to
    OME::Web::TableBrowse::HeaderBuilder.pm, 
    and we must make getMenuBuilder return null; instead of
    OME::Web::GuestMenuBuilder...

    These values can be changed to point to different
    files if necessary, or the contents of thes HeaderBuilder file
    might be customized.
=cut


sub patchAccessManager() {

    my $webPath = catdir($FindBin::Bin,'..','src','perl2','OME','Web');
    my $amFile = catfile($webPath,'AccessManager.pm');
    my $bakName = "AccessManager.pm.bak";
    my $bakFile = catfile($webPath,$bakName);

    # copy amFile to bakfile
    system("cp $amFile $bakFile");

    # remove amfile
    system("rm $amFile");

    # open am file for writing, bakfile for reading
    open SRC, "<$bakFile";
    open DEST, ">$amFile";
    # iterate and do changes.
    while (<SRC>) {
	if (/use base.*/) {
	    # add code for the footer builder
	    print DEST "use OME::Web::TableBrowse::FooterBuilder;\n";
	}
	else {
	    s/OME::Web::GuestHeaderBuilder/OME::Web::TableBrowse::HeaderBuilder/g;
	    s/new OME::Web::GuestMenuBuilder\(\$page\)/undef/g;
	    s/my \$FOOTER_FILE=undef/my  \$FOOTER_FILE=\'OME::Web::TableBrowse::FooterBuilder\'/;
	}
	print DEST $_;
    }
    close SRC;
    close DEST;
}

=head2 patchHome
    
    Adjust the Home.pm file to use OME::Web::Authenticated as a base,
    instead of OME::Web. This makes the home page incaccessible to
    unauthenticated users.

=cut

sub patchHome() {

    my $webPath = catdir($FindBin::Bin,'..','src','perl2','OME','Web');
    my $homeFile = catfile($webPath,'Home.pm');
    my $bakName = "Home.pm.bak";
    my $bakFile = catfile($webPath,$bakName);

    # copy amFile to bakfile
    system("cp $homeFile $bakFile");

    # remove amfile
    system("rm $homeFile");

    # open am file for writing, bakfile for reading
    open SRC, "<$bakFile";
    open DEST, ">$homeFile";
    # iterate and do changes.- change "use base qw(OME::Web)" 
    # to OME::Web::Authenticated
    while (<SRC>) {
	s/use base qw\(OME::Web\)/use base qw\(OME::Web::Authenticated\)/g;
	print DEST $_;
    }
    close SRC;
    close DEST;
}

=head2 copyHeaderImages

    copy all of the .jpg files from this directory to ../images - the
    images directory in the main OME installation. This code can be
    changed to refer to sepcific files or different file types, as
    necessary.

    
=cut
sub copyHeaderImages() {
    
    my $imagePath = catdir($FindBin::Bin,'..','images');
    system("cp *.jpg $imagePath");
    system("cp *.gif $imagePath");
}

=head2 importTypeDefs

    Importing the specific types and instances necessary for the given
    data model. The file /src/xml/OME/Annotations/MouseAnnotations.ome
    is imported, using the OME import mechanism.
 
    In order to avoid redundant importation of the contents of this
    file, this procedure starts by checking to see if the Semantic
    Type EmbryoStage exists. If this type is found, the file is not
    reimported.

    Site-specific modifications should involve creation of a new XML
    file and revision to this procedure to point to the new file and
    to use an appropriate SemanticType as a sentinel for avoiding
    redundant importation.

=cut
sub importTypeDefs() {

    my $factory = shift;

    # first, check to see if we have embryo stage st.
    my $embryoStageST = $factory->findObject('OME::SemanticType',
           {name=>'EmbryoStage'});
    if (!$embryoStageST) {
	my $xmlPath =
	    catdir($FindBin::Bin,'..','src','xml','OME','Annotations');
	my $stFile = catfile($xmlPath,'MouseAnnotations.ome');
	my @fileNames = ( $stFile);
	
	
	my $results = OME::Tasks::ImageTasks::importFiles(undef,\@fileNames);
    }
}

=head2 configureTemplates
    
    Create instances of BrowseTemplate, DisplayTemplate, and
    AnnotationTemplate to refer to the appropriate template files for
    the table display. 

    Note that these instances are created with a MEX that has an
    undefined group. This gurantees that the resulting objects will be
    visible to all users - ACL rules will not apply. 

    Custom installations can revise the template files, or change this
    code to point to different template files, as needed.

=cut
sub configureTemplates() {
    my $factory = shift;

    # background - mex, etc.

    my $module = $factory->findObject('OME::Module',
		     name=>'Global import')
	or die "cannot load global import module \n";
    my $mex = OME::Tasks::ModuleExecutionManager->
	createMEX($module,'G',undef,undef,undef,0,undef)
	or die "Failed to create MEX\n ";

    #create a browse template
    my $browseST = $factory->findObject('OME::SemanticType',{name=>'BrowseTemplate'});
    my $browse = $factory->maybeNewAttribute($browseST,undef,$mex,
      {Name =>'GeneProbeTable',Template=>'Browse/GeneProbeTable.tmpl' });
    

    # create a display template.
    my $displayST = $factory->findObject('OME::SemanticType',
					 {name=>'DisplayTemplate'});
    # note that the name of this template must be the same as the name
    # for the BrowseTemplate instance that was just created. 
    my $display = $factory->maybeNewAttribute($displayST,undef,$mex,
      {Name =>'GeneProbeTable',
       Template=>'Display/One/OME/Image/GeneProbeTable.tmpl',
       ObjectType=>'OME::Image',
       Arity=>'one',
       Mode=>'ref'});

    # create an annotation template
    my $annotationST = $factory->findObject('OME::SemanticType',
					 {name=>'AnnotationTemplate'});
    my $annotation = $factory->maybeNewAttribute($annotationST,undef,$mex,
      {Name => 'MouseAnnotations',
       Template=>'/Actions/Annotator/ProbeStage.tmpl'});
   

}


=head2 importImages

    Import the .tif images found in $IMAGE_DIR. This value is set to 
    /Images/yong/Blastocyst by default, but can be modified as needed.

    Before importing the images, this code looks to see if they are in
    the database. Any images that have already been loaded are
    skipped.

    The group of the current user must be set to be null before this
    procedure is called. This modification will cause the MEXs created
    by OME::Tasks::ImageTasks::importFiles to have a null group,
    making associate objects visible to all users.

    Although the user group has been set to null, the dataset for
    these images must be created with a non-null group (creation will
    fail if the group is null). This group must be passed in from
    the caller. 

=cut
sub importImages() {

    my ($factory,$group) = @_;
    my $imagePath = $IMAGE_DIR;
    open DIR, "ls $imagePath/*.tif | ";
    my @imageFiles;
    while (<DIR>) {
	chop;
	push @imageFiles,$_;
    }

    my @imagesToImport;
    foreach my $image (@imageFiles) {
	my ($volume,$directories,$file) = splitpath($image);
	$file =~ /(.*).tif/;
	my $dbImg = $factory->findObject('OME::Image',
			 name=>$1);

	# add it to list if not found
	push  (@imagesToImport,$image) unless ($dbImg);
    }

    print "Importing " . scalar(@imagesToImport) . " images. \n";

    my $datasetManager = new OME::Tasks::DatasetManager;
    my $dataset = $datasetManager->newDataset('DGAS data','DGAS',undef,$group->id(),
					      undef);						 
    my $results = OME::Tasks::ImageTasks::importFiles($dataset,
						      \@imagesToImport);
}

=head2 importAssocations

  Importing annotations from the "dgas.xls" annotation spreadsheet.

    As described above, this file contains 5 columns: image name,
    gene, probe, embryo stage, and probe type. 

   This procedure will load appropriate types, read the spreadsheet,
    create appropriate type instances, and store the results in the
    database.   Specific descriptions are given within the code. 

    Customizations of this code will require providing an appropriate
    spreadsheet (and referring to it), and modifying the procedue to
    instantiat the    appropriate types.
=cut
sub importAssociations() {

    my ($factory,$session) = @_;

    # load up STS

    my $geneST = $factory->findObject('OME::SemanticType', {name=>'Gene'});
    my $probeST = $factory->findObject('OME::SemanticType', {name=>'Probe'});

    my $pgST = $factory->findObject('OME::SemanticType',{name=>'ProbeGene'});

    my $ipST = $factory->findObject('OME::SemanticType',{name=>'ImageProbe'});
    my $esST = $factory->findObject('OME::SemanticType',
				    {name=>'EmbryoStage'});

    my $imageEsST = $factory->findObject('OME::SemanticType',
				      {name=>'ImageEmbryoStage'});

    my $probeTypeST = $factory->findObject('OME::SemanticType',
				      {name=>'ProbeType'});

    my $pubStatusST = $factory->findObject('OME::SemanticType',
				      {name=>'PublicationStatus'});

    my $extLinkST = $factory->findObject('OME::SemanticType',
					 {name =>'ExternalLink'});

    my $extLinkTemplateST = $factory->findObject('OME::SemanticType',
					 {name =>'ExternalLinkTemplate'});

    my $geneLinkMapST = $factory->findObject('OME::SemanticType',
					    {name => 'GeneExternalLink'});
    # load a module and create a mex.
    my $global_module = $factory->findObject('OME::Module',
		     name=>'Spreadsheet Global import')
	or die "cannot load spreadsheet module \n";
    my $mex = OME::Tasks::ModuleExecutionManager->
	createMEX($global_module,'G',undef,undef,undef,0,undef)
	or die "Failed to create MEX\n ";
   
    #create the new template
    my $extLinkTemplate = 
	$factory->maybeNewAttribute($extLinkTemplateST,undef,$mex,
				    {Name=>"MGI",
				    Template=>$MGI_TEMPLATE_PATTERN});
    $extLinkTemplate->storeObject();
				
						      
    

    # open the spreadsheet and read meatadata.
    my $spreadSheetFile = "dgas.xls";
    my $excel = new Spreadsheet::ParseExcel;
    my $workbook = $excel->Parse($spreadSheetFile);
    my $sheet = $workbook->{Worksheet}[0];
    my $maxRow = $sheet->{MaxRow};


    # for each row.
    for (my $row = 1, my $rowNum=2; $row <=$maxRow; $row++,$rowNum++) {
	my $rowImageCell = $sheet->{Cells}[$row][0];

	# identify the image
	my $rowImage = &getCellValue($sheet,$row,0,"Image");

	# identify the gene
	my $rowGene = &getCellValue($sheet,$row,1,"Gene");
	
        # identify the probe
	my $rowProbe  = &getCellValue($sheet,$row,2,"Probe");

        # identify the embryoStage
	my $rowEmbryoStage = &getCellValue($sheet,$row,3,"Embryo Stage");

	#identify the probe type.
	my $rowProbeType = &getCellValue($sheet,$row,4,"Probe Type");

	# bow out if we don't have an image
	next unless ($rowImage);

	# get  image
	my $image = $factory->findObject('OME::Image',
					 name=>$rowImage);
	if (!$image) {
	    print "Could not find $image in database. Skipping \n";
	    next;
	}

	# get gene and create it
	my $gene;
	if ($rowGene) {
	    $gene = $factory->maybeNewAttribute($geneST,undef,$mex,
						   {Name=>$rowGene});
	    $gene->storeObject();

	    # create an ExternalLink object for this gene
	    my $extLink =
		$factory->maybeNewAttribute($extLinkST,undef,$mex,
					    { Description =>'MGI',
					      ExternalId =>
						  $gene->Name(),
						  Template=>$extLinkTemplate});
	    $extLink->storeObject();
	    # create a gene external link object..				
	    my $geneExLink =
		$factory->maybeNewAttribute($geneLinkMapST,undef,$mex,
					    { Gene=>$gene,
					      ExternalLink=>$extLink});
	    $geneExLink->storeObject();


	}

	my $probe;
	# get probe and create it 
	if ($rowProbe) {
	    $probe = $factory->maybeNewAttribute($probeST,undef,$mex,
						    {Name=>$rowProbe});
	    $probe->storeObject();
	}
	# create gene probe connection
	if ($probe && $gene) {
	    my $pgMap = $factory->maybeNewAttribute($pgST,undef,$mex,
				    {Probe=>$probe,Gene=>$gene});
	    $pgMap->storeObject();
	}

	# get probe type and create if
	if ($rowProbeType) {
	    my $probeType = $factory->maybeNewAttribute($probeTypeST,
					undef,$mex,{Name=>$rowProbeType});
	    if ($probe) {
		# make probe-probe type connection
		$probe->Type($probeType);
		$probe->storeObject();
	    }
	}
	
	# make image-probe connection
	# but only if it does not exist.
	if ($image && $probe) {

	    # get all of the image probes for this image
	    my @imageProbes = $image->ImageProbeList();
	    my $ip;

	    # if something matches this current probe find it.
	    foreach my $ipl (@imageProbes) {
		if ($ipl->Probe->ID == $probe->ID) {
		    $ip = $ipl->Probe;
		    last;
		}
	    }
	    # if not, create it.
	    if (!$ip) {
		$ip = $factory->newAttribute($ipST,$image,$mex,
						     {Probe=>$probe});
		$ip->storeObject();
	    }
	}

	# get embryo stage and create if exists
	my $embryoStage;
	if ($rowEmbryoStage) {
	    $embryoStage = $factory->maybeNewAttribute($esST,undef,$mex,
				  {Name=>$rowEmbryoStage}); 	
	    $embryoStage->storeObject();
	}

	# create image embryo_stage -link, but only if not existing.
	if ($image && $embryoStage) {
	    my $ies;
	    my @imageEmbryoStageList = $image->ImageEmbryoStageList;
	    foreach my $imageEmbryoStage (@imageEmbryoStageList) {
		if ($imageEmbryoStage->EmbryoStage->ID ==
		    $embryoStage->ID) {
		    $ies = $imageEmbryoStage->EmbryoStage;
		    last;
		}
	    }
	    if (!$ies) {
		$ies = $factory->newAttribute($imageEsST,$image,$mex,
				   {EmbryoStage=>$embryoStage});
		$ies->storeObject();
	    }
	}
					      
	#publication status - create if it doesn't already exist.
	my @pubStatusList = $image->PublicationStatusList;

	my $pubStatus;
	foreach my $ps  (@pubStatusList) {
	    if ($ps->Publishable ==1){
		$pubStatus =$ps;
		$pubStatus->Publishable(1);
		$pubStatus->storeObject();
	    }
	}
	
	if (!$pubStatus) { 
	    $pubStatus = $factory->newAttribute($pubStatusST,
						$image,$mex,{Publishable=>1});
	    $pubStatus->storeObject();
	}
	# commit stuff
	$session->commitTransaction();
    }
    # clean up and cloes up.
}
    
=head2 getCellValue

    my $val = getCellValue($sheet,$row,$col,$name)
    
    Get the cell in $row, $col from $sheet and return its value if found. Otherwise,
    return undef.

=cut
sub getCellValue {
    my ($sheet,$row,$col,$name) = @_;
    
    my $cell;
    my $val;
    $cell = $sheet->{Cells}[$row][$col];
    if (!$cell) {
	print "Line $row does not have a $name value\n";
    }
    else {
	$val = $cell->Value;
    }
    return $val;
}
# =============================================================
#main - this is the code that does the work
# =============================================================


&verifyEnvironment();


# clean up the login file.
&cleanupLoginFile();

# start the work
print "Configuring OME for DGAS image display\n";

# get environment and user id
my $environment = OME::Install::Environment::restore_from();
my $OME_USER = $environment->user()
    or croak "Unable to retrieve OME_USER!";
my  $OME_UID = getpwnam ($OME_USER)
    or croak "Unable to retrive OME_USER UID!";




# while in root id, patch files. Must be root because files might
# be tied to root

print "Patching template files ..\n";

&patchAccessManager();

# copy images to the appropriate directory

print "Installing header images\n";
&copyHeaderImages();


# patch home.pm to not be guest visible.
print "Patching OME home \n";
&patchHome();


# switch to effective user id for login and other changes.
# do this as currnt user.

print "Logging onto OME..\n";
euid($OME_UID);
my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();


# Enable the guest account

print "Enabling guest access..\n";
&enableGuestAccess($factory);
		       

# Configure annotation, display, and browsing templates

print "Creating Template instances..\n";
&configureTemplates($factory);

# ok. here we want to set the current user's group to null and update.
# then, do imports in an eval
# and reset it back.
#
# This is necessary to force ImportManager to create a mex with a null group 
# (ImportManager uses the user's group as the mex group). Doing so will make 
# associated objects visible to all users.

my $user = $session->User();
my $group = $user->Group();
$user->Group(undef);
$user->storeObject();


eval {
    # import MouseAnnotations.ome

    print "Importing data types and instance definitions...\n";
    &importTypeDefs($factory);

    # import images

    print "Importing Images\n";

    &importImages($factory,$group);
};

# restore the group 
$user->Group($group);
$user->storeObject();

# Import Association spreadsheets
print "Importing annotation spreadsheet\n";

&importAssociations($factory,$session);

1;
