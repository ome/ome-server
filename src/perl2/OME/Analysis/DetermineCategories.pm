# OME/module_execution/DetermineCategories.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Analysis::DetermineCategories;

use OME::Analysis::DefaultLoopHandler;
use XML::LibXML;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Analysis::DefaultLoopHandler);

# the classification system was built with the assumption that each image 
# will belong to one Category. the only way that can be guaranteed is for this
# algorithm to be fed exactly one attr per image. That is enforced in the 
# wrapper, not here. As a result, this code is capable of assigning multiple Categories.
sub postcalculateImage {
    my ($self) = @_;

	my @attrList = @{ $self->getImageInputs( $self->{_fi_criteria} ) }
		or die "No inputs found named ".$self->{_fi_criteria};
	foreach my $attrDat ( @attrList ) {
		# make a key from the semantic elements criteria list
		my $key = join( '-', map( $attrDat->{$_}, @{ $self->{_se_criteria} } ) );
		if (exists $self->{_unique_categories}->{ $key }) {
			# make a Category reference if we have a referent
			$self->newAttributes( CategoryRef => {
				Category => $self->{_unique_categories}->{ $key }
			});
		} else {
			# otherwise make a Category and a Category reference
			$self->{_unique_categories}->{ $key } = $self->newAttributes(
				Category => {
					CategoryGroup => $self->{_categoryGroup},
					Name          => $key
			});
			$self->newAttributes( CategoryRef => {
				Category => $self->{_unique_categories}->{ $key }
			});
		}
	}

}

sub precalculateDataset {
	my $self = shift;

	my $module                = $self->{_module};
	my $executionInstructions = $module->execution_instructions();
	if( defined $executionInstructions and $executionInstructions ne '' ) { 
		my $parser                = XML::LibXML->new();
		my $tree                  = $parser->parse_string( $executionInstructions );
		my $root                  = $tree->getDocumentElement();
		my $criteria = $root->getElementsByTagName( 'Criteria' );
		if( $criteria ) {
			$self->{_fi_criteria} = $criteria->getAttribute( 'FormalInput' );
			$self->{_se_criteria} = [ split( / /, $criteria->getAttribute( 'SemanticElements' ) ) ];
		} 
	}

	# auto detect criteria if it wasn't given in execution instructions
	unless ( exists $self->{_se_criteria} ) {
		my @imgFormalInputs = grep( $_->semantic_type->granularity eq 'I', @{ $module->inputs() } );
		die "Expected 1 formal input of image granularity. Got ".scalar(@imgFormalInputs)
			unless scalar(@imgFormalInputs) eq 1;
		my $fi = $imgFormalInputs[0];	
		$self->{_fi_criteria} = $fi->semantic_type();
		# default se criteria is every se in the st. se criteria is what determines class uniqueness
		$self->{_se_criteria} = $self->{_fi_criteria}->semantic_elements;
	}

	$self->{_categoryGroup} = $self->newAttributes( CategoryGroup => {
		 Name     => $self->{_fi_criteria} }
	);
		
}

1;
