# OME/Tests/AnalysisEngine/ShowImageAttributes.pl

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
use OME::Image;
use OME::Feature;
use OME::DataTable;
use Term::ReadKey;

# I really hate those "method clash" warnings, especially since these
# methods are now deprecated.
no strict 'refs';
undef &Class::DBI::min;
undef &Class::DBI::max;
use strict 'refs';

print "\nOME Test Case - Show image attributes\n";
print "-------------------------------------\n";

if (scalar(@ARGV) == 0) {
    print "Usage:  ShowImageAttributes [image ID's]\n\n";
    exit -1;
}

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();


my $factory = $session->Factory();
$factory->Debug(0);

my @all_datatypes = OME::DataTable->retrieve_all();

my %temp_datatypes = (D => [], I => [], F => []);
push @{$temp_datatypes{$_->semantic_type()}}, $_ foreach @all_datatypes;

my %datatypes;
foreach ('D','I','F') {
    my @sorted = sort {$a->table_name() cmp $b->table_name()} @{$temp_datatypes{$_}};
    $datatypes{$_} = \@sorted;
}

foreach my $imageID (@ARGV) {
    my $image = $factory->loadObject("OME::Image",$imageID);
    print "\n\nImage ".$imageID." - '".$image->name()."'\n";
    __showDatatype("  ",$_,$imageID) foreach @{$datatypes{I}};
    __showFeature("  ",$_) foreach $image->features();
}


sub __showDatatype {
    my ($prefix,$datatype,$id) = @_;

    my $table_name = $datatype->table_name();
    my $sth = $datatype->findAttributesByTarget($id);
    while (my $row = $sth->fetch()) {
        print "$prefix$table_name\n";
        my $attribute = $factory->loadAttribute($table_name,$row->[0]);
        foreach my $column ($datatype->db_columns()) {
            my $column_name = $column->column_name();
            my $method_name = lc($column_name);
            my $value = $attribute->$method_name();
            print "$prefix  $method_name = ".$value."\n"
              if (defined $value);
        }
    }
}

sub __showFeature {
    my ($prefix,$feature) = @_;

    print $prefix.$feature->tag()." feature ".$feature->id()." - '".$feature->name()."'\n";

    __showDatatype("$prefix  ",$_,$feature->id()) foreach @{$datatypes{F}};
    __showFeature("$prefix  ",$_) foreach $feature->children();
}
