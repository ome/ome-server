# -*- perl -*-

# t/036_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'OME::ImportExport::Importer' ); }

my $object = OME::ImportExport::Importer->new ();
isa_ok ($object, 'OME::ImportExport::Importer');


