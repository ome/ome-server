# -*- perl -*-

# t/008_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Experimenter' ); }

my $object = OME::Experimenter->new ();
isa_ok ($object, 'OME::Experimenter');


