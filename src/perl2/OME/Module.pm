package OME::Program;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id          => ['PROGRAMS','PROGRAM_ID',
			{sequence => 'PROGRAM_SEQ'}],
	name        => ['PROGRAMS','PROGRAM_NAME'],
	description => ['PROGRAMS','DESCRIPTION'],
	category    => ['PROGRAMS','CATEGORY'],
	location    => ['PROGRAMS','LOCATION'],
	inputs      => ['FORMAL_INPUTS','FORMAL_INPUT_ID',
			{map       => 'PROGRAM_ID',
			 reference => 'OME::Program::FormalInput'}],
	outputs     => ['FORMAL_OUTPUTS','FORMAL_OUTPUT_ID',
			{map       => 'PROGRAM_ID',
			 reference => 'OME::Program::FormalOutput'}]
    };

    return $self;
}


# performAnalysis(parameters,dataset)
# -----------------------------------
# Creates a new Analysis (an instance of this Program being run), and
# performs the analysis against a dataset.  The parameters are defined
# as follows:
#    { $FormalInput => { attribute => $Attribute } }
# or { $FormalInput => { analysis  => $Analysis,
#                        output    => $FormalOutput } }
# These two possibilities model the fact that inputs can come from a
# previous module's calculations, or from user input.

sub performAnalysis {
    my ($self, $params, $dataset) = @_;
    my $factory = $self->Factory();

    my $analysis = $factory->newObject("OME::Analysis");
    $analysis->Field("program",$self);
    $analysis->Field("experimenter",$self->Session()->User());
    $analysis->Field("dataset",$dataset);

    # We've set up everything we can, now delegate to
    # the Analysis object to perform the actual processing.

    $analysis->performAnalysis($params);
    
}


package OME::Program::FormalInput;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id          => ['FORMAL_INPUTS','FORMAL_INPUT_ID',
			{sequence => 'FORMAL_INPUT_SEQ'}],
	program     => ['FORMAL_INPUTS','PROGRAM_ID',
			{reference => 'OME::Program'}],
	name        => ['FORMAL_INPUTS','NAME'],
        columnType  => ['FORMAL_INPUTS','COLUMN_TYPE',
			{reference => 'OME::DataType::Column'}],
	lookupTable => ['FORMAL_INPUTS','LOOKUP_TABLE_ID',
			{reference => 'OME::LookupTable'}]
    };

    return $self;
}


package OME::Program::FormalOutput;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
use OME::DBObject;
@ISA = ("OME::DBObject");

# new
# ---

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{_fields} = {
	id          => ['FORMAL_OUTPUTS','FORMAL_OUTPUT_ID',
			{sequence => 'FORMAL_OUTPUT_SEQ'}],
	program     => ['FORMAL_OUTPUTS','PROGRAM_ID',
			{reference => 'OME::Program'}],
	name        => ['FORMAL_OUTPUTS','NAME'],
	columnType  => ['FORMAL_OUTPUTS','COLUMN_TYPE',
			{reference => 'OME::DataType::Column'}]
    };

    return $self;
}


1;

