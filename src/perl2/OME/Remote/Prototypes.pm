# OME/Remote/Prototypes.pm

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


package OME::Remote::Prototypes;
our $VERSION = '1.00';

use strict;

our %prototypes =
  (
   'OME::Session' => {
                      id      => [['$'],['$']],
                      Factory => [[],['OME::Factory']],
                     },
   'OME::Factory' => {
                      newObject     => [['$','%'],['OME::DBObject']],
                      newAttribute  => [['$','OME::DBObject','%'],
                                        ['OME::AttributeType::Superclass']],
                      loadObject    => [['$','$'],['OME::DBObject']],
                      loadAttribute => [['$','$'],
                                        ['OME::AttributeType::Superclass']],
                     },
   'OME::DBObject' => {
                       id          => [['$'],['$']],
                       writeObject => [[],[]],
                      },
   'OME::Project' => {
                      #id          => [['$'],['$']],
                      name        => [['$'],['$']],
                      description => [['$'],['$']],
                      owner       => [['OME::Experimenter'],['OME::Experimenter']],
                      group       => [['OME::Group'],['OME::Group']],
                      #writeObject => [[],[]],
                     },
   'OME::Experimenter' => {
                           #id          => [['$'],['$']],
                           ome_name    => [['$'],['$']],
                           firstname   => [['$'],['$']],
                           lastname    => [['$'],['$']],
                           email       => [['$'],['$']],
                           data_dir    => [['$'],['$']],
                           #writeObject => [[],[]],
                          },
   'OME::Group' => {
                    #id          => [['$'],['$']],
                    name        => [['$'],['$']],
                    leader      => [['OME::Experimenter'],['OME::Experimenter']],
                    contact     => [['OME::Experimenter'],['OME::Experimenter']],
                    #writeObject => [[],[]],
                },
  );


sub findPrototypes {
    my ($class, $method) = @_;

    my @classesToCheck = ($class);
    my $prototypeFound;

    print STDERR "*** $class ";
    while (my $nextClass = shift(@classesToCheck)) {
        if (exists $prototypes{$nextClass}->{$method}) {
            $prototypeFound = $prototypes{$nextClass}->{$method};
            last;
        }
        my $isaRef = "${nextClass}::ISA";
        no strict 'refs';
        print STDERR join(' ',@$isaRef)," ";
        push @classesToCheck, @$isaRef;
        use strict 'refs';
    }

    print STDERR "\n";

    return $prototypeFound;
}

1;
