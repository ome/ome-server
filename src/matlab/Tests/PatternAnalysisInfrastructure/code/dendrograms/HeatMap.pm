use strict;
package HeatMap;

use Carp;

=pod

=head1 HeatMap

=head1 Description

Generate heat map coloring for data that can be plotted on a single axis.

=head1 Synopsis

	use HeatMap;
	# Initalize an instance to the data range
	my $heatMap = new HeatMap( $units_label, \@values );
	# Get an rgb triplet for a given data point
	my $rgb = $heatMap->getRGBColorFromValue( $val );
	# Do something with the triplet. ex:
	my $colorString = 'fill="rgb('.join(',', @$rgb ).')"';

	# Get a legend to show the distribution of the data, and what colors corrospond to what observations.
	my $svgChunk = $heatMap->getLegend( $showNumericVals, $X_offset, $Y_offset, $makeStandAloneSVG );

=head1 Functions

=head2 new()

=head2 getRGBColorFromValue()

=head2 getLegend()

=cut

sub new {
	my ( $proto, $units, $values, $options ) = @_;
	my $class = ref( $proto ) || $proto;

	# Determine if values are numeric or categorical. If they are categorical, 
	# translate them into numeric values.
	my $category_numeric_values;
	my $category_names;
	if( grep( m/\D/, @$values ) ) {
		if( $options->{ value_numeric_values } ) {
			$category_numeric_values = $options->{ value_numeric_values }
		} else {
			foreach my $val ( sort( @$values ) ) {
				unless( exists( $category_numeric_values->{ $val } ) ) {
					$category_numeric_values->{$val} = scalar( keys( %$category_numeric_values ) );
				}
			}
		}
		@$values = map( $category_numeric_values->{ $_ }, @$values );
		$category_names = { map{ $category_numeric_values->{$_} => $_ } keys( %$category_numeric_values ) };
	}

	# Identify range of values	
	my ( $minVal, $maxVal );
	foreach my $val ( @$values ) {
		$minVal = $val
			if( (defined $val ) && ( (not defined $minVal) || ( $val < $minVal ) ) );
		$maxVal = $val
			if( (defined $val ) && ( (not defined $maxVal) || ( $val > $maxVal ) ) );
	}	
	my $range = ( $maxVal - $minVal );

	# Build histogram to describe distribution of values
	# This will be integrated into the legend.
	my $numBins  = ( exists $options->{ numBins } ? $options->{ numBins } : 10 );
	my $binWidth = $range / $numBins;
	my ( @thresholds, @binCounts, @binCenters );
	# Calculate the thresholds that divide one bin from another
	# Also, initialize the bin counts, and the position of the bin centers.
	foreach my $bin ( 0..($numBins-1) ) {
		$thresholds[ $bin - 1 ] = ( $minVal + ( $bin * $binWidth ) )
			if( $bin >= 1 );
		$binCounts[ $bin ] = 0;
		$binCenters[ $bin ] =
			$minVal + 
			( $binWidth / 2 ) + 
			( $bin * $binWidth);
	}
	# Count how many data points fall into each histogram
	foreach my $val ( @$values ) {
		next unless defined $val; # Don't consider undef points.
		my $bin;
		foreach my $threshold_index ( 0..(scalar( @thresholds ) - 1) ) {
			if( ( $val <= $thresholds[ $threshold_index ] ) ) {
				$bin = $threshold_index; 
				last;
			}
		}
		if( ( $val > $thresholds[ scalar( @thresholds ) - 1 ] ) ) {
			$bin = $numBins-1;
		}
		$binCounts[ $bin ] ++;
	}
	
	# Build color space lookup table that goes from Red to Green to Blue, 
	# and uses high intensity colors throughout
	my @colorSpace;
	my ( $R, $G, $B ) = (255, 0, 0);
	my @intensityVals;
	my $counter = 0;
	# Generate intensity values to iterate though
	for( my $i = 0; $i < 255; $i += 8 ) {
		push(@intensityVals, $i );
	}
	push( @intensityVals, 255 );
	my @revIntensityVals = sort( { $b <=> $a } @intensityVals );
	# Begin to generate RGB entries
	foreach $G ( @intensityVals ) {
		push( @colorSpace, [ $R, $G, $B ] );
		$counter++;
	}
	$G = 255;
	for( $R = 255, $B = 0; $R > 128; $R -= 8, $B += 8) {
		push( @colorSpace, [ $R, $G, $B ] );
		$counter++;
	}
	for( $B = 128; $B < 255; $B += 8, $R -= 8) {
		push( @colorSpace, [ $R, $G, $B ] );
		$counter++;
	}
	$R = 0;
	$B = 255;
	foreach $G ( @revIntensityVals ) {
		push( @colorSpace, [ $R, $G, $B ] );
		$counter++;
	}

	my $self = {
		units             => $units, 
		minVal            => $minVal,
		maxVal            => $maxVal,
		range             => $range,
		delta             => $range / ( scalar( @colorSpace ) - 1), 
		colorSpace        => \@colorSpace,
		colorSpaceEntries => scalar( @colorSpace ), 
		thresholds        => \@thresholds,
		binCounts         => \@binCounts,
		binCenters        => \@binCenters,
		category_numeric_values => $category_numeric_values,
		category_names          => $category_names,
	};
	bless $self, $class;
	
	return $self;
}

sub getLegend {
	# Extract input params
	my( $self, $showValsArray, $options ) = @_;
	$options = {} unless( $options );
	my $legendLabelFontSize = ( exists $options->{ legendLabelFontSize } ? 
		 $options->{ legendLabelFontSize } : 20 );
	my $legendFontSize = ( exists $options->{ legendFontSize } ? 
		 $options->{ legendFontSize } : 16 );
	my $xOffset = ( exists $options->{ x_offset } ? 
		 $options->{ x_offset } : 0 );
	my $yOffset = ( exists $options->{ y_offset } ? 
		 $options->{ y_offset } : $legendLabelFontSize );
	# Make a copy of the incoming array ref.
	my $showSpan;
	if( exists $options->{ showSpan } &&
	    scalar( @{ $options->{ showSpan } } ) > 0 ) {
		$showSpan = [ @{ $options->{ showSpan } } ];
	}
	
	
	my $labels = "<g id='labels'>\n";
	my $colorLegend;
	unless( exists( $options->{ noClip } ) ) {
		$colorLegend = "<g id='colorChart' clip-path='url(#histogram)'>\n";
	} else {
		$colorLegend = "<g id='colorChart'>\n";
	}
	my $xMin = 0;
	my $counter = 0;
	# Determine which values we will show on the legend
	if( defined $showValsArray ) {
		$showValsArray = [ sort( { $a <=> $b} @$showValsArray ) ];
	} else {
		foreach my $i ( 0..4 ) {
			push( @$showValsArray, sprintf( '%.2f', $self->{ minVal } + $self->{ range } * $i / 4 ) );
		}
	}

	# Draw the colors and labels of the legend
	my $val = $self->{ minVal };
	my $showVal = shift( @$showValsArray );
	my @binCenters = @{ $self->{ binCenters } };
	my $binSearchVal = shift( @binCenters );
	my @binXVals;
	my( $x, $y );;
	my @spanCoords;
	my $spanVal = ( $showSpan ? shift( @$showSpan ) : undef );
	$x = $xMin;
	my ($histoYMin, $histoYMax) = (10, 60);
	foreach my $colorEntry ( @{ $self->{ colorSpace } } ) {
		my ( $R, $G, $B ) = ( $colorEntry->[0], $colorEntry->[1], $colorEntry->[2] );
		$colorLegend .= "<line x1='$x' y1='$histoYMin' x2='$x' y2='$histoYMax' style='stroke:rgb($R,$G,$B); stroke-width:2'/>\n";
		# Add a label if we're at the value to label.
		if( ( ($val < $showVal) && ($val + $self->{ delta } > $showVal ) ) ||
		    ( $val == $showVal ) ) {
		    my $string;
		    if( defined( $self->{ category_names } ) ) {
		    	$string = $self->{ category_names }->{ sprintf( '%.0f', $showVal ) };
		    } else {
				if( $showVal =~ m/^\d+\.\d+$/ ) {
					$string = sprintf( '%.2f', $showVal);
				} else {
					$string = $showVal;
				}
			}
			$labels .= "<text x='$x' y='".($histoYMax+20)."' font-size='$legendFontSize' text-anchor='middle'>$string</text>\n";
			$showVal = shift( @$showValsArray );
		}
		# Record the x-coordinate of a histogram bin when we hit the center of one
		if( ( ($val < $binSearchVal) && ($val + $self->{ delta } > $binSearchVal ) ) ||
		    ( $val == $binSearchVal ) ) { 
			push( @binXVals, $x );
			$binSearchVal = shift( @binCenters );
		}
		# Record the bin start & end coordinates when we're at that value
		if( ( defined $spanVal ) && 
		    ( ( ($val < $spanVal) && ($val + $self->{ delta } > $spanVal ) ) ||
		      ( $val == $spanVal ) 
		    )
		  ) { 
			push( @spanCoords, $x );
			$spanVal = shift( @$showSpan );
		}
		$x += 2;
		$counter ++;
		$val += $self->{ delta };
	}
	$colorLegend .= "</g>\n";	
	$labels .= "</g>\n";
	my $maxX = $x;
	
	# Draw the histogram clipping mask on top of the color chart
	my $numBins  = scalar( @{ $self->{ binCounts } } );
	my @binCounts = @{ $self->{ binCounts } };
	my $maxBinCount = 0;
	foreach my $bin ( 0..($numBins-1) ) {
		$maxBinCount = $binCounts[ $bin ]
			if( $maxBinCount < $binCounts[ $bin ] );
	}
	my $histoYShortest = $histoYMax - 10; # A zero value in the histogram will be this y level, which guarantees it will be at least 10 pixels tall
	my $histUsableHeight = $histoYShortest - $histoYMin;
	confess "maxBinCount is 0" if $maxBinCount == 0;
	my $histYscale = $histUsableHeight / $maxBinCount;
	$colorLegend .= "\n\t<!-- Histogram clip mask to show the distribution of this variable. -->\n\n";
	$colorLegend .= "<clipPath id='histogram'>\n\t<path d='M $xMin $histoYMax L $xMin $histoYShortest ";
	foreach my $bin ( 0..($numBins - 1 ) ) {
		$x = $binXVals[ $bin ];
		$y = $histoYShortest - $binCounts[ $bin ] * $histYscale;
		$colorLegend .= "L $x $y ";
	}
	$colorLegend .= "L $maxX $histoYShortest L $maxX $histoYMax L $xMin $histoYMax' ";
	$colorLegend .= "fill-rule='nonzero'/>\n</clipPath>\n";
	
	
	# Draw an ROI around a range of the histogram if requested
	my $interestingRegionOfHistogram = "<g id='selectedSpan'>\n";
	if( $showSpan ) {
		my $width = ( scalar( @spanCoords ) == 2 ? 
			( $spanCoords[1] - $spanCoords[0] ) :
			( $maxX - $spanCoords[0] ) );
		$interestingRegionOfHistogram .= "<rect x='".($xMin + $spanCoords[0])."' ".
		                  "width='$width' ".
		                  "y='$histoYMin' ".
		                  "height='".( $histoYMax - $histoYMin)."' ".
		                  "fill='none' style='stroke:black; stroke-width:1;'/>";
	}
	$interestingRegionOfHistogram .= "</g>\n\n";
	
	# Add the title to the text portion of the legend,
	$labels .= "<text x='".($maxX/2)."' y='0' font-size='$legendLabelFontSize' text-anchor='middle'>".$self->{ units }."</text>\n";

	
	# Compile all the bits into a legend
	my $svgChunk = 
		"<g id='HeatMapLegend' transform ='translate( $xOffset, $yOffset )' >\n".
		"\n\t <!-- Labels -->\n".$labels.
		"\n\t<!-- Heatmap and histogram -->\n".$colorLegend.
		"\n\t<!-- Selected region of histogram -->\n".$interestingRegionOfHistogram."</g>";

	# return a section of svg unless a complete svg file was requested
	return $svgChunk
		unless $options->{ embedInSVG };
	
	# Make the legend a complete svg file if it was requested
	my $svg = <<END;
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">
END
	$svg .= $svgChunk;
	$svg .= "\n\n</svg>\n";
	return $svg;
}

sub getRGBColorFromValue {
	my( $self, $val ) = @_;
	if( defined( $self->{ category_numeric_values } ) ) {
		$val = $self->{ category_numeric_values }->{ $val };
	}
	my $ratio = ( $val - $self->{ minVal } ) / $self->{ range };
	return $self->{ colorSpace }[ sprintf( '%d', 
		($ratio * ( $self->{ colorSpaceEntries } - 1 ) )
	) ];
}

1;