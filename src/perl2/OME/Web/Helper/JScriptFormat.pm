# OME/Web/Helper/JScriptFormat.pm

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
# Written by:    J-M Burel <jburel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::Helper::JScriptFormat;


=head 1 NAME

OME::Web::Helper::JScriptFormat - HTML code used for WebInterface

=head 1 SYNOPSIS

	use OME::Web::Helper::JScriptFormat;
	my $htmlFormat=new OME::Web::Helper::JScriptFormat;


=head 1 DESCRIPTION

The OME::Web::Helper::JScriptFormat provides a list of methods to write javascript functions

=head1 METHODS (ALPHABETICAL ORDER)

=head2 closeButton
=head2 openExistingDataset
=head2 openExistingProject
=head2 openInfoDataset
=head2 openInfoDatasetImport
=head2 openInfoProject
=head2 popUpImage
=head2 popUpDataset

=cut


use strict;
use OME;
our $VERSION = $OME::VERSION;

sub new{
	my $class=shift;
	my $self={};
	$self->{GetGraphics}="/perl2/serve.pl?Page=OME::Web::GetGraphics";
	$self->{GetInfo}="/perl2/serve.pl?Page=OME::Web::GetInfo";
	$self->{InfoProject}="/perl2/serve.pl?Page=OME::Web::InfoProject";
	$self->{InfoDataset}="/perl2/serve.pl?Page=OME::Web::InfoDataset";

	bless($self,$class);
   	return $self;
}

##############
sub closeButton{
my $text.=<<END;
	<input type=button
	onclick="window.close()"
	value="Close window">
END
return $text;
}


################
sub openExistingDataset{
	my $self=shift;
	my $text;
	$text=writeFunction("openExistingDataset","ExistingDataset",$self->{InfoDataset},"UsergpID");
	return $text;
}

##################
sub openExistingProject{
	my $self=shift;
	my $text;
	$text=writeFunction("openExistingProject","ExistingProject",$self->{InfoProject},"UsergpID");
	return $text;
}

##########################
sub openInfoDataset{
	my $self=shift;
	my $text;
	$text=writeFunction("openInfoDataset","InfoDataset",$self->{GetInfo},"DatasetID");
	return $text;
}

#########################
sub openInfoDatasetImport{
	my $self=shift;
	my ($id)=@_;
	my $text;
	$text=writeFunctionOpen("InfoDatasetImport",$self->{GetInfo},"DatasetID",$id);
	return $text;

}
########################
sub openInfoProject{
	my $self=shift;
	my $text;
	$text=writeFunction("openInfoProject","InfoProject",$self->{GetInfo},"ProjectID");
	return $text;
}


######################
sub popUpDataset{
	my $self=shift;
	my $text;
	$text=writeFunction("openPopUpDataset","DatasetViewer",$self->{GetGraphics},"DatasetID");
	return $text;
}

#####################
sub popUpImage{
	my $self=shift;
	my $text;
	$text=writeFunction("openPopUpImage","ImageViewer",$self->{GetGraphics},"ImageID");
	return $text;
}



####################
# PRIVATE METHODS
####################

sub writeFunction{
	my ($function,$name,$path,$param)=@_;
	my $file=$path."&".$param."=";
my $text=<<ENDJS;
<script language="JavaScript">
<!--
var ID;
function $function(id){
imageid=id;
var OMEfile;
OMEfile=\'$file\'+imageid;
$name=window.open(
OMEfile,
"$name",
"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
return false;
}
-->
</script>
ENDJS

return $text;
}

sub writeFunctionOpen{
	my ($name,$path,$param,$id)=@_;
	my $file=$path."&Bool=1&".$param."=".$id;
	my $text="";
 $text.=<<ENDJS;
<script language="JavaScript">
<!--
var OMEfile=\'$file\';
$name=window.open(
OMEfile,
"$name",
"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500");
-->
</script>
ENDJS

return $text;

}


1;
