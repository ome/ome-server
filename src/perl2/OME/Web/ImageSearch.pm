# OME/Web/ImageSearch.pm

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


package OME::Web::ImageSearch;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;

use OME::Web::Helper::HTMLFormat;
use OME::Web::ImageTable;

use base qw(OME::Web);

#####################
sub getPageTitle {
	return "Open Microscopy Environment - Image Search" ;

}
####################

sub getPageBody {
	my $self = shift ;
	my $cgi = $self->CGI() ;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $body="" ;
	
	##########################
	# DB info
	# 	table name 
	#	selected columns
	
	my 	$table="images";			
	my 	$selectedcolumns="name,inserted,image_id";	
	##########################
		
	if ($cgi->param('search') ) {
		my (@imgs, $imgName, %criteria);
		( $imgName = $cgi->param('name') ) =~ s/^\s*(.*\S)\s*$/$1/;
		

		$criteria{ 'name' } = ['like', '%'.$imgName.'%']
			if (length($imgName) > 1 );

		my @create_after = grep( length($_) > 0, ( 
			$cgi->param('create_after_year'),
			$cgi->param('create_after_month'),
			$cgi->param('create_after_day')
		));
		my $create_after_str = join( '-', @create_after);
		$criteria{ 'created'} = ['>=',$create_after_str]
			if scalar( @create_after ) == 3;

		my @create_before = grep( length($_) > 0, ( 
			$cgi->param('create_before_year'),
			$cgi->param('create_before_month'),
			$cgi->param('create_before_day')
		) );
		my $create_before_str = join( '-', @create_before);
		$criteria{ 'created'} = ['<',$create_before_str]
			if scalar( @create_before ) == 3;
		
		unless ( keys( %criteria ) > 0 ) {
			$body .= format_form($cgi); 
			return ('HTML',$body) ;
		}
		@imgs = $factory->findObjects( 'OME::Image', %criteria );
		
		if (scalar @imgs){
			$body .= format_output(\@imgs,$cgi,\%criteria);
			$body .= format_form($cgi);	
		} else{
			$body .= "No Images found.";
			$body .= format_form($cgi);	
		}
	
	} else{
		$body .= format_form($cgi);
	}
	return ('HTML',$body) ;
}


#---------------------
# PRIVATE METHODS
#---------------------


sub format_output{
	my ($imgs,$cgi)=@_;
	my $text="";
	$text.="<h3>List of image(s) matching your data.</h3>";
	my $t_generator = new OME::Web::ImageTable;
	$text .= $t_generator->getTable( {
			relations => 1,
		}, @$imgs );
	return $text;
}



sub format_form{
	my ($cgi) =@_ ;
	my $form="";

	$form .=$cgi->startform;
	$form .="<h3>Search For Images </h3>";
	$form .= $cgi->p( "<b>Name contains </b>",
		$cgi->textfield( -name => 'name', -default => $cgi->param('name') || undef, -maxlength => 25 )
	);
	$form .= $cgi->p( "<b>Description contains </b>",
		$cgi->textfield( -name => 'description', -default => $cgi->param('name') || undef, -maxlength => 25 )
	);

	my ($ryear,$rmonth,$rday) = OME::Web::Helper::HTMLFormat->YMD();
	$form .= $cgi->p( $cgi->table( 
		$cgi->caption( 'Creation Date' ),
		$cgi->Tr( [
			$cgi->th( { -colspan => 3, -align => 'CENTER' }, ['After', 'Before'] )
		] ),
		$cgi->Tr( {-align => 'LEFT'}, 
			[
				$cgi->td( ['year','month','day','year','month','day'] ),
				$cgi->td( [
					$cgi->popup_menu( 
						-name   => 'create_after_year', 
						-values => [ sort( keys( %$ryear ) ) ],
						-default => $cgi->param('year') || undef,
						-labels  => $ryear
					),
					$cgi->popup_menu( 
						-name   => 'create_after_month', 
						-values => [ sort( keys( %$rmonth ) ) ],
						-default => $cgi->param('month') || undef,
						-labels  => $rmonth
					),
					$cgi->popup_menu( 
						-name   => 'create_after_day',
						-values => [ sort( keys( %$rday ) ) ],
						-default => $cgi->param('day') || undef,
						-labels  => $rday
					),
					$cgi->popup_menu( 
						-name   => 'create_before_year', 
						-values => [ sort( keys( %$ryear ) ) ],
						-default => $cgi->param('year') || undef,
						-labels  => $ryear
					),
					$cgi->popup_menu( 
						-name   => 'create_before_month', 
						-values => [ sort( keys( %$rmonth ) ) ],
						-default => $cgi->param('month') || undef,
						-labels  => $rmonth
					),
					$cgi->popup_menu( 
						-name   => 'create_before_day',
						-values => [ sort( keys( %$rday ) ) ],
						-default => $cgi->param('day') || undef,
						-labels  => $rday
					)
				] )
			]
		)
	) );

#	$form .= $cgi->p( $cgi->table( 
#		$cgi->caption( 'Import Date' ),
#		$cgi->Tr( [
#			$cgi->th( { -colspan => 3, -align => 'CENTER' }, ['After', 'Before'] )
#		] ),
#		$cgi->Tr( {-align => 'LEFT'}, 
#			[
#				$cgi->td( ['year','month','day','year','month','day'] ),
#				$cgi->td( [
#					$cgi->popup_menu( 
#						-name   => 'import_after_year', 
#						-values => [ sort( keys( %$ryear ) ) ],
#						-default => $cgi->param('year') || undef,
#						-labels  => $ryear
#					),
#					$cgi->popup_menu( 
#						-name   => 'import_after_month', 
#						-values => [ sort( keys( %$rmonth ) ) ],
#						-default => $cgi->param('month') || undef,
#						-labels  => $rmonth
#					),
#					$cgi->popup_menu( 
#						-name   => 'import_after_day',
#						-values => [ sort( keys( %$rday ) ) ],
#						-default => $cgi->param('day') || undef,
#						-labels  => $rday
#					),
#					$cgi->popup_menu( 
#						-name   => 'import_before_year', 
#						-values => [ sort( keys( %$ryear ) ) ],
#						-default => $cgi->param('year') || undef,
#						-labels  => $ryear
#					),
#					$cgi->popup_menu( 
#						-name   => 'import_before_month', 
#						-values => [ sort( keys( %$rmonth ) ) ],
#						-default => $cgi->param('month') || undef,
#						-labels  => $rmonth
#					),
#					$cgi->popup_menu( 
#						-name   => 'import_before_day',
#						-values => [ sort( keys( %$rday ) ) ],
#						-default => $cgi->param('day') || undef,
#						-labels  => $rday
#					)
#				] )
#			]
#		)
#	) );
	
	$form .= $cgi->submit( -name => 'search', -value => 'Search' );
	$form .=$cgi->endform;
	return $form ;
}


1;



