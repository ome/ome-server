#!/usr/bin/perl -w

use File::Find;

my @ids;

sub wanted {
    push @ids, $_ if /^[0-9]+$/o;
}

sub getDims {
    my ($id) = @_;

    my $cmd = "./omeis Method=PixelsInfo PixelsID=${id}";
    my $result = `$cmd`;

    if ($result =~ /Dims=(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)/) {
        return ($1,$2,$3,$4,$5,$6);
    } else {
        die "Could not retrieve dimensions";
    }
}

sub setThumb {
    my ($id) = @_;

    my ($x,$y,$z,$c,$t,$bbp) = getDims($id);
    return if $c < 1;

    my $cmd = "./omeis Method=Composite PixelsID=${id} LevelBasis=geomean";

    $cmd .= " RedChannel=0,-4.0,4.0,1.0"    if $c > 0;
    $cmd .= " GreenChannel=1,-4.0,4.0,1.0"  if $c > 1;
    $cmd .= " BlueChannel=2,-4.0,4.0,1.0"   if $c > 2;

    use integer;
    my $theT = $t / 2;
    my $theZ = $z / 2;

    $cmd .= " theZ=${theZ} theT=${theT} SetThumb=1";

    print "$cmd\n";
    system($cmd);
}

find(\&wanted,"/OME/OMEIS/Pixels");

foreach my $id (@ids) {
    print "ID: $id\n";
    setThumb($id);
}
