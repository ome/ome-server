# OME/Tasks/OMEXMLImportExport.pm

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
# Written by:    JM Burel <jburel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


=pod

=head1 WARNING!

This class is a quick and dirty implementation for alpha. This class will be removed and its functionality moved to other places.
the functionality of importXMLfile pretty much replicates the functionality of OME::Tasks::OMEImport
the functionality of exportToXMLFile will be moved to imageManager. Similar functionality will be added to DatasetManager, ProjectManager, and the other Managers.


This warning added by Josiah <siah@nih.gov> based on correspondence with Jean-Marie & Andrea.

=cut

package OME::Tasks::OMEXMLImportExport;


our $VERSION = 2.000_000;

use strict ;

use OME::Tasks::OMEImport ;
use OME::Tasks::OMEExport ;



# Constructor. This is not an instance method as well.
# new($session)

sub new {
	my ($class,$session) = @_ ;
	my  $self = {} ;
	$self->{session} = $session ;
	bless($self,$class) ;
	return  $self ;
}

############################
# Imports an xml file.
# import($file)
# $file   MUST be absolute (path+name)

sub importXMLfile {
  	my  $self = shift ;
  	my ($refFiles)=@_;
  	my $session= $self->{session};
  	my $importer=OME::Tasks::OMEImport->new( session => $session,debug => 1 ) ;
	foreach my $file (@$refFiles){
		# To-do check if XML file
  		$importer->importFile($file) ;
	}
  	return ;
}

#####################################################
# For each given image, exports all image attributes 
# to the specified XML file.
# export($images,$file)
# $images  a ref to an array containing the image objects
# $file   MUST be absolute (path+name)

sub exportToXMLFile {

  	my  ($self, $images, $file) = @_ ;
 	my  $factory = $self->{session}->Factory() ;
	# To-do check if can write in file
  	my  @imageAttributes = $factory->findObjects("OME::SemanticType",
                                                        granularity => 'I');
  	my  $exporter = OME::Tasks::OMEExport->new( session => $self->{session} ) ;
  	my  @exportObjects = () ;
 	my  $i = 0 ;
 	while( $i < @$images) {
		push(@exportObjects,$images->[$i]) ; # Add the image
    		foreach my $attribute (@imageAttributes) {  # Add its attribute instances
     		  my  @attr = $factory->findAttributes($attribute->name(),$images->[$i]->id()) ;
		  if(@attr) {
		    push(@exportObjects,@attr) ;
		  }
    		}
		$i++;
  	}
  	$exporter->buildDOM(\@exportObjects, ResolveAllRefs => 1, ExportSTDs => 0) ;
	$exporter->exportFile($file);
 	return ;
}



=head1 AUTHOR

JM Burel (jburel@dundee.ac.uk)

=cut

1;
