# OME/Research/SearchEngine.pm

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
# Written by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Research::SearchEngine;


use OME;
our $VERSION = $OME::VERSION;
use strict;

#use Class::Accessor;
#use Class::Data::Inheritable;
use OME::DBConnection;
#use OME::DBObject;
use OME::Research::AnalyseText;
use OME::Research::SetStatement;
use OME::SetDB;


#---------------------------------------------------------
# Create a new instance
sub new {
   my $class=shift;
   my $self = {};
   $self->{type} = shift;		# projects, datasets, images	: string
   #$self->{string} = shift;		# string to parse			: string
   $self->{selectedcol}=shift;	# selected columns 		: string  
   bless($self,$class);
   return $self;
}


#--------------------------------
# parameters: 
# 	string = string to search
#	htime= ref hash with (year,month,day)

sub searchEngine{

  my $self=shift;
  my ($string,$htime)=@_;
  my $results=undef;
  my %words=();
  my $sepvalue;
  my $text=new OME::Research::AnalyseText;
  if (defined $text){
   $text->analyse($string,1);
  }
  %words=$text->unique_words;
  $sepvalue=$text->num_separators;
  my %h=();
  %h=(
	name=>\%words,
	description=>\%words
  );

  my $cd= new OME::Research::SetStatement;
  my $condition;
  if (defined $cd){
   # ILike: Postgres ! not used
    my $db=new OME::SetDB(OME::DBConnection->DataSource(),OME::DBConnection->DBUser(),OME::DBConnection->DBPassword());  
    $condition=$cd->Prepare_Request_Like(\%h,$sepvalue,$htime);
    $results=&_do_Request($self,$condition,$db);
    $db->Off();	
  }
  # because of import process
  my @list=();
  foreach (@$results){
	push(@list,$_) unless  ($_->{name} eq "Dummy import dataset");
  }
  return (scalar(@list)==0)?undef:\@list;

  #return \@list;
}



#----------------
#PRIVATE MEHTODS  
#----------------

sub _do_Request{
 my $self=shift;
 my ($condition,$db)=@_;
 my $type=$self->{type};
 chomp($type);
 return undef unless $type;
 my $selectedcolumns;
 my $result;
 
 # no selected columns 	modify ?
 $selectedcolumns=$self->{selectedcol};
 if (defined $db){
    if (defined $selectedcolumns){
     $result=$db->GetRecords($type,$condition,$selectedcolumns);
    }else{
     $result=$db->GetRecords($type,$condition);
    }

 }
 return $result;
 

}
 



1;
