#!/usr/bin/perl

use strict;
use HeatMap;
use Getopt::Long;


if( scalar( @ARGV ) < 2 ) {
	print "Simple usage is:\n".
	      "./psTree2SVG_coloredTree.pl infile.ps outfile.svg --label WRM_00 --label WRM_01 --category Day1 --category Day4 --value 1 --value 4\n";
	exit;
}

my $psFile   = shift @ARGV;
my $savePath = shift @ARGV;

###################################################################
# Convert from Sample%d which are labels in the PS file into
# actual SampleLabels/SampleValues for the SVG
###################################################################
my @sampleLabels;
my @sampleCategories;
my @sampleValues;
my $showLabels = '';
GetOptions('label=s' => \@sampleLabels,
		   'value=s' => \@sampleValues,
		   'category=s' => \@sampleCategories,
		   'showLabels!' => \$showLabels);
		   
# by default arbitrarily assign categories values 1...n
if (not scalar @sampleValues) {
	my %catNumLUT;

	# figure out category -> value mapping
	foreach(@sampleCategories){
		$catNumLUT{$_} = "";
	}
	my $i=1;
	foreach (sort(keys %catNumLUT)) {
		$catNumLUT{$_}= $i++;
	}
	# apply category->value mapping
	foreach (@sampleCategories){
		push (@sampleValues, $catNumLUT{$_});
	}
}

if (scalar @sampleLabels != scalar @sampleCategories) {
	print "ERROR: number of sample categories (--category) needs to match number of sample labels (--label)\n";
	exit(-1);
}

my %sampleLabelsKey;
my %sampleValuesKey;
my %sampleCategoriesKey;

my $i=1;
foreach (@sampleLabels) {
	$sampleLabelsKey{sprintf("Sample%d",$i++)} = $_;
}
$i=1;
foreach (@sampleCategories) {
	$sampleCategoriesKey{sprintf("Sample%d",$i++)} = $_;
}
$i=1;
foreach (@sampleValues) {
	$sampleValuesKey{sprintf("Sample%d",$i++)} = $_;
}

my ($nodes, $nodeDists, $connectedNodes) = parsePSFile( $psFile );

# Label Nodes
foreach (@$nodes) {
	if($_->{isLeaf}) {
		my $sampleHashKey = $_->{label};
		$_->{label}    = $sampleLabelsKey{$sampleHashKey};
		$_->{value}    = $sampleValuesKey{$sampleHashKey};
		$_->{category} = $sampleCategoriesKey{$sampleHashKey};
	}
}

#foreach (@$nodes) {
#		print "$_->{label} $_->{value} $_->{category}\n";
#}

$nodes = oozingPaint($nodes, $nodeDists, $connectedNodes, {} );

# ShowValues are the unique values in sampleValues
my @showValues = (1..scalar @sampleValues);

printNodes2SVG( $nodes, $connectedNodes, $savePath, \@showValues, {
	lineWidth         => 1,
	markerRadius      => 5,
	markerStrokeWidth => 0,
	printMarkers      => 1,
	multipleShapes    => 1, # otherwise, all categories are circles just with different colors
	showLabels        => $showLabels,
# ABSOLUTELY WRONG, catNames does some ordering weirdness	categoryNames     => \@sampleCategories,
});

########################################################
# Parse the lines & labels from the postscript file.
sub parsePSFile {
	my ( $psFile ) = @_;
	open( PSFILE, "< $psFile")
		or die "Couldn't open $psFile for reading.";
	my $currentBlock = "header";
	my ($labelX, $labelY);
	my @nodes;
	my @nodeDists;
	my @connectedNodes; # could be derived from @nodeDists. Some queries are easier on this structure than @nodeDists.
	
	while( my $line = <PSFILE> ) {
		if( $currentBlock eq "header" ) {
			if( $line =~ m/setlinewidth newpath/ ) {
				$currentBlock = "lines";
				next;
			}
		# Parse lines to get nodes and edges
		} elsif( $currentBlock eq "lines" ) {
			if( $line =~ m/^\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+l$/ ) {
				my ( $x1, $y1, $x2, $y2 ) = ( $1, $2, $3, $4 );
				# Identify the p1_Node, expand the node list if p1 is a new node
				my $p1_Node = -1;
				for my $i (0..(scalar( @nodes )-1)) {
					my $node = $nodes[ $i ];
					if( $node->{ 'x' } == $x1 && $node->{ 'y' } == $y1 ) {
						$p1_Node = $i;
						last;
					}
				}
				if( $p1_Node == -1 ) {
					push( @nodes, { 'x' => $x1, 'y' => $y1 } );
					$p1_Node = scalar( @nodes ) - 1;
				}
				# Identify the p2_Node, expand the node list if p2 is a new node
				my $p2_Node = -1;
				for my $i (0..(scalar( @nodes )-1)) {
					my $node = $nodes[ $i ];
					if( $node->{ 'x' } == $x2 && $node->{ 'y' } == $y2 ) {
						$p2_Node = $i;
						last;
					}
				}
				if( $p2_Node == -1 ) {
					push( @nodes, { 'x' => $x2, 'y' => $y2 } );
					$p2_Node = scalar( @nodes ) - 1;
				}
				# Connect the p1 & p2 nodes & record the distance between them.
				my $lineLength = sqrt( ($x1 - $x2) **2 + ($y1 - $y2) **2 );
				$nodeDists[ $p1_Node, $p2_Node ] = $lineLength;
				$nodeDists[ $p2_Node, $p1_Node ] = $lineLength;
				push( @{ $connectedNodes[ $p1_Node ] }, $p2_Node );
				push( @{ $connectedNodes[ $p2_Node ] }, $p1_Node );
			} else {
				$currentBlock = "labels";
				next;
			}
		# Parse out labels
		} elsif( $currentBlock eq "labels" ) {
			if( $line =~ m/^\s*([\d\.]+)\s+([\d\.]+)\s+translate/ ) {
				($labelX, $labelY) = ( $1, $2 );
				# Only keep two decimal places because that's as many as the lines have
				$labelX = sprintf("%.2f", $labelX );
				$labelY = sprintf("%.2f", $labelY );
			} elsif( $line =~ m/^\s*\((.+)\)\s+show/ ) {
				my $label = $1;
				
				# Match the labels with nodes
				for my $i (0..(scalar( @nodes )-1)) {
					my $node = $nodes[ $i ];
					if( $node->{ 'x' } == $labelX && $node->{ 'y' } == $labelY ) {
						$node->{ label }    = $label;
						$node->{ isLeaf }   = 1;
						last;
					}
				}
			}
		}
	
	}
	
	close( PSFILE );	
	
	return ( \@nodes, \@nodeDists, \@connectedNodes);
}


########################################################
# Color every node using an 'oozing paint' algorithm
sub oozingPaint {
	my ($nodes, $nodeDists, $connectedNodes, $options) = @_;

	# Identify leaf nodes
	my @leafNodes = ();
	my @notLeafNodes = ();
	for my $i (0..(scalar( @$nodes )-1)) {
		if( exists $nodes->[ $i ]->{ isLeaf } ) {
			push( @leafNodes, $i );
		} else {
			push( @notLeafNodes, $i );
		}
	}
	
	# Determine path distances from leaf nodes to all other nodes
	my @pathDistsBwNodes = ();
	foreach my $leafNodeIndex ( @leafNodes ) {
		my %inspectedNodes = ();
		# Establish a list of adjacent nodes to visit
		my @nodesToVisit = @{ $connectedNodes->[ $leafNodeIndex ] };
		# Establish the path distance to adjacent nodes
		foreach my $i ( @nodesToVisit ) {
			$inspectedNodes{$i} = 1;
			$pathDistsBwNodes[$leafNodeIndex][$i] = $nodeDists->[ $leafNodeIndex, $i ];
		}
		# Measure path distances to other nodes
		while( @nodesToVisit ) {
			# pop a node from the list
			my $nodeIndex = pop( @nodesToVisit );
			# Find adjacent nodes
			my @candidateVisitors = grep( 
				( not exists $inspectedNodes{$_} ), 
				@{ $connectedNodes->[ $nodeIndex ] } );
			# Add adjacent nodes to the list
			push( @nodesToVisit, @candidateVisitors );
			# Calculate the distance to those nodes
			foreach my $i ( @candidateVisitors ) {
				$inspectedNodes{$i} = 1;
				$pathDistsBwNodes[$leafNodeIndex][$i] = 
					$pathDistsBwNodes[$leafNodeIndex][$nodeIndex] + $nodeDists->[ $nodeIndex, $i ];
				$pathDistsBwNodes[$i][$leafNodeIndex] = 
					$pathDistsBwNodes[$leafNodeIndex][$nodeIndex] + $nodeDists->[ $nodeIndex, $i ];
			}
		}
	}

	my $maxDistBwNodes = 0;
	foreach my $i ( 0..(scalar( @$nodes )-1) ) {
		foreach my $j ( 0..(scalar( @$nodes )-1) ) {
			$maxDistBwNodes = $nodeDists->[$i,$j]
				if( $maxDistBwNodes < $nodeDists->[$i,$j] );			
		}
	}


	# Establish mean path distance between leaf nodes to use as a threshold
	# calculate some other stats too for yucks
	my $sumPathDistBwLeaves = 0;
	my $numPathsBwLeaves = 0;
	my $maxPathDistBwLeaves = 0;
	my @interLeafPathDists = ();
	foreach my $i ( @leafNodes ) {
		foreach my $j ( @leafNodes ) {
			next unless $j > $i;
			push( @interLeafPathDists, $pathDistsBwNodes[$i][$j] );
			$sumPathDistBwLeaves += $pathDistsBwNodes[$i][$j];
			$numPathsBwLeaves ++;
			$maxPathDistBwLeaves = $pathDistsBwNodes[$i][$j]
				if( $maxPathDistBwLeaves < $pathDistsBwNodes[$i][$j] );
		}
	}
	@interLeafPathDists = sort( @interLeafPathDists );
	my $medianPathDistBwLeaves = $interLeafPathDists[ sprintf( '%.0f', scalar( length( @interLeafPathDists ) ) / 2 ) ];
	my $meanPathDistBwLeaves = $sumPathDistBwLeaves / $numPathsBwLeaves;
#	my $theshold = $meanPathDistBwLeaves;
	my $theshold = $maxDistBwNodes + 1;
#print "theshold is $theshold\nmax is $maxPathDistBwLeaves\nmean is $meanPathDistBwLeaves\nmedian is $medianPathDistBwLeaves\nmaxDistBwNodes is $maxDistBwNodes\n";
	
	# Find the range of values for the heat map
	my @values;
	foreach my $leafNodeIndex ( @leafNodes ) {
		my $leafNode = $nodes->[ $leafNodeIndex ];
		push( @values, $leafNode->{ value } );
	}
	my $heatMap = new HeatMap( '', \@values );


	# Make every leaf node ooze its color to every non-leaf node
	# How much color is oozed is a function of the distance from the node
	# Color stops oozing at $meanPathDistBwLeaves away from the leaf node
	foreach my $leafNodeIndex ( @leafNodes ) {
		my $leafNode = $nodes->[ $leafNodeIndex ];
		# Color in the leaf node
		my $leafRGB = $heatMap->getRGBColorFromValue( $leafNode->{ value } );
		$leafNode->{ rgb } = $leafRGB;
		# Establish a list of nodes to visit 
		my @nodesToVisit;
		foreach my $i ( @notLeafNodes ) {
			push( @nodesToVisit, $i )
				if( $pathDistsBwNodes[$leafNodeIndex][$i] <= $theshold );
		}
		# Make a contribution to non-leaf nodes that are within the distance threshold
		foreach my $nodeIndex (@nodesToVisit) {
			my $node = $nodes->[ $nodeIndex ];
			# Contribute to this node's color
			$node->{ numColorContributors } ++;
			foreach my $c ( 0..2 ) {
				push( @{ $node->{ colorsContributors }->[$c] }, $leafRGB->[$c] );
			}
			# Record the strength of this contribution
			push( @{ $node->{ colorWeights } }, 
				($theshold - $pathDistsBwNodes[$leafNodeIndex][ $nodeIndex ] ) / $theshold );
		}
	}
	
	# Calculate the final color of each non-Leaf node
	for my $i (0..(scalar( @$nodes )-1)) {
		next if( exists $nodes->[ $i ]->{ isLeaf } );
		my $node = $nodes->[ $i ];
		if( $node->{ numColorContributors } == 0 )  {
			print "node $i (".$node->{'x'}.", ".$node->{'y'}.") has no contributors\n";
			$node->{ rgb } = [0,0,0];
		} else {
			my $weightSums = 0;
			my @colorSums = ();
			foreach my $contributionIndex ( 0..scalar( @{ $node->{ colorWeights } } )-1 ) {
				foreach my $c ( 0..2 ) {
					$colorSums[$c] += $node->{ colorsContributors }->[$c]->[$contributionIndex] * $node->{ colorWeights }->[$contributionIndex];
				}
				$weightSums += $node->{ colorWeights }->[$contributionIndex];
			}
			foreach my $c ( 0..2 ) {
				$node->{ rgb }->[$c] = sprintf( '%.0f', $colorSums[$c] / $weightSums )
			}
		}
	}
	
	# Return the colored list of nodes
	return $nodes;
}


########################################################
# Print to an SVG file.
sub printNodes2SVG {
	my ($nodes, $connectedNodes, $svgSavePath, $showVals, $options) = @_;
	
	# Find the range of values for the heat map
	my @values;
	my @categories;
	
	for my $i (0..(scalar( @$nodes )-1)) {
		next unless exists( $nodes->[$i]->{ isLeaf } );
		push( @values, $nodes->[$i]->{ value } );
		push( @categories, $nodes->[$i]->{ category } );
	}
	
	# Set up category:id mappings	
	@categories = sort(@categories);
	my %categoryID;
	foreach (@categories) {
		$categoryID{$_} = scalar( keys( %categoryID ) )
			unless exists $categoryID{ $_ };
	}
	my $numCategories = scalar (keys %categoryID);
			
	my $heatMap = new HeatMap( 'HeatMap Legend', \@values );
		
	# Constants
	my $margin        = ( exists $options->{ margin } ? $options->{margin} : 20 );
	my $lineWidth     = ( exists $options->{ lineWidth } ? $options->{lineWidth} : 2 );
	my $labelFontSize = ( exists $options->{ labelFontSize } ? $options->{labelFontSize} : 8 );
	my $markerRadius  = ( exists $options->{ markerRadius } ? $options->{markerRadius} : 2 );
	my $markerStrokeWidth = ( exists $options->{ markerStrokeWidth } 
		? $options->{markerStrokeWidth} : 
		2 / 3 * $markerRadius );
	my $markerOuterRadius = $markerRadius + $markerStrokeWidth / 2;
	my $showLabels  = ( exists $options->{ showLabels } ? $options->{showLabels} : 1 );

	# Print the lines connecting nodes
	my @drawnEdges = [];
	my $gradientsSVG .= "\n\n<defs>\n\n";
	my $linesSVG .= "\n\n<g id='dendogram_lines'>\n\n";
	my ($yMax, $xMax) = (0, 0);
	for my $i (0..(scalar( @$nodes )-1)) {
		my $rgb1 = $nodes->[ $i ]->{ rgb };
		my $colorString1 = 'rgb('.join(',', @$rgb1 ).')';
		my @adjacentNodes = @{ $connectedNodes->[ $i ] };
		$yMax = $nodes->[$i]->{'y'} if( $yMax < $nodes->[$i]->{'y'} );
		$xMax = $nodes->[$i]->{'x'} if( $xMax < $nodes->[$i]->{'x'} );
		foreach my $j ( @adjacentNodes ) {
			# is it drawn yet?
			next if( $drawnEdges[ $i, $j ] );
			# Mark it drawn
			$drawnEdges[ $i, $j ] = 1;
			$drawnEdges[ $j, $i ] = 1;
			# Draw it
			my $rgb2 = $nodes->[ $j ]->{ rgb };
			my $colorString2 = 'rgb('.join(',', @$rgb2 ).')';
			my $gradientID = $i.'_'.$j;
			my ($line, $gradient ) = getLineAndGradient( $nodes->[$i]->{'x'}, -1 * $nodes->[$i]->{'y'}, $nodes->[$j]->{'x'}, -1 * $nodes->[$j]->{'y'}, $gradientID, $lineWidth, $colorString1, $colorString2 );
			$gradientsSVG .= $gradient;
			$linesSVG .= $line;
		}
	}
	$linesSVG .= "\n\n</g>\n\n";
	$gradientsSVG .= "\n\n</defs>\n\n";

	# Print the markers if asked
	my $markersSVG = "";
	my $categoryLegend = "";
	if( $options->{ printMarkers } ) {
		
		# Set up category templates: star, triangle, square, circle+. So if more
		# than four categories, the fifth etc. categories will also be circles
		my @label_templates;
		if ($options->{ multipleShapes } ) {
			# Star
			my $points = '';
			my $pi = atan2(0,-1);
			my $aspectRatio = 0.3 * $markerRadius;
			foreach my $i (0..4) {
				my $theta1 = 2*$pi/5*$i + $pi / 2;
				my $theta2 = 2*$pi/5*$i + $pi / 2 + 2 * $pi / 10;
				$points .= sprintf( '%.2f,%.2f %.2f,%.2f ', 
					$markerRadius * cos($theta1), $markerRadius * sin($theta1),
					$aspectRatio  * cos($theta2), $aspectRatio  * sin($theta2)
				);
			}
			$label_templates[0] = '<polygon id="%s" transform = "translate(%.2f,%.2f)" stroke="black" stroke-width="'.($markerStrokeWidth).'" points="'.$points.'" opacity=".8" %s />'."\n";

			# Triangle
			my $points = '';
			my $pi = atan2(0,-1);
			foreach my $i (0..2) {
				my $theta = 2*$pi/3*$i + $pi / 2;
				$points .= sprintf( '%.2f,%.2f ', 
					$markerRadius * cos($theta), $markerRadius * sin($theta),
				);
			}
			$label_templates[1] = '<polygon id="%s" transform = "translate(%.2f,%.2f)" stroke="black" stroke-width="'.($markerStrokeWidth).'" points="'.$points.'" opacity=".8" %s />'."\n";		
			# Square
			my $points = '';
			my $pi = atan2(0,-1);
			foreach my $i (0..3) {
				my $theta = -$pi/4 + $pi/2*$i ;
				$points .= sprintf( '%.2f,%.2f ', 
					$markerRadius * cos($theta), $markerRadius * sin($theta),
				);
			}
			$label_templates[2] = '<polygon id="%s" transform = "translate(%.2f,%.2f)" stroke="black" stroke-width="'.($markerStrokeWidth).'" points="'.$points.'" opacity=".8" %s />'."\n";		
			
			# The other categories are rendered as circles
			for (my $i=3; $i<$numCategories; $i++) {
				$label_templates[$i] = '<circle id="%s" cx="%.2f" cy= "%.2f" stroke="black" stroke-width="'.($markerStrokeWidth).'" r="'.($markerRadius).'" opacity=".8" %s/>'."\n";
			}
		} else {
			# All categories are rendered as circles
			for (my $i=0; $i<$numCategories; $i++) {
				$label_templates[$i] = '<circle id="%s" cx="%.2f" cy= "%.2f" stroke="black" stroke-width="'.($markerStrokeWidth).'" r="'.($markerRadius).'" opacity=".8" %s/>'."\n";
			}
		}
        # Add text to the label_template markers
		$_ .= ( $showLabels ? "<text x='%.2f' y='%.2f' font-size='%d' text-anchor='start' opacity='.7'>%s</text>\n" : '' )
			foreach @label_templates;
			
		# Print the markers
		my %categoryIDcolor; # figure out what colors are used for which category
		for my $i (0..(scalar( @$nodes )-1)) {
			next unless exists( $nodes->[$i]->{ isLeaf } );
			my $x = $nodes->[$i]->{ 'x' };
			my $y = $nodes->[$i]->{ 'y' };
			
			my $rgb         = $nodes->[ $i ]->{ rgb };
			my $colorString = 'fill="rgb('.join(',', @$rgb ).')"';
			my $catID = $categoryID{ $nodes->[$i]->{ category } };
			$categoryIDcolor{$catID} = $colorString;
			$markersSVG .= sprintf( $label_templates[$catID], 
				$nodes->[$i]->{ label }, 
				$x,
				-1 * $y,
				$colorString,
				( $showLabels ? (
					$x,
					-1 * $y + $labelFontSize / 2,
					$labelFontSize, 
					$nodes->[$i]->{ label } ) : ()
				),"\n"
			);
		}
		
		# Draw up categorical legend
		$categoryLegend = '<g id="CategoricalLegend" transform = "translate(%.2f,%.2f) scale(3)">'."\n";
		my @categoryNames = sort keys %categoryID;

		my $legendLineHeight = ( $labelFontSize > 2*$markerRadius ? $labelFontSize : 2*$markerRadius );
		foreach my $i ( 0..(scalar(@categoryNames)-1) ) {
			my $category = $categoryNames[$i];
			my $categoryName = $category;
			
			if( $options->{ categoryNames } ) {
				my $index = ord($category) - ord("A");
				$categoryName = $options->{ categoryNames }->[ $index ];
			}
			my $catID = $categoryID{ $category };
			my $colorString = $categoryIDcolor{$catID};
			$categoryLegend .= "\t".sprintf( $label_templates[$catID], 
				$category, 
				0,
				1.5 * $legendLineHeight * $i,
				$colorString
			)." <text x='".2*$markerRadius."' y='".(1.5 * $legendLineHeight * $i + $markerRadius)."' font-size='$labelFontSize' text-anchor='start' opacity='1'>$categoryName</text>\n";
		}
		$categoryLegend .= "</g>\n";


	}
	open( SVG_OUT, "> $svgSavePath" )
		or die "Couldn't open $svgSavePath for writing.";
	
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
	print SVG_OUT $gradientsSVG."<g id='lines'>".$linesSVG."</g><g id='markers'>\n".$markersSVG."</g>";
	print SVG_OUT "\n\n\n</g>".
 		$heatMap->getLegend( $showVals, {
 			x_offset => 30, 
 			y_offset => 30,
 			noClip   => 1,
 		} )."\n\n".
 		sprintf( $categoryLegend, 30, 300).
		"</svg>\n";
	close( SVG_OUT );
} 

sub getLineAndGradient {
	my ( $x1, $y1, $x2, $y2, $gradientID, $lineWidth, $colorString1, $colorString2 ) = @_;
	my $theta = atan2( $y2-$y1, $x2-$x1 );
	my $length = sqrt( ($x1 - $x2) **2 + ($y1 - $y2) **2 );
	my $rect_template = '<g transform="translate(%.2f %.2f) rotate(%.2f)"><rect x="0" y="%.2f" width="%.2f" height="%.2f" fill="url(#%s)" stroke-width="0"/></g>'."\n";
	
	my $pi = atan2( 0,-1 );
	my $thetaDegrees = $theta / $pi * 180;
	my $rect = sprintf( $rect_template, $x1, $y1, $thetaDegrees, -1 * $lineWidth / 2, $length, $lineWidth, $gradientID );
	
	my $gradient_template = '<linearGradient id="%s"><stop offset="0%%" stop-color="%s" /><stop offset="100%%" stop-color="%s" /></linearGradient>'."\n";
	my $gradient;
		$gradient = sprintf( $gradient_template, $gradientID, $colorString1, $colorString2 );
	
	return ( $rect, $gradient );
}