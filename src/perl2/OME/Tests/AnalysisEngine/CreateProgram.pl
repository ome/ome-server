# OME/Tests/AnalysisEngine/CreateProgram.pl

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


use OME::Session;
use OME::SessionManager;
use OME::Module;
use OME::DataTable;
use OME::SemanticType;
use Term::ReadKey;

print "\nOME Test Case - Create module\n";
print "---------------------------\n";

if (scalar(@ARGV) != 0) {
    print "Usage:  CreateProgram\n\n";
    exit -1;
}

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();


my $factory = $session->Factory();
$factory->Debug(0);


print "Finding data tables...\n";

my $xyzImageInfo = $factory->findObject("OME::DataTable",table_name => 'XYZ_IMAGE_INFO');
print "  ".$xyzImageInfo->table_name()." (".$xyzImageInfo->id().")\n";

my $xyImageInfo = $factory->findObject("OME::DataTable",table_name => 'XY_IMAGE_INFO');
print "  ".$xyImageInfo->table_name()." (".$xyImageInfo->id().")\n";

my $timepoint = $factory->findObject("OME::DataTable",table_name => 'TIMEPOINT');
print "  ".$timepoint->table_name()." (".$timepoint->id().")\n";

my $threshold = $factory->findObject("OME::DataTable",table_name => 'THRESHOLD');
print "  ".$threshold->table_name()." (".$threshold->id().")\n";

my $location = $factory->findObject("OME::DataTable",table_name => 'LOCATION');
print "  ".$location->table_name()." (".$location->id().")\n";

my $extent = $factory->findObject("OME::DataTable",table_name => 'EXTENT');
print "  ".$extent->table_name()." (".$extent->id().")\n";

my $signal = $factory->findObject("OME::DataTable",table_name => 'SIGNAL');
print "  ".$signal->table_name()." (".$signal->id().")\n";

my $bounds = $factory->findObject("OME::DataTable",table_name => 'BOUNDS');
print "  ".$bounds->table_name()." (".$bounds->id().")\n";

my $ratio = $factory->findObject("OME::DataTable",table_name => 'RATIO');
print "  ".$ratio->table_name()." (".$ratio->id().")\n";


print "Create attribute types...\n";

my ($atype,$acolumn);

sub __createType {
    my ($typedef,$coldefs) = @_;

    my $atype = $factory->
        newObject("OME::SemanticType",{
            name        => $typedef->[0],
            granularity => $typedef->[1],
            description => $typedef->[2]
            });
    print "  ".$atype->name()." (".$atype->id().")\n";

    foreach my $coldef (@$coldefs) {
        $acolumn = $factory->newObject("OME::SemanticType::Column",{
            semantic_type => $atype,
            name           => $coldef->[0],
            data_column    => $coldef->[1]->findColumnByName($coldef->[2]),
            description    => $coldef->[3]
            });
        print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id().")\n";
    }

    return $atype;
}

my $atXYZMean = __createType
    (['Stack mean','I',''],
     [['WAVENUMBER',$xyzImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyzImageInfo,'TIMEPOINT',''],
      ['MEAN',$xyzImageInfo,'MEAN','']]);
my $atXYZGeomean = __createType
    (['Stack geomean','I',''],
     [['WAVENUMBER',$xyzImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyzImageInfo,'TIMEPOINT',''],
      ['GEOMEAN',$xyzImageInfo,'GEOMEAN','']]);
my $atXYZSigma = __createType
    (['Stack sigma','I',''],
     [['WAVENUMBER',$xyzImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyzImageInfo,'TIMEPOINT',''],
      ['SIGMA',$xyzImageInfo,'SIGMA','']]);
my $atXYZMinimum = __createType
    (['Stack minimum','I',''],
     [['WAVENUMBER',$xyzImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyzImageInfo,'TIMEPOINT',''],
      ['MINIMUM',$xyzImageInfo,'MIN','']]);
my $atXYZMaximum = __createType
    (['Stack maximum','I',''],
     [['WAVENUMBER',$xyzImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyzImageInfo,'TIMEPOINT',''],
      ['MAXIMUM',$xyzImageInfo,'MAX','']]);
my $atXYZCentroid = __createType
    (['Stack centroid','I',''],
     [['WAVENUMBER',$xyzImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyzImageInfo,'TIMEPOINT',''],
      ['X',$xyzImageInfo,'CENTROID_X',''],
      ['Y',$xyzImageInfo,'CENTROID_Y',''],
      ['Z',$xyzImageInfo,'CENTROID_Z','']]);

my $atXYMean = __createType
    (['Plane mean','I',''],
     [['WAVENUMBER',$xyImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyImageInfo,'TIMEPOINT',''],
      ['ZSECTION',$xyImageInfo,'ZSECTION',''],
      ['MEAN',$xyImageInfo,'MEAN','']]);
my $atXYGeomean = __createType
    (['Plane geomean','I',''],
     [['WAVENUMBER',$xyImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyImageInfo,'TIMEPOINT',''],
      ['ZSECTION',$xyImageInfo,'ZSECTION',''],
      ['GEOMEAN',$xyImageInfo,'GEOMEAN','']]);
my $atXYSigma = __createType
    (['Plane sigma','I',''],
     [['WAVENUMBER',$xyImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyImageInfo,'TIMEPOINT',''],
      ['ZSECTION',$xyImageInfo,'ZSECTION',''],
      ['SIGMA',$xyImageInfo,'SIGMA','']]);
my $atXYMinimum = __createType
    (['Plane minimum','I',''],
     [['WAVENUMBER',$xyImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyImageInfo,'TIMEPOINT',''],
      ['ZSECTION',$xyImageInfo,'ZSECTION',''],
      ['MINIMUM',$xyImageInfo,'MIN','']]);
my $atXYMaximum = __createType
    (['Plane maximum','I',''],
     [['WAVENUMBER',$xyImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyImageInfo,'TIMEPOINT',''],
      ['ZSECTION',$xyImageInfo,'ZSECTION',''],
      ['MAXIMUM',$xyImageInfo,'MAX','']]);
my $atXYCentroid = __createType
    (['Plane centroid','I',''],
     [['WAVENUMBER',$xyImageInfo,'WAVENUMBER',''],
      ['TIMEPOINT',$xyImageInfo,'TIMEPOINT',''],
      ['ZSECTION',$xyImageInfo,'ZSECTION',''],
      ['X',$xyImageInfo,'CENTROID_X',''],
      ['Y',$xyImageInfo,'CENTROID_Y','']]);

my $atTimepoint = __createType
    (['Timepoint','F',''],
     [['TIMEPOINT',$timepoint,'TIMEPOINT','']]);

my $atThreshold = __createType
    (['Threshold','F',''],
     [['THRESHOLD',$threshold,'THRESHOLD','']]);

my $atLocation = __createType
    (['Location','F',''],
     [['X',$location,'X',''],
      ['Y',$location,'Y',''],
      ['Z',$location,'Z','']]);

my $atExtent = __createType
    (['Extent','F',''],
     [['VOLUME',$extent,'VOLUME',''],
      ['MIN_X',$extent,'MIN_X',''],
      ['MIN_Y',$extent,'MIN_Y',''],
      ['MIN_Z',$extent,'MIN_Z',''],
      ['MAX_X',$extent,'MAX_X',''],
      ['MAX_Y',$extent,'MAX_Y',''],
      ['MAX_Z',$extent,'MAX_Z',''],
      ['SIGMA_X',$extent,'SIGMA_X',''],
      ['SIGMA_Y',$extent,'SIGMA_Y',''],
      ['SIGMA_Z',$extent,'SIGMA_Z',''],
      ['SURFACE_AREA',$extent,'SURFACE_AREA',''],
      ['PERIMETER',$extent,'PERIMITER',''],
      ['FORM_FACTOR',$extent,'FORM_FACTOR','']]);

my $atSignal = __createType
    (['Signal','F',''],
     [['WAVELENGTH',$signal,'WAVELENGTH',''],
      ['CENTROID_X',$signal,'CENTROID_X',''],
      ['CENTROID_Y',$signal,'CENTROID_Y',''],
      ['CENTROID_Z',$signal,'CENTROID_Z',''],
      ['MEAN',$signal,'MEAN',''],
      ['GEOMEAN',$signal,'GEOMEAN',''],
      ['SIGMA',$signal,'SIGMA',''],
      ['INTEGRAL',$signal,'INTEGRAL',''],
      ['BACKGROUND',$signal,'BACKGROUND','']]);

my $atBounds = __createType
    (['Bounds','F',''],
     [['X',$bounds,'X',''],
      ['Y',$bounds,'Y',''],
      ['WIDTH',$bounds,'WIDTH',''],
      ['HEIGHT',$bounds,'HEIGHT','']]);

my $atRatio = __createType
    (['Ratio','F',''],
     [['RATIO',$ratio,'RATIO','']]);

print "Creating programs...\n";


sub __createProgram {
    my ($progdef,$inputdefs,$outputdefs) = @_;

    my $module = $factory->
        newObject("OME::Module",{
            name     => $progdef->[0],
            description      => $progdef->[1],
            category         => $progdef->[2],
            module_type      => $progdef->[3],
            location         => $progdef->[4],
            default_iterator => $progdef->[5],
            new_feature_tag  => $progdef->[6]
            });
    print "  ".$module->name()." (".$module->id().")\n";

    foreach my $inputdef (@$inputdefs) {
        $input = $factory->
            newObject("OME::Module::FormalInput",{
                module        => $module,
                name           => $inputdef->[0],
                semantic_type => $inputdef->[1]
                });
        print "    Input: ".$input->name()." (".$input->id().")\n";
    }

    foreach my $outputdef (@$outputdefs) {
        $output = $factory->
            newObject("OME::Module::FormalOutput",{
                module        => $module,
                name           => $outputdef->[0],
                semantic_type => $outputdef->[1],
                feature_tag    => $outputdef->[2]
                });
        print "    Output: ".$output->name()." (".$output->id().")\n";
    }

    return $module;
}



my $calcXYZInfo = __createProgram
    (['Stack statistics',
      'Calculate pixel statistics for each XYZ stack',
      'Statistics',
      'OME::ModuleExecution::StopgapCLIHandler',
      '/OME/bin/OME_Image_XYZ_stats'],
     [],
     [['Stack mean',$atXYZMean],
      ['Stack geomean',$atXYZGeomean],
      ['Stack sigma',$atXYZSigma],
      ['Stack minimum',$atXYZMinimum],
      ['Stack maximum',$atXYZMaximum],
      ['Stack centroid',$atXYZCentroid]]);

my $calcXYInfo = __createProgram
    (['Plane statistics',
      'Calculate pixel statistics for each XY plane',
      'Statistics',
      'OME::ModuleExecution::StopgapCLIHandler',
      '/OME/bin/OME_Image_XY_stats'],
     [],
     [['Plane mean',$atXYMean],
      ['Plane geomean',$atXYGeomean],
      ['Plane sigma',$atXYSigma],
      ['Plane minimum',$atXYMinimum],
      ['Plane maximum',$atXYMaximum],
      ['Plane centroid',$atXYCentroid]]);

my $findSpots = __createProgram
    (['Find spots',
      'Find spots in the image',
      'Segmentation',
      'OME::ModuleExecution::FindSpotsHandler',
      '/OME/bin/findSpotsOME',
      undef,
      'SPOT'],
     [['Stack mean',$atXYZMean],
      ['Stack geomean',$atXYZGeomean],
      ['Stack sigma',$atXYZSigma],
      ['Stack minimum',$atXYZMinimum],
      ['Stack maximum',$atXYZMaximum]],
     [['Timepoint',$atTimepoint,'[Feature]'],
      ['Threshold',$atThreshold,'[Feature]'],
      ['Location',$atLocation,'[Feature]'],
      ['Extent',$atExtent,'[Feature]'],
      ['Signals',$atSignal,'[Feature]']]);

my $findCells = __createProgram
    (['Find cells',
      'Find cells',
      'Testing',
      'OME::ModuleExecution::FindBounds',
      '',
      undef,
      'CELL'],
     [],
     [['Output bounds',$atBounds,'[Feature]']]);

my $findGolgi = __createProgram
    (['Find golgi',
      'Find golgi',
      'Testing',
      'OME::ModuleExecution::FindBounds',
      '',
      'CELL',
      'GOLGI'],
     [['Input bounds',$atBounds]],
     [['Output bounds',$atBounds,'[Feature]']]);

my $findMito = __createProgram
    (['Find mito',
      'Find mito',
      'Testing',
      'OME::ModuleExecution::FindBounds',
      '',
      'CELL',
      'MITOCHONDRIA'],
     [['Input bounds',$atBounds]],
     [['Output bounds',$atBounds,'[Feature]']]);

my $findRatio = __createProgram
    (['Find ratio',
      'Find ratio',
      'Testing',
      'OME::ModuleExecution::FindRatio',
      '',
      'CELL',
      undef],
     [['Golgi bounds',$atBounds],
      ['Mito bounds',$atBounds]],
     [['Golgi-mito ratio',$atRatio,'[Iterator]']]);


$output->dbi_commit();

1;
