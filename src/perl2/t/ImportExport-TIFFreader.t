# -*- perl -*-

# t/038_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::ImportExport::TIFFreader' ); }

my $object = OME::ImportExport::TIFFreader->new ();
isa_ok ($object, 'OME::ImportExport::TIFFreader');


