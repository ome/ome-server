# OME/Web/Helper/JScriptFormat.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  J-M Burel <jburel@dundee.ac.uk>
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


package OME::Web::Helper::JScriptFormat;

use strict;
our $VERSION = '1.0';

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




sub popUpImage{
	my $self=shift;
	my $text;
	$text=writeFunction("openPopUpImage","ImageViewer",$self->{GetGraphics},"ImageID");
	return $text;
}

######################


sub popUpDataset{
	my $self=shift;
	my $text;
	$text=writeFunction("openPopUpDataset","DatasetViewer",$self->{GetGraphics},"DatasetID");
	return $text;
}

########################

sub openInfoProject{
	my $self=shift;
	my $text;
	$text=writeFunction("openInfoProject","InfoProject",$self->{GetInfo},"ProjectID");
	return $text;

}

##########################

sub openInfoDataset{
	my $self=shift;
	my $text;
	$text=writeFunction("openInfoDataset","InfoDataset",$self->{GetInfo},"DatasetID");
	return $text;

}


##################

sub openExistingProject{
	my $self=shift;
	my $text;
	$text=writeFunction("openExistingProject","ExistingProject",$self->{InfoProject},"UsergpID");
	return $text;
}

################

sub openExistingDataset{

	my $self=shift;
	my $text;
	$text=writeFunction("openExistingDataset","ExistingDataset",$self->{InfoDataset},"UsergpID");
	return $text;

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

1;