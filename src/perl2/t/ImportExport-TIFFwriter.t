# -*- perl -*-

# t/039_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::ImportExport::TIFFwriter' ); }

my $object = OME::ImportExport::TIFFwriter->new ();
isa_ok ($object, 'OME::ImportExport::TIFFwriter');


