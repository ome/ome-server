package OME::LookupTable;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('lookup_tables');
__PACKAGE__->sequence('lookup_table_seq');
__PACKAGE__->columns(Primary => qw(lookup_table_id));
__PACKAGE__->columns(Essential => qw(name description));
__PACKAGE__->has_many('entries',OME::LookupTable::Entry => qw(lookup_table_id));



package OME::LookupTable::Entry;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->AccessorNames({
    lookup_table_id => 'lookup_table'
    });

__PACKAGE__->table('lookup_table_entries');
__PACKAGE__->sequence('lookup_table_entry_seq');
__PACKAGE__->columns(Primary => qw(lookup_table_entry_id));
__PACKAGE__->columns(Essential => qw(value label lookup_table_id));



1;

