#!/usr/bin/perl -w
# OME/Tests/ImportChain.pl

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


use strict;
use OME::Tasks::ChainImport;
use OME::SessionManager;

print "\nOME Test Case - Chain Import\n";
print "----------------------------\n";

if (scalar(@ARGV) < 1) {
    print "Usage:  ImportChain [file list]\n\n";
    exit -1;
}

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();

my $chainImporter = OME::Tasks::ChainImport->
  new(session => $session);

my $totalChains = 0;
foreach (@ARGV) {
    print STDERR "Importing $_...\n";

    my $newChains;
    eval {
        $newChains = $chainImporter->importFile($_,NoDuplicates => 1);
    };
    print STDERR "Import failed on $_\nError message:\n$@\n"
      if $@;
    print STDERR "Imported ".scalar(@$newChains)." chains sucessfully.\n"
      unless $@;
    $totalChains += scalar(@$newChains)
      unless not defined $newChains;
}
print STDERR "\nImported $totalChains chains from ".scalar(@ARGV)." files.";

print STDERR "\n";
