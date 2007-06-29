#!/usr/bin/perl

use strict;
use Spiral;
use HeatMap;

if( scalar( @ARGV ) < 2 ) {
	print "Simple usage is:\n".
	      "./psTree2SVG_discreteState.pl infile.ps outfile.svg\n";
	exit;
}

my ($psFile, $savePath, $showVals, $showLabels) = @ARGV;

my $threshold = 1;
my ($unique_lines, $labelPositions) = parsePSFile( $psFile, $threshold );
print2SVG($unique_lines, $labelPositions, $savePath, $showVals, {
	markerRadius => 3,
	markerStrokeWidth => 1
});

########################################################
# Parse the lines & labels from the postscript file.
sub parsePSFile {
	my ( $psFile, $threshold ) = @_;
	open( PSFILE, "< $psFile")
		or die "Couldn't open $psFile for reading.";
	my $currentBlock = "header";
	my ($labelX, $labelY);
	my @unique_lines; # Each entry is hash with keys { x1, y1, x2, y2 }
	my @labelPositions; # Each entry is hash with keys { x, y, \@labels }, where \@labels is a list of labels
	
	while( my $line = <PSFILE> ) {
		if( $currentBlock eq "header" ) {
			if( $line =~ m/setlinewidth newpath/ ) {
				$currentBlock = "lines";
				next;
			}
		# Parse out lines
		} elsif( $currentBlock eq "lines" ) {
			if( $line =~ m/^\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+l$/ ) {
				my ( $x1, $y1, $x2, $y2 ) = ( $1, $2, $3, $4 );
				my $is_unique = 1;
				foreach my $unique_line( @unique_lines ) {
					my $discrepancy = 
						sqrt( ( $x1 - $unique_line->{x1} )**2 + 
						      ( $y1 - $unique_line->{y1} )**2) + 
						sqrt( ( $x2 - $unique_line->{x2} )**2 + 
						      ( $y2 - $unique_line->{y2} )**2);
					if( $discrepancy < $threshold ) {
						$is_unique = 0;
						last;
					}
				}
				if( $is_unique ) {
					push( @unique_lines, { x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2 } );
				}
			} else {
				$currentBlock = "labels";
				next;
			}
		# Parse out labels
		} elsif( $currentBlock eq "labels" ) {
			if( $line =~ m/^\s*([\d\.]+)\s+([\d\.]+)\s+translate/ ) {
				($labelX, $labelY) = ( $1, $2 );
			} elsif( $line =~ m/^\s*\((.+)\)\s+show/ ) {
				my $label = $1;
				my $is_unique = 1;
				my $labelPos;
				foreach $labelPos( @labelPositions ) {
					my $discrepancy = 
						sqrt( ( $labelX - $labelPos->{'x'} ) ** 2 + 
						      ( $labelY - $labelPos->{'y'} ) ** 2 );
					if( $discrepancy < $threshold ) {
						push( @{ $labelPos->{ labels } }, $label );
						$is_unique = 0;
						last;
					}
				}
				if( $is_unique ) {
					push( @labelPositions, { 'x' => $labelX, 'y' => $labelY, labels => [$label] } );
				}
			}
		}
	
	}
	
	close( PSFILE );
	return (\@unique_lines, \@labelPositions);
}
	

########################################################
# Print to an SVG file.
sub print2SVG {
	my ($unique_lines, $labelPositions, $svgSavePath, $showVals, $options) = @_;


	# Find the range for the heat map
	my @values;
	foreach my $labelPos ( @$labelPositions ) {
		foreach my $label( sort( @{ $labelPos->{ labels } } ) ) {
			my $value = parse_label( $label );
			push( @values, $value );
		}
	}
	my $heatMap = new HeatMap( 'Days since molting', \@values, { numBins => 7 } );
	if( $showVals ) {
		$showVals = [ split( ',', $showVals ) ];
	}

	# Print the lines 	
	my $linesSVG = "";
	my $line_template = '<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" style="stroke:rgb(99,99,99); stroke-width:2"/>'."\n";
	$linesSVG .= "\n\n<g id='dendogram_lines'>\n\n";
	foreach my $line ( @$unique_lines ) {
		$linesSVG .= sprintf( $line_template, $line->{x1}, -1 * $line->{y1}, $line->{x2}, -1 * $line->{y2} );
	}
	$linesSVG .= "\n\n</g>\n\n";

	# Print the markers
	my $markersSVG = "";
	my $labelFontSize = 8;
	my $markerRadius = ( exists $options->{ markerRadius } ? $options->{markerRadius} : 2 );
	my $markerStrokeWidth = ( exists $options->{ markerStrokeWidth } 
		? $options->{markerStrokeWidth} : 
		2 / 3 * $markerRadius );
	my $markerOuterRadius = $markerRadius + $markerStrokeWidth / 2;
	my $label_template = '<circle id="%s" cx="%.2f" cy= "%.2f" stroke="black" stroke-width="'.($markerStrokeWidth).'" r="'.($markerRadius).'" opacity=".8" %s/>'."\n".
		( $showLabels ? "<text x='%.2f' y='%.2f' font-size='%d' text-anchor='start' opacity='.7'>%s</text>\n" : '' );
	my $spiral = new Spiral( $markerOuterRadius );
	# Print the labels
	my $group_id = 1;
	my ($yMax, $xMax) = (0, 0);
	foreach my $labelPos ( @$labelPositions ) {
		# Draw the labels in a spiral radiating from the twig endpoint
		$spiral->resetAndRecenter( $labelPos->{'x'}, $labelPos->{'y'} );
		my $num_labels = scalar(  @{ $labelPos->{ labels } } );
		$yMax = $labelPos->{'y'} 
			if( $yMax < $labelPos->{'y'} );
		$xMax = $labelPos->{'x'} 
			if( $xMax < $labelPos->{'x'} );
		my ($r, $spiral_string, $rgb_sums);
		# Parse & build IDs so we can sort the list by observational values instead of label
		my @entries = ();
		foreach my $label( sort( @{ $labelPos->{ labels } } ) ) {
			my $value = parse_label( $label );
			push( @entries, { value => $value, id => $label } );
		}
		foreach my $entry( sort( { $a->{ value } <=>  $b->{ value } } @entries ) ) {
			my $theta = $spiral->getTheta();
			$r = $spiral->getR_incTheta();
			my $x = cos( $theta )*$r;
			my $y = sin( $theta )*$r;
			my $id  = $entry->{ id };
			# Get heat map color
			my $val = $entry->{ value };
			my $rgb = $heatMap->getRGBColorFromValue( $val );
			my $colorString = 'fill="rgb('.join(',', @$rgb ).')"';
			# Begin to calculate the average color for the whole group
			for( my $i = 0; $i < scalar( @$rgb ); $i++ ) {
				$rgb_sums->[ $i ] += $rgb->[ $i ];
			}
			$spiral_string .= sprintf( $label_template, 
				$id, 
				$labelPos->{'x'} + $x,
				$y - $labelPos->{'y'},
				$colorString,
				( $showLabels ? (
					$labelPos->{'x'} + $x,
					$y - $labelPos->{'y'} + $labelFontSize / 2,
					$labelFontSize, 
					$id ) : ()
				)
			) . "\t<!-- Val: $val -->\n";
		}
		my $rgb_avgs;
		foreach my $intensity( @$rgb_sums ) {
			push( @$rgb_avgs, sprintf( '%d', $intensity / $num_labels ) );
		}
		$markersSVG .= "\n\n<g id='group_$group_id'>\n\n";
		$markersSVG .= sprintf( "<circle cx='%d' cy='%d' r='%d' stroke='black' stroke-width='2' fill='rgb(%d,%d,%d)' opacity='.3'/>\n\n", $labelPos->{'x'}, -1 * $labelPos->{'y'},  ($r + 2*$markerRadius), @$rgb_avgs )
			if( @entries > 1 );
		$markersSVG .= $spiral_string;
		$markersSVG .= "\n\n</g>\n\n";
		$group_id ++;
	}
	
	open( SVG_OUT, "> $svgSavePath" )
		or die "Couldn't open $svgSavePath for writing.";
	
	my $margin = 20;
	my $height = sprintf( '%d', $yMax + $markerOuterRadius + 2*$margin );
	my $width  = sprintf( '%d', $xMax + $markerOuterRadius + 2*$margin );
	my $verticalOffset = sprintf( '%d', $yMax + $markerOuterRadius + $margin );
	
	# print header
print SVG_OUT <<END;
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="$width" height="$height" version="1.1"
xmlns="http://www.w3.org/2000/svg">
	<g id='dendogram_and_labels' transform="translate(0,$verticalOffset)">

END
	# Print the contesnts, legend & footer
	print SVG_OUT $linesSVG.$markersSVG;
	print SVG_OUT "\n\n\n</g>".
 		$heatMap->getLegend( $showVals, {
 			x_offset => 30, 
 			y_offset => 30
 		} ).
		"</svg>\n";
	
	close( SVG_OUT );
} 

sub parse_label {
	my $label = shift;
	$label =~ m/^\w?D(\d+)(\w\d+)\s*$/
		or die "Couldn't parse '$label'";
	my $value = $1;
	return $value;
}