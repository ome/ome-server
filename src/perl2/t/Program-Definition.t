# -*- perl -*-

# t/030_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Program::Definition' ); }

my $object = OME::Program::Definition->new ();
isa_ok ($object, 'OME::Program::Definition');


