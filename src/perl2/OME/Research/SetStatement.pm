# OME/Research/SetStatement.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Jean-Marie Burel <j.burel@dundee.ac.uk>
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

#07-03-03


package OME::Research::SetStatement;
use strict;
use Exporter;

use vars qw (@ISA $VERSION);
@ISA=qw(Exporter);

$VERSION   = '1.00';



#---------------------------------------------------------

sub new {
  # my $invoker = shift;
   #my $class = ref($invoker) || $invoker;   # called from class or instance
   my $class=shift;
   my $self = {};

   $self->{bool} =" OR ";		# not used				default value
   $self->{separator} =" OR ";	# if no "+" in string parsed		default value
   $self->{timecreated} ="created";	#default value
   bless($self,$class);
   return $self;
}

#-----------------------------------
# description: prepare sql condition

sub Prepare_Request_Like{
  	my $self=shift;		
  	my ($ref,$sepvalue,$htime)=@_;
  	my %h=();
  	my $separator=$self->{separator};		
  	my @listgeneral=();
  	my $requestgeneral="";
  	my $results;
  	%h=%$ref;
	if (defined $htime){
		my $date=$self->timeFormat($htime);
		if (defined $date){
			my $temp=$self->{timecreated}." LIKE \'\%".$date."\%\' AND ";	
			$requestgeneral.=$temp;
		}
	}
  	foreach my $column_name (keys %h){
   	 	my $request;
    		my @list=();
    		my $hash=$h{$column_name};
   		if($sepvalue>0){
		   $separator=" AND ";
    		}   
    		foreach my $word (keys %$hash){
     		    my $temp="Upper(".$column_name.") LIKE Upper(\'\%".$word."\%\')";	
      	    push(@list,$temp);
    		}
    		$request=join($separator,@list);
    		#$request="(".$request.")";
    		push(@listgeneral,$request);
  	}
  	if (scalar(@listgeneral)>1){
     		$requestgeneral.=join($self->{bool},@listgeneral);
  	}else{
		# only one value;
    		$requestgeneral.=$listgeneral[0];
  	}
	
  	return $requestgeneral;

}


###############
# parameters:
#	htime= ref hash

sub timeFormat{
	my $self=shift;
	my ($htime)=@_;
	my @date=();
	my $d;
	if (${$htime}{year} eq "" && ${$htime}{month} eq "" && ${$htime}{day} eq "" ){
		return undef;
	}else{
	  my ($day,$month,$year);
	  ($day,$month,$year)=(localtime)[3,4,5];
	  if (${$htime}{year} eq ""){
		$year=1900+$year;
	  }else{
		$year =${$htime}{year};
	  }
	  push(@date,$year);
	  if (${$htime}{month} ne "" || ${$htime}{day} ne ""){
		if (${$htime}{month} eq ""){
			$month=$month+1;
			if ($month<10){
				$month="0".$month;
			}
		}else{	
		 	$month =${$htime}{month};
		}
		push(@date,$month);
		if (${$htime}{day} ne ""){
		  push(@date,${$htime}{day});

		}
	  }
	}
	$d=join("-",@date);
	return $d;
}
1;

