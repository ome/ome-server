# -*- perl -*-

# t/029_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Program::CalculateImageStatistics' ); }

my $object = OME::Program::CalculateImageStatistics->new ();
isa_ok ($object, 'OME::Program::CalculateImageStatistics');


