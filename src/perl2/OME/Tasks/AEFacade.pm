# OME/Tasks/AEFacade.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:  JM Burel <jburel@dundee.ac.uk>
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


package OME::Tasks::AEFacade;


our $VERSION = 2.000_000;

=pod

=head1 WARNING!

This class is a quick and dirty implementation for alpha. This class will be removed and its functionality moved to other places. 
The most likely place will be under OME::Web, since this is a web utility function.

This warning added by Josiah <siah@nih.gov> based on correspondence with Jean-Marie & Andrea.

=cut

=head1 NAME

OME::Tasks::AEFacade 

=head1 SYNOPSIS

		
=head1 DESCRIPTION

=head1 METHODS 

=head2 
=cut








use strict ;
use OME::Analysis::AnalysisEngine;
use OME::Tasks::ChainManager;

#####################################################
# Constructor. This is not an instance method as well.
# new($session)

sub new {
	my ($class,$session) = @_ ;
	my  $self = {} ;
	$self->{session} = $session ;
	bless($self,$class) ;
	return  $self ;
}


#################
sub executeView{
	my $self=shift;
	my $session=$self->{session};
	my ($dataset,$nameView,$string,$nameFunction,$refh,$attributeType)=@_;
	my %user_inputs=();
	my @attributes=();
	my $engine = OME::Analysis::AnalysisEngine->new();
	my $cmanager = OME::Tasks::ChainManager->new($session);
	my $view=$self->{session}->Factory()->findObject("OME::AnalysisChain",
							name=>$nameView);
	print STDERR "chain===".$view->analysis_chain_id()."\n";
	my $node=$cmanager->getNode($view,$nameFunction);
print STDERR "nodeID===".$node->analysis_chain()->id()."\n";

	my $formal_input=$cmanager->getFormalInput($view,$node,$string);

	my $attribute = $session->Factory()->newAttribute($attributeType,undef,undef,$refh);
      push (@attributes,$attribute);

	$user_inputs{$node->id()}->{$formal_input->id()} =\@attributes;
	$engine->executeAnalysisView($session,$view,\%user_inputs,$dataset);
	return ;

}


=head1 AUTHOR

JM Burel (jburel@dundee.ac.uk)

=cut

1;

