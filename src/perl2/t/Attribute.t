# -*- perl -*-

# t/004_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::Attribute' ); }

my $object = OME::Attribute->new ();
isa_ok ($object, 'OME::Attribute');


