package Graphics;
use strict;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = ("");

# new
# ---

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self;
	my %params = @_;

	if (exists $params{width} and defined $params{width}) {
		$self->{width} = $params{width};
	} else {
		$self->{width} = 512;
	}

	if (exists $params{height} and defined $params{height}) {
		$self->{height} = $params{height};
	} else {
		$self->{height} = 512;
	}

	if (exists $params{theZ} and defined $params{theZ}) {
		$self->{theZ} = $params{theZ};
	} else {
		$self->{theZ} = 0;
	}

	if (exists $params{theT} and defined $params{theT}) {
		$self->{theT} = $params{theT};
	} else {
		$self->{theT} = 0;
	}

	
	bless $self,$class;
	return $self;
}


sub InitHash {
	my $self = shift;
	my %params = @_;

	if (exists $params{x0} and defined $params{x0}) {
		$self->{x0} = $params{x0};
	} else {
		$self->{x0} = [472,498,532,526,547,489,445,436,100];
	}
	
	if (exists $params{y0} and defined $params{y0}) {
		$self->{y0} = $params{y0};
	} else {
		$self->{y0} = [ 79, 93,181,282,292,226,216,198,100];
	}
	
	if (exists $params{x1} and defined $params{x1}) {
		$self->{x1} = $params{x1};
	} else {
		$self->{x1} = [405,219,576,361,360,228,363,559,200];
	}
	
	if (exists $params{y1} and defined $params{y1}) {
		$self->{y1} = $params{y1};
	} else {
		$self->{y1} = [247,270,631,502,585,547,753,457,100];
	}
	
	if (exists $params{z0} and defined $params{z0}) {
		$self->{z0} = $params{z0};
	} else {
		$self->{z0} = [  0,  0,  0,  0,  1,  1,  1,  1,  1];
	}
	
	if (exists $params{z1} and defined $params{z1}) {
		$self->{z1} = $params{z1};
	} else {
		$self->{z1} = [  1,  1,  1,  1,  2,  2,  2,  2,  2];
	}
	
	if (exists $params{t} and defined $params{t}) {
		$self->{t} = $params{t};
	} else {
		$self->{t}  = [  0,  0,  0,  0,  0,  0,  0,  0,  1];
	}
}


sub Draw {
}
1;

