# OME/SetDB.pm

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



#------------------------------------------------------------------------------


package OME::SetDB;
use strict;
our $VERSION	= 1.00;

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
   
   ${$self->{obj}}->disconnect;

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
 
  $dbd->disconnect;
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

  $dbd->disconnect;   

  return $Err?undef:1;


}

1;