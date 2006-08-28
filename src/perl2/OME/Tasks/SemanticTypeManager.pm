# OME/Tasks/ModuleExecutionManager.pm

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
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#                Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Tasks::SemanticTypeManager;

=head1 NAME

OME::Tasks::SemanticTypeManager - Workflow methods for handling
semantic types

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::SemanticType;
use OME::SemanticType::Element;
use OME::DataTable;
use OME::Tasks::OMEImport;
use OME::Util::Data::Delete;

sub createSemanticType {
    my $class = shift;
    my ($name,$granularity,$description) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $st = $factory->findObject('OME::SemanticType',
                                  name => $name);
    unless (defined $st) {
        $st = $factory->
          newObject('OME::SemanticType',
                    {
                     name        => $name,
                     granularity => $granularity,
                     description => $description,
                    });
        die "Could not create $name type"
          unless defined $st;
    }

    return $st;
}

sub addSemanticElement {
    my $class = shift;
    my ($st,$name,$dc,$description) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $se = $factory->findObject('OME::SemanticType::Element',
                                  semantic_type => $st,
                                  name          => $name);
    unless (defined $se) {
        $se = $factory->
          newObject('OME::SemanticType::Element',
                    {
                     semantic_type => $st,
                     name          => $name,
                     data_column   => $dc,
                     description   => $description,
                    });
        die "Could not create $name element"
          unless defined $se;
    }

    return $se;
}


sub createDataTable {
    my $class = shift;
    my ($name,$granularity,$description) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $dt = $factory->findObject('OME::DataTable',
                                  table_name => $name);
    unless (defined $dt) {
        $dt = $factory->
          newObject('OME::DataTable',
                    {
                     table_name  => $name,
                     granularity => $granularity,
                     description => $description,
                    });
        die "Could not create $name table"
          unless defined $dt;
    }

    return $dt;
}

sub addDataColumn {
    my $class = shift;
    my ($dt,$name,$type,$param1,$param2) = @_;
    my ($description,$reftype);
    if ($type eq 'reference') {
        $reftype = $param1;
        $description = $param2;
    } else {
        $reftype = undef;
        $description = $param1;
    }
    my $factory = OME::Session->instance()->Factory();

    my $dc = $factory->findObject('OME::DataTable::Column',
                                  column_name => $name,
                                  data_table  => $dt);
    unless (defined $dc) {
        $dc = $factory->
          newObject('OME::DataTable::Column',
                    {
                     data_table     => $dt,
                     column_name    => $name,
                     sql_type       => $type,
                     reference_type => $reftype,
                     description    => $description,
                    });
        die "Could not create $name column"
          unless defined $dc;
    }

    return $dc;
}

=cut

e.g. 
my @Image_ome_updates = (
    {
       semantic_type  => "ImageExperiment",
       sql_conversion => "INSERT INTO imageexperiment(attribute_id,module_execution_id,image_id,experiment) ".
						 "SELECT attribute_id,module_execution_id,image_id,experiment FROM image_info",
    },
    {
       semantic_type  => "ImageGroup",
       sql_conversion => "INSERT INTO imagegroup(attribute_id,module_execution_id,image_id,group_se) ".
 					     "SELECT attribute_id,module_execution_id,image_id,group_id FROM image_info",
    },
    {
       semantic_type  => "ImageInstrument",
       sql_conversion => "INSERT INTO imageinstrument(attribute_id,module_execution_id,image_id,instrument,objective) ".
					     "SELECT attribute_id,module_execution_id,image_id,instrument,objective FROM image_info",
    },
);
  
OME::Tasks::SemanticTypeManager->updateSTDefinitions("../../../src/xml/OME/Core/Image.ome",@Image_ome_updates);

$session->commitTransaction() needs to be called after updateSTDefinitions() is called

=cut

# N.B obviously there are four loops going through @oldST/@st_updates
# they probably shouldn't be combined because of multiple STs per table conflicts
sub updateSTDefinitions {
    my $class = shift;
    my $new_ST_xml_file = shift;
    my @st_updates = @_;
    
    my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $dbh = $factory->obtainDBH();
	
	# load old STs and rename them
	my @oldSTs;
	foreach my $st_update (@st_updates) {
		my $oldST = $factory->findObject( "OME::SemanticType",
											{
											'name'  => $st_update->{semantic_type},
											}) or 
			die " could not load ".$st_update->{semantic_type};
			
		$oldST->name( $oldST->name()."_old");
		$oldST->storeObject();
		push (@oldSTs, $oldST);
	}
	
	# import the new ST definitions (including creating tables)
	my $omeImport = OME::Tasks::OMEImport->new(session => $session);
	$omeImport->importFile($new_ST_xml_file, NoDuplicates => 1);

	# copy old ST attributes into new
	foreach (@st_updates) {
		$dbh->do($_->{sql_conversion}) or die $dbh->errstr();
	}
	
	foreach my $oldST (@oldSTs) {
		$oldST->name() =~ m/(.*)_old/;
		my $newSTname = $1;
		my $newST = $factory->findObject( "OME::SemanticType",
											{
											'name'  => $newSTname,
											}) or 
			die " could not load ".$newSTname;
			
		# change references pointing to the old ST to point to the new ST
		my @FI = $factory->findObjects( "OME::Module::FormalInput", {semantic_type_id  => $oldST->id()});
		my @FO = $factory->findObjects( "OME::Module::FormalOutput", {semantic_type_id  => $oldST->id()});			
		my @untypedOutputs = $factory->findObject( "OME::ModuleExecution::SemanticTypeOutput",  {semantic_type_id  => $oldST->id()});
		
		foreach ((@FI,@FO,@untypedOutputs)) {
			next unless defined $_;
			$_->semantic_type_id($newST->id());
			$_->storeObject();
		}

		# remove the oldST
		# N.B: the foreign key constraint on the oldST table is based on the oldST's original name
		#      that's what the last parameter passed into delete_st is about
		OME::Util::Data::Delete->delete_st($oldST,1,0,$newSTname);
	}	
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Tom Macura <tmacura@nih.gov>

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
