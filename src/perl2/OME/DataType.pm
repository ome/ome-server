package OME::DataType;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->table('datatypes');
__PACKAGE__->sequence('datatype_seq');
__PACKAGE__->columns(Primary => qw('datatype_id'));
__PACKAGE__->columns(Essential => qw(table_name description attribute_type));
__PACKAGE__->has_many('columns',OME::DataType::Column => qw(datatype_id));



package OME::DataType::Column;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->AccessorNames({
    datatype_id => 'datatype'
    });

__PACKAGE__->table('datatype_columns');
__PACKAGE__->sequence('datatype_column_seq');
__PACKAGE__->columns(Primary => qw(datatype_column_id));
__PACKAGE__->columns(Essential => qw(column_name reference_name));
__PACKAGE__->hasa(OME::DataType => qw(datatype_id));
    

1;

