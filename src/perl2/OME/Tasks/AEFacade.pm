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
	my $message;
	my $engine = OME::Analysis::AnalysisEngine->new();
	my $cmanager = OME::Tasks::ChainManager->new($session);
	my $factory = $self->{session}->Factory();
	my $view=$factory->findObject("OME::AnalysisChain",
							name=>$nameView);

	my $module=$cmanager->findModule($nameFunction);
	my @moduleExecution=$factory->findObjects("OME::ModuleExecution", 
								'module_id' => $module->id(),
								'dataset_id' => $dataset->id()
								 );

	

	my $node=$cmanager->getNode($view,$nameFunction);		# table analysis_chains
	# inputs parameters passed to chain. formal_inputs table.
	my $formal_input=$cmanager->getFormalInput($view,$node,$string);
  	# Check userInputs	
	my @att=$factory->findAttributes($attributeType);		
	
	
	#######################################################
	if (scalar (@moduleExecution) >0){
		foreach my $a (@att){
			my $module_execution=$a->module_execution();	
			if (defined $a->module_execution()){
				my $me_id=$a->module_execution()->id();
				foreach my $me (@moduleExecution){
					my @list_input=();
					my @num=();
					my $result=$factory->findObject("OME::ModuleExecution::ActualInput", 
								'module_execution_id' => $me->id(),
								'input_module_execution_id' => $me_id,
								'formal_input_id' => $formal_input->id()
								 );
					if (defined $result){
					    my $h=$a->getDataHash();
					    foreach my $k (keys %$h){
					      push (@num,$k);
					      if ("${$h}{$k}" eq "${$refh}{$k}"){
						  push (@list_input,$k); 
						}
				          }
					    if (scalar (@num) == scalar (@list_input)){
		 			      $message="This analysis has already been run against this dataset with the same input";
		  			      return (undef,$message);
					    }
					}# defined
								
				} #foreach $me
			}
		}
	}
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

