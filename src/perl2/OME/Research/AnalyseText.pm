# OME/Research/AnalyseText.pm

# Copyright (C) 2003 Open Microscopy Environment
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

package OME::Research::AnalyseText;
use strict;
use Exporter;

use vars qw (@ISA $VERSION);
@ISA=qw(Exporter);

$VERSION   = '1.00';

#------------------------------------------------------------------------------
# Create a new instance of a text object.

sub new
{
   my $class = shift;

   my $text = {};
   bless($text,$class);
   return $text;
}


#------------------------------------------------------------------------------
# Analyse a text, stored as a string. The string may contain line
# terminators.

sub analyse
{
   my $text = shift;
   my ($block,$accumulate) = @_;

   unless ( $accumulate )
   {
      $text = &_initialize($text);
   }

   unless ( $block )
   {
      return($text);
   }

   
   # by setting split limit to -1, we prevent split from stripping
   # trailing line terminators
   my @all_lines = split(/\n/,$block,-1);
   my $one_line;
   foreach $one_line ( @all_lines )
   {
      $text = &_analyse_line($text,$one_line);
   }

   return($text);
}


#------------------------------------------------------------------------------
sub num_words
{
   my $text = shift;
   return($text->{num_words});
}
#------------------------------------------------------------------------------
sub num_separators
{
   my $text = shift;
   return($text->{num_separators});
}

#------------------------------------------------------------------------------
# Return anonymous hash of all the unique words in analysed text. 
sub unique_words
{
   my $text = shift;
   if ( $text->{unique_words} )
   {
      return( %{ $text->{unique_words} } );
   }
   else
   {
      return(undef);
   }
}

#------------------------------------------------------------------------------
# PRIVATE METHODS
#------------------------------------------------------------------------------
sub _initialize
{
   my $text = shift;
   $text->{num_words} = 0;
   $text->{num_separators} = 0;
   $text->{unique_words} = ();

   return($text);
}

#------------------------------------------------------------------------------
# Increment number of text lines

sub _analyse_line
{
   my $text = shift;
   my ($one_line) = @_;

   if ( $one_line =~ /\w/ )
   {
      chomp($one_line);
      $text = &_analyse_words($text,$one_line);
   }
   return($text);
}
#------------------------------------------------------------------------------
# Try to detect real words in line. 

sub _analyse_words
{
   my $text = shift;
   my ($one_line) = @_;
   
  
   #while ( $one_line =~ /\b([a-z0-9][-'a-z0-9]*)\b/ig )
    while ( $one_line =~ /([a-zàäâçéèëêïîöôùüû0-9_][-'a-zàäâçéèëêïîöôùüû0-9_]+)/ig )

   {
      my $one_word = $1;

      # Try to filter out acronyms and  abbreviations by accepting
      # words with a vowel sound. This won't work for GPO etc.
      #next unless $one_word =~ /[aeiouy0-9]/i;

      # Test for valid hyphenated word like be-bop
      if ( $one_word =~ /-/ )
      {
         #next unless $one_word =~ /[a-z]{2,}-[a-z]{2,}/i;
	   next unless $one_word =~ /[a-zàäâéèëêïîöôùüû0-9_]{1,}-[a-zàäâéèëêïîöôùüû0-9_]{1,}/i;

      }
      
      # word frequency count
      #$text->{unique_words}{lc($one_word)}++; 
      $text->{unique_words}{$one_word}++;

      $text->{num_words}++;

   }
      
   
   # Search for +
   while ( $one_line =~ /\b\s*[+]\s*\b/g ) { $text->{num_separators}++ }
   return($text);
}





1;

