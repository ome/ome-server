# OME/HTML/HTMLFormat.pm

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
# Written by:    J-M Burel <jburel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::Helper::HTMLFormat;

use strict;


use OME;
our $VERSION = $OME::VERSION;

=head 1 NAME

OME::Web::Helper::HTMLFormat - HTML code used for WebInterface

=head 1 SYNOPSIS

	use OME::Web::Helper::HTMLFormat;
	my $htmlFormat=new OME::Web::Helper::HTMLFormat;
	

=head 1 DESCRIPTION

The OME::Web::Helper::HTMLFormat provides a list of methods to write HTML code

=head1 METHODS (ALPHABETICAL ORDER)

=head2 buttonControl
=head2 datasetList
=head2 datasetListInProject
=head2 dropDownTable
=head2 formatDataset
=head2 formatImage
=head2 formatProject
=head2 formatThumbnail
=head2 formChange
=head2 formCreate
=head2 formExport
=head2 formImport
=head2 formLogin
=head2 formSearch
=head2 gallery
=head2 imageInDataset
=head2 listImages
=head2 manager
=head2 projectList
=head2 radioButton
=head2 searchResults
=head2 titleBar


=cut





sub new{
	my $class=shift;
	my $self={};

	$self->{cellLeft}={
	"align"	=>"LEFT",
	};

	$self->{cellCenter}={
	"align"	=>"CENTER",
	};

	$self->{tableDefaults}={
	"border"	=>1,
	};
	
	$self->{imageDefaults}={
	"src"   => "/images/AnimalCell.aa.jpg.png",
	"width" => 105,
	"height" => 77,				
	"border" => 0,
	"alt"    => "Cell in mitosis",
	};

	bless($self,$class);
   	return $self;
};








##############
# Parameters:
#	object= dataset/image object
#	userID= current user ID
#	user = owner
#	bool = for delete button 
#	type= dataset/image
# Return: html code table with button(s)

sub buttonControl{
	my $self=shift;
	my ($object,$userID,$user,$bool,$type)=@_;
	my $rows="";
	my $html="";	
	my $typ=lc($type);
	my ($view,$function,$id,$select,$delete);
	$select=undef;
	$view=undef;
	my %h=();
	if ($typ eq "dataset"){
		$function="openPopUpDataset";
		$id=$object->dataset_id();
		$delete=buttonInput("submit",$id,"Delete") if ($userID==$user->id() and !defined $bool);
		$select=buttonInput("submit",$id,"Select");
		$view=buttonPopUp($id,"View",$function);
		$h{1}={content=>$view,attribute=>$self->{cellLeft}},


	}else{
		$function="openPopUpImage";
		$id=$object->image_id();
		#$delete=buttonInput("submit",$id,"Delete") if ($userID==$user->id() and defined $bool);
	}
	
		
	$h{2}={ content=>$select,attribute=>$self->{cellLeft} } if (defined $select);
	$h{3}={ content=>$delete,attribute=>$self->{cellLeft} } if (defined $delete);
	$rows.=addRow(\%h);
	$html.=writeTable($rows);
	return $html;
}





#######################
# Parameters:
#	ref= ref hash dataset object 
# Return: html code table object name + id + viewButton

sub datasetList{
	my $self=shift;
	my ($ref)=@_;
	my $html="";
	my $rows="";
	my %H=(
	1	=> { content=>"<b>Name</b>",attribute=>$self->{cellLeft}},
	2	=>{ content=>"<b>ID</b>",attribute=>$self->{cellLeft}},
	3	=>{ content=>"<b>View</b>",attribute=>$self->{cellLeft}},
	);
	$rows.=addRow(\%H);

	foreach (keys %$ref){
		my $view=buttonPopUp($_,"View","openPopUpDataset");
		my %h=(
		1 =>	{ content=>${$ref}{$_}->name(),attribute=>$self->{cellLeft}},
		2 => 	{ content=>$_,	attribute=>$self->{cellLeft}},
		3 =>  { content=>$view, attribute=>$self->{cellCenter}},
		);		
		$rows.=addRow(\%h);

	}
	$html.=writeTable($rows);
}



############################
# Parameters:
#	ref= ref array of dataset object to format
# Return: html code table list Name, locked +button (select,Remove)

sub datasetListInProject{
	my $self=shift;
	my ($ref)=@_;
	my $rows="";
	my $html="";
	my %H=(
	1	=> { content=>"<b>Name</b>",attribute=>$self->{cellLeft}},
	2	=>{ content=>"<b>Locked/Unlocked</b>",attribute=>$self->{cellLeft}},
	3	=>{ content=>"<b>Select</b>",attribute=>$self->{cellLeft}},
	4	=>{ content=>"<b>Remove</b>",attribute=>$self->{cellLeft}},
	);
	$rows.=addRow(\%H);
	foreach (@$ref){
		my ($select,$remove);
		$select=buttonInput("submit",$_->dataset_id(),"Select");
		$remove=buttonInput("submit",$_->dataset_id(),"Remove");
	      my $lock;
		if($_->locked() == 0){
			$lock="Unlocked";
		}else{
			$lock="Locked";
		} 
		my %h=(
		1 =>	{ content=>$_->name(),	attribute=>$self->{cellLeft}},
		2 => 	{ content=>$lock,	attribute=>$self->{cellLeft}},
		3 =>  { content=>$select, attribute=>$self->{cellLeft}},
		4 =>  { content=>$remove, attribute=>$self->{cellLeft}},
		);		
		$rows.=addRow(\%h);
	}
	
	$html.=writeTable($rows,$self->{tableDefaults});
	return $html;



}




sub dropDownTable{
	my $self=shift;
	my ($name,$ref,$switch,$switchValue)=@_;
	my $html="";
  	my $rows="";
	my %b=("name"=>$name);			# for select Tag
	my $submit="";
	my %h=();
	my $menu=writeDropDow($ref,\%b);
	$h{1}= { content=>$menu, attribute=>$self->{cellLeft}};
	if (defined $switch){
		$submit.=buttonInput("submit",$switch,$switchValue);
		$h{2}={ content=>$submit, attribute=>$self->{cellLeft}};

	}
	$rows.=addRow(\%h);
	$html.=writeTable($rows);
	return $html;
}

#####################
# Parameters:
#	type= dataset/project
# Return: html code sentence

sub existMessage{
	my $self=shift;
	my ($type)=@_;
	my $html="";
	$html.="<b>This name already exists. Please enter a new name for your ".$type."</b><br>";
	return $html;

}

#####################
# Parameters:
#	dataset= dataset object
#	bool = if defined format current dataset
# 	address = if defined format user info
#	user = user object if address defined
#	view= format view button if defined
# Return: html code format dataset

sub formatDataset{
	my $self=shift;
	my ($dataset,$bool,$address,$view,$user)=@_;
	my $html="";
	if (!defined $bool){
	$html .= "<h3>Your current dataset is:</h3>" ;
	}

	$html .= "<P><NOBR><B>Name:</B> ".$dataset->name()."</NOBR><BR>" ;
	$html .= "<NOBR><B>ID:</B> ".$dataset->dataset_id()."</NOBR><BR>" ;
	$html .= "<B>Description:</B> ".$dataset->description()."<BR>" ;
	$html .= "<NOBR><B>Locked:</B> ".($dataset->locked()?'YES':'NO')."</NOBR><BR>";
	if (defined $address){
	  $html .= "<NOBR><B>Owner:</B> ".$user->FirstName()." ".$user->LastName()."</NOBR><BR>";
 	  $html .= "<NOBR><B>E-mail:</B><a href='mailto:".$user->Email()."'>".$user->Email()."</a></NOBR><BR>";
	}
	$html .= "<NOBR><B>Number Images in dataset:</B> ".scalar($dataset->images())."</NOBR></P>" ;
 	if (defined $view){
	$html.=buttonPopUp($dataset->dataset_id(),"View","openPopUpDataset");

	}
	return $html ;
}


################
# Parameters:
#	image = image object
# Return: html code format image

sub formatImage{
	my $self=shift;
	my ($image)=@_;
	my $html="";
	$html	.= "<P><NOBR><B>Name:</B> ".$image->name()."</NOBR><BR>" ;
  	$html .= "<B>Image ID:</B> ".$image->image_id()."<BR></P>" ;
	return $html;
}



#################
# Parameters:
#	project = project object
#	bool = if defined format current project
# Return: html code format project

sub formatProject{
	my $self=shift;
	my ($project,$bool)=@_;
	my $html="";
	if (!defined $bool){
 		$html .= "<h3>Your current project is:</h3>" ;
	}
 	$html .= "<P><NOBR><B>Name:</B> ".$project->name()."</NOBR><BR>" ;
 	#$html .= "<NOBR><B>ID:</B> ".$project->project_id()."</NOBR><BR>" ;
 	$html .= "<B>Description:</B> ".$project->description()."<BR>" ;
	$html.= "<b>Number of Datasets:</b>".scalar($project->datasets())."<br></p>";
 	return $html ;

}

####################
# Parameters:
#	imageName
#	imageID
sub formatThumbnail{
	my $self=shift;
	my ($object)=@_;
	my $imageName=$object->name();
	my $imageID=$object->image_id();
	my $rows="";
	my $html="";
	my ($name,$imageTag);
	$name="<a href=\"#\" onClick=\"return openPopUpImage($imageID)\">".$imageName."</a>";
	$imageTag="<a href=\"#\" onClick=\"return openPopUpImage($imageID)\"><img src=/perl2/serve.pl?Page=OME::Web::ThumbWrite&ImageID=".$imageID." align=\"bottom\" border=0></a>";
	my %h=(
	1=>{ content=>$imageTag, attribute=>$self->{cellLeft}}
	);
	$rows.=addRow(\%h);
	my %ha=(
	1=>{ content=>$name, attribute=>$self->{cellCenter}},
	);
	$rows.=addRow(\%ha);
	$html.=writeTable($rows);
	return $html;

}
##############
# Parameters:
#	type= dataset/project
#	object= object to format
#	user = owner 
# Return: html code format change done

sub formChange{
	my $self=shift;
	my ($type,$object,$user)=@_;
	my $html="";
	my $rows="";
	my $text="";
	my $textarea="";

	my $typ=lc($type);
	my ($id,$name,$description,$owner,$group);
	my $lock=undef;
	$name=$object->name();
	$description=$object->description();

	#####
	
	$owner=$user->FirstName()." ".$user->LastName()." <a href='mailto:".$user->Email()."'>".$user->Email()."</a>";
	$group=$user->Group()->Name();
	
	my ($components, $componentCount );
	if ($typ eq "dataset"){
		$id=$object->dataset_id();
		if ($object->locked()){
		  $lock="locked";
		}else{
 		  $lock="unlocked";
		}
		$components = "images";
		$componentCount = scalar $object->images();
	}else{
		$id=$object->project_id();
		$components = "datasets";
		$componentCount = scalar $object->datasets();
	}
	$text .=buttonInput("text","name",$name,32);
	$textarea .=buttonArea("description",3,32,$description);

	my %a=(
	1 =>{ content=>"*Name  ", attribute=>$self->{cellLeft}},
	2=> { content=>$text, attribute=>$self->{cellLeft}},
	);
	my %b=(
	1 =>{ content=>"Description  ", attribute=>$self->{cellLeft}},
	2=> { content=>$textarea, attribute=>$self->{cellLeft}},
	);
	my %c=(
	"Owner"	=>$owner,
	"Group"	=>$group,
	"ID"    =>$id,
	"Number of $components in $typ" =>$componentCount
	);
	$c{"Locked/Unlocked"}=$lock if (defined $lock);
	$rows.=addRow(\%a);
	$rows.=addRow(\%b);

	foreach my $k (keys %c){
		my %h=(
		1 =>{ content=>$k, attribute=>$self->{cellLeft}},
		2 =>{ content=>$c{$k}, attribute=>$self->{cellLeft}},
		);
		$rows.=addRow(\%h);
	}
	$html.=writeTable($rows);
	my $pop=buttonInput("submit","save","Save changes");
	my %hpop=(
	1=>{content=>$pop, attribute=>$self->{cellLeft}},
	);
	my $rowButton=addRow(\%hpop);
	$html.="<br>";
	$html.=writeTable($rowButton);
	$html .= "<br><font size=-1>An asterick (*) denotes a required field</font>";

	return $html;


}


################
# Parameters:
#	type = dataset/project
#	userID= userId
#	ref= if dataset, display list of images to add (createWithExisting images)
# Return: html code
 
sub formCreate{
	my $self=shift;
	my ($type,$usergpID,$ref)=@_;
	my $rows="";
	my $html="";
	my $text="";
	my $textarea="";
	my (%a,%b);
	%a=(
	"border"	=>0,
	"cellspacing" =>4,
	"cellpadding"=>0,
	) ;
	%b=(
	"colspan" => 2,
	);
	my $typ=lc($type);
	my $function;
	if ($typ eq "project"){
		$function="openExistingProject";
	}else{
		$function="openExistingDataset";
	}
	my $txt="Description existing $type(s)";
	$text .=buttonInput("text","name",undef,32);
	$textarea .=buttonArea("description",3,32);
	my $button=buttonInput("submit","create","Create");

	my %h=(
	1=>{ content=>"<b>*Name:  </b>", attribute=>$self->{cellLeft}},
	2=>{ content=>$text, attribute=>$self->{cellLeft}},
	);
	my %H=(
	1=>{ content=>"<b>Description:  </b>", attribute=>$self->{cellLeft}},
	2=>{ content=>$textarea, attribute=>$self->{cellLeft}},
	);
	my %ha=(
	1=>{ content=>$button, attribute=>\%b},
	);
	$rows.=addRow(\%h);
	$rows.=addRow(\%H);
	$rows.=addRow(\%ha);
	$html.=writeTable($rows,\%a);

	my $pop=buttonPopUp($usergpID,$txt,$function);
	my %hpop=(
	1=>{content=>$pop, attribute=>$self->{cellLeft}},
	);
	my $rowButton=addRow(\%hpop);
	$html.="<br>";
	$html.=writeTable($rowButton);
	$html .= "<br><font size=-1>An asterick (*) denotes a required field</font>";
	if (defined $ref){
		$html.="<h3>Please select images in the list below.</h3>";
		$html.=$self->writeCheckBoxImage($ref);
	}
	return $html;

}


#############
# Parameters
#	No
sub formExport{
	my $self=shift;
	my $html="";
	my $rows="";
	my %h=(
	1 =>{name =>'All', text=> 'All '},
	2 =>{name => 'User', text => 'User'},
	3 =>{name => 'Project', text => 'Project'},
	4 =>{name => 'Dataset', text => 'Dataset'},
	5 =>{name => 'Images', text => 'Images'},
	6 =>{name => 'Features', text => 'Features'},
	);
	my %ha=(
	1 =>{name =>'yes', text=> 'Yes'},
	2 =>{name =>'no', text=> 'No'},
	);
	my $radioSTD= $self->radioButton(\%ha,1,"exportSTD");
	my $radioButton= $self->radioButton(\%h,1,"type");
	my $text="";
	$text .="Name ";
	$text .=buttonInput("text","file name",undef,25);
	my $button =buttonInput("submit","export","Export");
	$html.="Do you want to export to a file? If yes, please indicate a file's name.<br>";
	my $txt="";
	foreach (@$radioSTD){
		$txt.=$_." ";
	}

	my %a=();
	$a{1}={ content=>$text, attribute=>$self->{cellLeft}};
	$rows.=addRow(\%a);
	$html.=writeTable($rows);
	$html.="Do you want to export STDs?<br>";

	$a{1}={ content=>$txt, attribute=>$self->{cellLeft}};
	$rows="";
	$rows.=addRow(\%a);
	$html.=writeTable($rows,\%a);
	$rows="";
	$html.="<br>";
	$txt="";
	foreach (@$radioButton){
		$txt.=$_." ";
	}
	$a{1}={ content=>$txt, attribute=>$self->{cellLeft}};
	$rows.=addRow(\%a);
	$a{1}={ content=>$button, attribute=>$self->{cellLeft}};
	$rows.=addRow(\%a);

	$html.=writeTable($rows);


	return $html;

}

#####################
# Parameters:
#	datasetName= default value
#	dropDownTable = html code  list of existing dataset (result of dropdowTable)
#	radio	= ref array(result of radioButton)
#	nameSubmit = name submit button
#	valueSubmit = value sbmit button
# Return: html code table

sub formImport{
	my $self=shift;
	my ($datasetName,$dropDownTable,$radio,$nameSubmit,$valueSubmit)=@_;
	my $rows="";
	my $html="";
  	my @rad=@$radio;
	my $submit=buttonInput("submit",$nameSubmit,$valueSubmit);
	my $text=buttonInput("text","newDataset",$datasetName,32);

	my $textarea=buttonArea("description",3,32);
	my %c=(
	"border"	=>0,
	"cellspacing" =>4,
	"cellpadding"=>0,
	);
	my $txt="<nobr>".$rad[0]."</nobr>";
	my %a=(
	1 =>{ content=>$txt, attribute=>$self->{cellLeft}},
	2=> { content=>$text, attribute=>$self->{cellLeft}},
	);
	my %b=(
	1 =>{ content=>"Description  ", attribute=>$self->{cellLeft}},
	2=> { content=>$textarea, attribute=>$self->{cellLeft}},
	);
	$rows.=addRow(\%a);
	$rows.=addRow(\%b);
	$html.=$submit."<BLOCKQUOTE>";
	$html.=writeTable($rows,\%c);
	$html.=$rad[1]."<br>".$dropDownTable;
	
	$html.="</BLOCKQUOTE>";
	return $html;

}



##############################
# Parameters:
#	invalid= if defined, try to log again
# Return: html code login form

sub formLogin{
	my $self=shift;
	my ($invalid)=@_;
	my $rows="";
	my $html="";
	if (defined $invalid){
	   $html.="<h3>Invalid Login</h3>";
	   $html.="<p>The username and/or password you entered don't match an experimenter in the system.  Please try again.</h3>";
	}else{
	   $html.="<h3>Login</h3>";
	   $html.="<p>Please enter your username and password.</p>";
      }

	my $text=buttonInput("text","username",undef,25);
	my $textPass=buttonInput("password","password",undef,25);
	my $button=buttonInput("submit","execute","Login");
	my %a=(
	1=>{ content=>"<b>Username:  </b>", attribute=>$self->{cellLeft}},
	2=>{ content=>$text, attribute=>$self->{cellLeft}},
	);
	my %b=(
	1=>{ content=>"<b>Password:  </b>", attribute=>$self->{cellLeft}},
	2=>{ content=>$textPass, attribute=>$self->{cellLeft}},
	);
	$rows.=addRow(\%a);
	$rows.=addRow(\%b);
	$html.=writeTable($rows);
	my %h=(
	1=>{content=>$button, attribute=>$self->{cellLeft}},
	);
	my $rowButton=addRow(\%h);
	$html.="<br>";
	$html.=writeTable($rowButton);

	return $html;


}

#########################
sub formImportExportXML{
	my $self=shift;
	my ($ref,$nameButton,$valueButton)=@_;
	my $html="";
	my $rows="";
	my $text="";
	my $button="";
	my (%a,%b);
	%a=(
	"border"	=>0,
	"cellspacing" =>4,
	"cellpadding"=>0,
	) ;
	%b=(
	"colspan" => 2,
	);
	$text .="<b>Name(s): </b>";
	my %hb=(
	1=>{ content=>$text, attribute=>\%b},
	);
	$rows.=addRow(\%hb);

	$button .=buttonInput("submit",$nameButton,$valueButton);
	foreach(@$ref){
		my %h=(
		1=>{ content=>$_, attribute=>$self->{cellCenter}},
		);
		$rows.=addRow(\%h);
	}
	my %ha=(
	1=>{ content=>$button, attribute=>\%b},
	);
	$rows.=addRow(\%ha);
	$html.=writeTable($rows,\%a);

	return $html;



}
##################
# Parameters:
#	name= Projects/Datasets/Images
#	type= (optional) if defined search by date
# Return: html code search form

sub formSearch{
	my $self=shift;
	my ($name,$type)=@_;
	my $html="";
	my $rows="";
	my $text="";
	my $button="";
	my (%a,%b);
	%a=(
	"border"	=>0,
	"cellspacing" =>4,
	"cellpadding"=>0,
	) ;
	%b=(
	"colspan" => 2,
	);
	$html .="<h3>Search For $name </h3>";
	$html .="<p>Please enter a data to match, the date is optional</p>";
	$text .="<b>Name/Description contains </b>";
	$text .=buttonInput("text","name",undef,25);
	$button .=buttonInput("submit","search","Search");
	my %h=(
	1=>{ content=>$text, attribute=>$self->{cellCenter}},
	);
	$rows.=addRow(\%h);

	if ($type){
		my $date="Date";
		my $table="";
		my $rowTable="";
		my ($ryear,$rmonth,$rday)=YMD();
		my %b=("name"=>"year");
		my $year=writeDropDow($ryear,\%b);
		%b=("name"=>"month");
		my $month=writeDropDow($rmonth,\%b);
		%b=("name"=>"day");
		my $day=writeDropDow($rday,\%b);
		my %hdate=(
			0=>{ content=>"<b>Created</b> (optional):", attribute=>$self->{cellLeft}},
			1=>{ content=>"<b>year</b>", attribute=>$self->{cellLeft}},
			2=>{ content=>"<b>month</b>", attribute=>$self->{cellLeft}},
			3=>{ content=>"<b>day</b>", attribute=>$self->{cellLeft}},
		);
		$rowTable.=addRow(\%hdate);
		%hdate=(
			0=>{ content=>"", attribute=>$self->{cellLeft}},
			1=>{ content=>$year, attribute=>$self->{cellLeft}},
			2=>{ content=>$month, attribute=>$self->{cellLeft}},
			3=>{ content=>$day, attribute=>$self->{cellLeft}},
		);
		$rowTable.=addRow(\%hdate);
		$table.=writeTable($rowTable);
		%h=(
			1=>{ content=>$table, attribute=>$self->{cellLeft}},
		);
	$rows.=addRow(\%h);

	}
	
	%h=(
	1=>{ content=>$button, attribute=>\%b},
	);
	$rows.=addRow(\%h);
	
	$html.=writeTable($rows,\%a);

	return $html;

}

####################
# Parameters
# 	ref =ref array with html to format
#	n= number of thumbnails/row
sub gallery{
	my $self=shift;
	my ($ref,$n)=@_;
	my $html="";
	my $rows="";
	my $count=0;
	my %h=();
	my $num;
	if (defined $n){
		$num=$n;
	}else{
		$num=8;
	}
	foreach (@$ref){
	 	if ($count<$num){
		  $h{$count}={content=>$_, attribute=>$self->{cellCenter}};
		  $count++;
		}else{
		  $rows.=addRow(\%h);
		  %h=();
		  $count=0;
		  $h{$count}={content=>$_, attribute=>$self->{cellCenter}};
		}
	}
	my $size=0;
	foreach (keys %h){
		$size++;
	}
	if ($size>0){
	   $rows.=addRow(\%h);
	}
	$html.=writeTable($rows);
	return $html;

}
####################
# Parameters:
#	ref = ref array of images to display
#	border = if defined, table with border
#	search = if defined, other way to access the info
# Return: html code

sub imageInDataset{
	my $self=shift;
	my ($ref,$border,$search)=@_;
	my $rows="";
	my $html="";

	my %H=(
	1	=> { content=>"<b>Name</b>",attribute=>$self->{cellLeft}},
	2	=>{ content=>"<b>ID</b>",attribute=>$self->{cellLeft}},
	3	=>{ content=>"<b>View Image</b>",attribute=>$self->{cellCenter}},
	);
	$rows.=addRow(\%H);
	foreach my $k (@$ref){
		my ($name,$id,$view);
		if (defined $search){
			$name=$k->{name};
			$id=$k->{image_id};
			my ($a,$b)=split(" ",$k->{inserted});
			$name=$name."<br><b>In</b>:".$a;
		}else{
			$name=$k->name();
			$id=$k->image_id();
		}
		$view="<a href=\"#\" onClick=\"return openPopUpImage($id)\"><img src=/perl2/serve.pl?Page=OME::Web::ThumbWrite&ImageID=".$id." align=\"bottom\" border=0></a>";

		#$view=buttonPopUp($id,"View","openPopUpImage");
	
	   	my %h=(
		1 =>	{ content=>$name,	attribute=>$self->{cellLeft}},
		2 => 	{ content=>$id, attribute=>$self->{cellLeft}},
		3 =>  { content=>$view, attribute=>$self->{cellCenter}},
		);		
		$rows.=addRow(\%h);
	}
	if (defined $border){
		$html.=writeTable($rows,$self->{tableDefaults});
	}else{
		$html.=writeTable($rows);
	}
	return $html;
}

##############
# Parameters:
#	ref = ref hash to write CheckBox
#	name = button submit name
#	value = button submit value
# Return: html code (table)

sub listImages{
	my $self=shift;
	my ($ref,$name,$value)=@_;
	my $html="";
	my $rows="";
	my $button=buttonInput("submit",$name,$value);
	my %h=(
	1=>{ content=>$button, attribute=>$self->{cellLeft}},
	);
	$html.="<h3>Please select images in the list below.</h3>";
	$html.=$self->writeCheckBoxImage($ref);
	$rows.=addRow(\%h);
	$html.="<br>";
	$html.=writeTable($rows);

	return $html;
}


#################
# Parameters:
#	ref =
# 	nameButton = name submit button
#	valueButton = name submit button

#	type = dataset/image
# Return: html code

sub manager{
	my $self=shift;
	my ($ref,$nameButton,$valueButton,$type)=@_;
	my $rows="";	
	my $html="";
	my $typ=lc($type);
	my ($name,$related);
	if ($typ eq "dataset"){
		$name="<b>Datasets</b>";
		$related="<b>Projects related</b>";
	}else{
		$name="<b>Images</b>";
		$related="<b>Datasets related</b>";
	}
	my $button=buttonInput("submit",$nameButton,$valueButton);
	my %Ha=(
	1=>{	content=>$button,attribute=>$self->{cellCenter} },
	);
	my %H=(
	1=>{ content=>$name,attribute=>$self->{cellLeft}},
	2=>{ content=>$related,attribute=>$self->{cellLeft}},
	);
	
	$rows.=addRow(\%H);
	foreach my $k (keys %$ref){
		my $checkBox;
		if ($typ eq "dataset"){
		   $checkBox=writeCheckBox($k,${$ref}{$k}->{list});
		}else{
		   $checkBox=writeCheckBox($k,${$ref}{$k}->{list},1,${$ref}{$k}->{remove});
		}
		my %h=(
		1 =>	{ content=>${$ref}{$k}->{text},attribute=>$self->{cellLeft}},
		2 => 	{ content=>$checkBox, attribute=>$self->{cellLeft}},
		);		
		$rows.=addRow(\%h);
	}

	$html.=writeTable($rows,$self->{tableDefaults});
	my $rowButton=addRow(\%Ha);
	$html.=writeTable($rowButton);

	return $html;
	

}


#######################
# Parameters:
#	type= dataset/project
# Return: html code sentence

sub noNameMessage{
	my $self=shift;
	my ($type)=@_;
	my $html="";
	$html.="<b>Please enter a name for your ".$type."</b><br>";
	return $html;
}

########################
# Parameters:
#	ref = ref array of project object
#	bool= if defined Delete column added
# Return: html code table

sub projectList{
	my $self=shift;
	my ($ref,$bool)=@_;
	my $rows="";
	my $html="";
	my %H=(
	1	=> { content=>"<b>Name</b>",attribute=>$self->{cellLeft}},
	2	=>{ content=>"<b>ID</b>",attribute=>$self->{cellLeft}},
	3	=>{ content=>"<b>Select</b>",attribute=>$self->{cellCenter}},
	4	=>{ content=>"<b>Project Info</b>",attribute=>$self->{cellCenter}},
	);
	$H{5}	= { content=>"<b>Delete</b>",attribute=>$self->{cellCenter}} if (defined $bool);
	$rows.=addRow(\%H);
	foreach (@$ref){
		my ($select,$delete,$info);
		$info=buttonPopUp($_->project_id(),"Info","openInfoProject");
		$select=buttonInput("submit",$_->project_id(),"Select");
		$delete=buttonInput("submit",$_->project_id(),"Delete") if (defined $bool);
		my %h=(
		1 =>	{ content=>$_->name(),attribute=>$self->{cellLeft}},
		2 => 	{ content=>$_->project_id(),attribute=>$self->{cellLeft}},
		3 =>  { content=>$select, attribute=>$self->{cellCenter}},
		4 =>  { content=>$info, attribute=>$self->{cellCenter}},
		);

		$h{5} =  { content=>$delete, attribute=>$self->{cellCenter}} if (defined $bool);
		$rows.=addRow(\%h);
	}
	
	$html.=writeTable($rows,$self->{tableDefaults});

	return $html;
}




####################
# Paramaters:
#	ref = ref array of object
#	userID = current userID
#	name = Dataset(s)/Project(s)
#	type = project/dataset
#	refSelect =ref hash if dataset
# Return: html code table

sub searchResults{
	my $self=shift;
	my ($ref,$userID,$name,$type,$refSelect)=@_;
	my $rows="";
	my $html="";
	my $typ=lc($type);
	my %H=(
	1	=> { content=>"<b>Name</b>",attribute=>$self->{cellLeft}},
	2	=>{ content=>"<b>Select</b>",attribute=>$self->{cellCenter}},
	3	=>{ content=>"<b>Info $type</b>",attribute=>$self->{cellCenter}},
	);
	$rows.=addRow(\%H);
	foreach (@$ref){
		my ($select,$info);
		if ($typ eq "project"){
			$info=buttonPopUp($_->{project_id},"Info","openInfoProject");
			if ($userID==$_->{owner_id}){
			   $select=buttonInput("submit",$_->{project_id},"Select");
			}else{
			   $select="not allowed";
			}
		}else{
			$info=buttonPopUp($_->{dataset_id},"Info","openInfoDataset");
			if (exists(${$refSelect}{$_->{dataset_id}})){
			    $select=buttonInput("submit",$_->{dataset_id},"Select");

			}else{
			    $select="not allowed";

			}

		}
		my %h=(
		1 =>	{ content=>$_->{name},attribute=>$self->{cellLeft}},
		2 =>  { content=>$select, attribute=>$self->{cellCenter}},
		3 =>  { content=>$info, attribute=>$self->{cellCenter}},
		);		
		$rows.=addRow(\%h);
	}

	$html.="<h3>List of $name matching your data</h3>";
	$html.=writeTable($rows,$self->{tableDefaults});

	return $html;
}


#############
# Parameters:
#	experimenter = experimenter object
#	project = project object
#	dataset = dataset object
# Return: html code

sub titleBar{
	my $self=shift;
	my ($experimenter,$project,$dataset)=@_;
	my $rows="";
	my $html="";
	my $text="";
	my %a=(
	"width"=>105
	);
	my %b=(
	"cellspacing" => 0, 
	"cellpadding" => 2, 
	"border" => 0, 
	"width" => "100%" 
	);

	my $image=singleTag("img",$self->{imageDefaults});
	my ($sDataset,$sProject,$welcome);

	if (defined $project){
		$sProject="You are working on project:<b>".$project->name()."</b><br>",
	}else{
		$sProject=" no project defined <br>";
	}
	if (defined $dataset){
		$sDataset="You are working on dataset:<b>".$dataset->name()."</b><br>",
	}else{
		$sDataset.="no dataset defined <br>";
	}
	$welcome="Welcome ".$experimenter->FirstName()." ".$experimenter->LastName()."<br>";
	
	$text.=$welcome.$sProject.$sDataset;

	my %h=(
	1	=>{ content =>$image, attribute=>\%a},
	2	=>{ content =>$text, attribute=>$self->{cellCenter}},
	);
	$rows.=addRow(\%h);
	$html.=writeTable($rows,\%b);

	return $html;



}






###############
# Parameters:
#	ref =ref hash with value button
#	defaultRadio = 1/2 to choose with one to check
#	name	= name input button
# Return: ref array with html code

sub radioButton{
	my $self=shift;
	my ($ref,$defaultRadio,$name)=@_;
	my @list=();
	#foreach my $k (sort {$a <=> $b}  keys %$ref){
	 foreach my $k (sort {$a <=> $b} keys %$ref){

		my $button="";
		if ($k==$defaultRadio){
		      $button.=buttonInput("radio",$name,${$ref}{$k}->{name},undef,"checked");
		}else{
			$button.=buttonInput("radio",$name,${$ref}{$k}->{name});
		}
		$button.=${$ref}{$k}->{text};
		push(@list,$button);
	}
	
	return \@list;
}


###################
# PRIVATE METHODS #
###################
sub addRow{
	my ($ref)=@_;
	my $html="";
	$html.=openTag("tr");
	foreach (sort {$a <=> $b} keys %$ref){
		$html.=openTag("td",${$ref}{$_}{attribute});
		$html.=${$ref}{$_}{content};
		$html.=closeTag("td");
	}
	$html.=closeTag("tr");
	return $html;


}


sub writeAttribute{
	my ($ref)=@_;
	my $html="";
	my @end=();
	foreach (keys %$ref){
	  my $a=$_."=\"".${$ref}{$_}."\"";
	  push(@end,$a);
	}
	if (scalar(@end)==0){
	return undef;
	}else{
	$html.=join(" ",@end);
	return $html;
	}
}

sub writeDropDow{
	my ($ref,$refTag)=@_;
	my $html="";
	$html.=openTag("select",$refTag);
  	my %h=%$ref;
	foreach (sort {$a cmp $b} keys %h){		# id=>name
		my %a=(
			"value"=>$_
			);
		$html.=openTag("option",\%a);
		$html.=$h{$_};
		$html.=closeTag("option");
	}
	$html.=closeTag("select");
	return $html;



}




sub writeTable{
	my ($txt,$a)=@_;
	my $html="";
	if (defined $a){
		$html.=openTag("table",$a);
	}else{
		$html.=openTag("table");
	}
	$html.=$txt;
	$html.=closeTag("table");
	return $html;

}





sub openTag{
	my ($name,$ref)=@_;
	my $html="";
	my $attribute;
	$attribute=writeAttribute($ref);
	if (defined $attribute){
		$html.="<".$name." ".$attribute.">";
	}else{
		$html.="<".$name.">";
	}
	return $html;
}

sub closeTag{
	my ($name)=@_;
	my $html="";
	$html.="</".$name.">";
	return $html;

}

sub singleTag{
	my ($name,$ref)=@_;
	my $html="";
	if (defined $ref){
		my $attribute=writeAttribute($ref);
		$html.="<".$name." ".$attribute."/>";
	}else{
		$html.="<".$name."/>";
	}

	return $html;
}


sub buttonPopUp{
	my ($id,$value,$function)=@_;
 	my $text="";
	my %a;
	my $val="return $function($id)";
	%a=(
	 "type" 	=>"button",
	 "onclick" 	=>$val,
	 "value" 	=>$value,
	 "name"	=>"submit"
	);
	$text.=openTag("input",\%a);
 	return $text;

}

sub buttonInput{
	my ($type,$name,$value,$size,$checked,$onclick)=@_;
	my $text="";
	
	my %a=(
	"type"	=>$type,
	"name"	=>$name,
	);
	$a{"value"}=$value if (defined $value);
	$a{"size"}=$size if (defined $size);
	$a{"checked"}=$checked if (defined $checked);
	$a{"onclick"}=$onclick if (defined $onclick);
	$text.=openTag("input",\%a);
	return $text;
}

sub buttonArea{
	my ($name,$rows,$cols,$value)=@_;
	my $text="";
	my %a=(
	"name"	=>$name,
	"rows"	=>$rows,
	"cols"	=>$cols,
	);
	$text.=openTag("textarea",\%a);
	$text.=$value if defined $value;
	$text.=closeTag("textarea");

	return $text;

}


sub writeCheckBox{
	my ($id,$ref,$type,$refRemove)=@_;
	my @list=();
	my $html="";
	foreach (keys %$ref){
		my $pair=$id."-".$_;
		my $val="";
		if (defined $type){
		   if (defined ${$refRemove}{$_}){
		     $val.=buttonInput("checkbox","List",$pair);
		   }
		}else{
		   $val.=buttonInput("checkbox","List",$pair);
		}
		$val.=${$ref}{$_}->name();
		push(@list,$val);
	}
	$html.=join("<br>",@list);
	return $html;

}

sub writeCheckBoxImage{
	my $self=shift;
	my ($ref)=@_;
	my @list=();
	my $html="";
	foreach my $i (keys %$ref){
	 	my $val="";
		my $view="<a href=\"#\" onClick=\"return openPopUpImage($i)\"><img src=/perl2/serve.pl?Page=OME::Web::ThumbWrite&ImageID=".$i." align=\"bottom\" border=0></a>";

		#my $view=buttonPopUp($i,"View","openPopUpImage");
		#$val.=$view."&nbsp;&nbsp;";
		$val.=$view."<br>";
	 	$val.=buttonInput("checkbox","ListImage",$i);
	 	$val.=${$ref}{$i}->name();
		push(@list,$val);
	}
	$html.=$self->gallery(\@list);
	#$html.=join("<br>",@list);
	return $html;
}


sub YMD{

my %month=(
""	=>"-",
"01"	=>"Jan",
"02"	=>"Feb",
"03"	=>"Mar",
"04"	=>"Apr",
"05"	=>"May",
"06"	=>"Jun",
"07"	=>"Jul",
"08"	=>"Aug",
"09"	=>"Sep",
"10"	=>"Oct",
"11"	=>"Nov",
"12"	=>"Dec",
);
my %day=(
""	=>"-",
"01"	=>"01",
"02"	=>"02",
"03"	=>"03",
"04"	=>"04",
"05"	=>"05",
"06"	=>"06",
"07"	=>"07",
"08"	=>"08",
"09"	=>"09",
"10"	=>"10",
"11"	=>"11",
"12"	=>"12",
"13"	=>"13",
"14"	=>"14",
"15"	=>"15",
"16"	=>"16",
"17"	=>"17",
"18"	=>"18",
"19"	=>"19",
"20"	=>"20",
"21"	=>"21",
"22"	=>"22",
"23"	=>"23",
"24"	=>"24",
"25"	=>"25",
"26"	=>"26",
"27"	=>"27",
"28"	=>"28",
"29"	=>"29",
"30"	=>"30",
"31"	=>"31",
);

my %year=(
""	=>"-",
"2003"=>"2003",
"2002"=>"2002",
"2001"=>"2001",
);
return (\%year,\%month,\%day);
};




=head1 AUTHOR

JMarie Burel (jburel@dundee.ac.uk)

=head1 SEE ALSO

L<OME::Web::Helper::JScriptFormat|OME::Web::Helper::JScriptFormat>,


=cut


1;
