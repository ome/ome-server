# OME/SetDB.pm

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


#------------------------------------------------------------------------------
# FIXME:
#	this class may need to be refactored at some point to have less reliance on direct SQL queries.


package OME::SetDB;
use strict;
use OME;
our $VERSION = $OME::VERSION;

sub new {
   my $class = shift;

   my $self = {};
   $self->{dbname}=shift;
   $self->{dbuser}=shift;
   $self->{dbpasswd}=shift;	 
   my $dbd  = undef; 
	 
   unless ($dbd = DBI->connect($self->{dbname},$self->{dbuser},$self->{dbpasswd}),{ RaiseError => 1 }) { 
          return undef;
   }

   $self->{obj} 	= $dbd;
   return bless $self;
}

sub Off {

   my $self      = shift;    	
   my $val=$self->{obj};
   $val->disconnect;

}


#----------

sub GetRecords{


  my $self      = shift;
  my $dbd       = $self->{obj};          
  my ($table,$cond,$selectedcols, $key, $value,$trierpar, $join_table) = @_;

  my $sth		= undef;	
  my $Req		= undef;
  my $row		= undef;
  my $rows		= 0;
  my $tabref		= [];
  my $Err			= undef;  
  
  $selectedcols	= '*' unless (defined $selectedcols);  
  
  if ($cond) {
     return undef unless ($table);
     if ($join_table) {
        $Req = "SELECT $selectedcols  FROM $table,$join_table WHERE $cond ".
		(($trierpar)?"ORDER BY $trierpar":"");
     }else {
        $Req = "SELECT $selectedcols  FROM $table WHERE $cond ".
		(($trierpar)?"ORDER BY $trierpar":"");
     }

  }else{
    return undef unless ($table);
    return undef unless ($key);
    return undef unless ($value);
    $Req = "SELECT $selectedcols  FROM $table WHERE $key = $value ".(($trierpar)?"ORDER BY $trierpar":"");
  }
  $sth=$dbd->prepare($Req);
  $sth->execute or
       $Err = $sth->errstr;
 
  while ( $row = $sth->fetchrow_hashref ) {
      push (@$tabref, $row); 
      $rows++;	       
  }
 
  #$dbd->disconnect;
  $sth->finish;
  return ($rows>0)?$tabref:undef;

}


#-----------------
#
sub DeleteRecord{


  my $self      = shift;
  my $dbd       = $self->{obj}; 

  my ($table,$cond)=@_;	
  my $sth	= undef;	
  my $req	=undef;
  my $Err = undef;

  return undef unless ($table);

  if ($cond) {
     $req = "DELETE FROM $table WHERE $cond";
  }
  $sth = $dbd->prepare($req);     


  $sth->execute or $Err = $sth->errstr;

  #$dbd->disconnect;   
  $sth->finish;
  return $Err?undef:1;
  #return $Err?$Err:1;


}

#------------------------
# $row:ref % key=column_name value=update_value

sub UpdateRecord{

  my $self      = shift;
  my $dbd       = $self->{obj}; 

  my ($table,$row,$condition,$key,$value)=@_;

  my $sth	= undef;	
  my $req	= undef;
  my $vals	= undef;  
  my @final=();

  my $Err	= undef;

  return 0 unless ($table);
  return 0 unless ($row);
 
	
  foreach (keys %$row) {	
     my $val= "$_ = ${$row}{$_}";
     push(@final,$val);
  }
  $vals =join(',',@final);	
  if ($condition) {
     $req = "UPDATE $table SET $vals WHERE $condition";
  }else {
     $req = "UPDATE $table SET $vals WHERE $key = $value";
  }
  $sth = $dbd->prepare($req);     

  $sth->execute or $Err = $sth->errstr;
 
  $sth->finish;   

  return $Err?0:1;


}


1;
