package OME::Program::Definition;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $analysis = shift;
    
    my $self = {
	_analysis => $analysis
    };

    bless $self,$class;
}


sub Analysis { my $self = shift; return $self->{_analysis}; }
sub Factory { my $self = shift; return $self->{_analysis}->Factory(); }


sub startAnalysis {
    my ($self,$dataset) = @_;

    return 1;
}


sub analyzeOneImage {
    my ($self, $image, $parameters) = @_;

    return {};
}


sub finishAnalysis {
    my ($self) = @_;
}
