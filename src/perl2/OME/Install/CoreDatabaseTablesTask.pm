# OME/Install/CoreDatabaseTablesTask.pm

# Copyright (C) 2003 Open Microscopy Environment
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

package OME::Install::CoreDatabaseTablesTask;

# Hey there Chris, I just created this class to have a place to put
# the list of DBObjects that can be used to instantiate the database.
# --doug

# $coreClasses = ([$package_to_require,$class_to_instantiate], ... )

# Each class to instantiate is listed as a pair: the package that
# should be used in the "require" statement, and the class to actually
# instantiate in the database.  If the first argument is undef, no
# require statement is executed.  This is just to deal with the fact
# that some files declare multiple DBObject subclasses; only the
# package corresponding to the filename should be "required".

our @coreClasses =
  (
   ['OME::LookupTable',       'OME::LookupTable'],
   [undef,                    'OME::LookupTable::Entry'],
   ['OME::DataTable',         'OME::DataTable'],
   [undef,                    'OME::DataTable::Column'],
   ['OME::SemanticType',      'OME::SemanticType'],
   [undef,                    'OME::SemanticType::Element'],
   [undef,                    'OME::SemanticType::BootstrapExperimenter'],
   [undef,                    'OME::SemanticType::BootstrapGroup'],
   [undef,                    'OME::SemanticType::BootstrapRepository'],
   ['OME::Dataset',           'OME::Dataset'],
   ['OME::Project',           'OME::Project'],
   ['OME::Project',           'OME::Project::DatasetMap'],
   ['OME::Image',             'OME::Image'],
   ['OME::Image',             'OME::Image::DatasetMap'],
   ['OME::Image',             'OME::Image::ImageFilesXYZWT'],
   ['OME::Feature',           'OME::Feature'],
   ['OME::Session',           'OME::Session'],
   ['OME::ViewerPreferences', 'OME::ViewerPreferences'],
   ['OME::Module::Category',  'OME::Module::Category'],
   ['OME::Module',            'OME::Module'],
   ['OME::Module',            'OME::Module::FormalInput'],
   ['OME::Module',            'OME::Module::FormalOutput'],
   ['OME::AnalysisChain',     'OME::AnalysisChain'],
   ['OME::AnalysisChain',     'OME::AnalysisChain::Node'],
   ['OME::AnalysisChain',     'OME::AnalysisChain::Link'],
   ['OME::AnalysisPath',      'OME::AnalysisPath'],
   ['OME::AnalysisPath',      'OME::AnalysisPath::Map'],
   ['OME::ModuleExecution',   'OME::ModuleExecution'],
   ['OME::ModuleExecution',   'OME::ModuleExecution::ActualInput'],
   ['OME::ModuleExecution',   'OME::ModuleExecution::SemanticTypeOutput'],
   ['OME::AnalysisChainExecution',
                              'OME::AnalysisChainExecution'],
   ['OME::AnalysisChainExecution',
                              'OME::AnalysisChainExecution::NodeExecution'],
   # Make sure this next one is last
   ['OME::Configuration',     'OME::Configuration'],
  );


1;
