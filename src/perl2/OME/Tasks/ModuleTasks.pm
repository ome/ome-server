# OME/Tasks/ModuleTasks.pm

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
# Written by: Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------

package OME::Tasks::ModuleTasks;

use OME::Module::Category;
use OME::Session;
use OME::Factory;

=head1 METHODS

=head2 makeCategoriesFromPath

my $leaf_category = makeCategoriesFromPath ($path, $description);

Given a full category path and optional description, ensures that all
portions of the path exist in the database as categories, and returns
the Category object for the leaf category.

This was originally written by Joisah Johnston and called __getCategory
in ModuleImport.pm 
=cut

sub makeCategoriesFromPath {
    my ($path,$description) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my @names = split(/\./,$path);
    my $leaf_name = pop(@names);

    # Create/load categories for all but the leaf element
    my $last_parent;
    foreach my $name (@names) {
        my $criteria = { name => $name };
        $criteria->{parent_category_id} = $last_parent->id()
          if defined $last_parent;

        $last_parent = $factory->
          maybeNewObject('OME::Module::Category',$criteria);
    }

    # And then do the same for the leaf element
    my %criteria = ( name => $leaf_name );
    $criteria{parent_category_id} = $last_parent->id()
      if defined $last_parent;

    # We can't use maybeNewObject b/c the search criteria is not the
    # same as the hash to create the new object.

    my $category = $factory->findObject('OME::Module::Category',%criteria);
    if (!defined $category) {
        $criteria{description} = $description;
        $category = $factory->newObject('OME::Module::Category',\%criteria);
    }

    return $category;
}

=head2 returnPathToLeafCategory

my $path = returnPathToLeafCategory ($leafCategory);

Given the Category object for the leaf category, it returns the full category
path as a string.
=cut

sub returnPathToLeafCategory {
    my ($category) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

	my @path;
	unshift (@path, $category->name());

	while (defined $category->parent_category_id) {
		$category = $factory->findObject('OME::Module::Category',
			{id => $category->parent_category_id()});
		unshift (@path, $category->name());
	}
	
	my $pathStr = join('.', @path);
    return $pathStr;
}


=pod

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>

=cut

1;
