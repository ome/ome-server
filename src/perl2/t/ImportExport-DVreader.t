# -*- perl -*-

# t/031_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::ImportExport::DVreader' ); }

my $object = OME::ImportExport::DVreader->new ();
isa_ok ($object, 'OME::ImportExport::DVreader');


