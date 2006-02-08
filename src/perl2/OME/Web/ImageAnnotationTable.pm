#OME/Web/ImageAnnotationTable.pm

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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::ImageAnnotationTable;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use base qw(OME::Web);

sub getPageTitle {
    return "OME: Image Annotation Table";
}

{
    my $menu_text = "Image Annotation Table";
    sub getMenuText { return $menu_text }
}


=head1 getPageBody
    
=cut


sub getPageBody {
    my $self = shift ;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();

    # Load the correct template and make sure the URL still carries
    # the template  name.
    # get template from url parameter, or referer


    my $which_tmpl = $q->url_param('Template');
    my $referer = $q->referer();
    my $url = $self->pageURL('OME::Web::ImageAnnotationTable2');
    if ($referer && $referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
	$which_tmpl = $1;
	$which_tmpl =~ s/%20/ /;
	return ('REDIRECT', $self->redirect($url.'&Template='.$which_tmpl));
    }
    $which_tmpl =~ s/%20/ /;


    # get the details. this is where the bulk of the work gets done.
    # use this procedure to allow for bulk of layout to be called from
    # other modules
    my $output = $self->getTableDetails($self,$which_tmpl);


    # and the form.
    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $output;
    $html .= $q->endform();

    return ('HTML',$html);	
}

=head1 getTableDetails

    getTableDetails does the meat of the work of building this page.
    We load the template, populate pull-downs that let us switch x and
    y axes, and render the various dimensions.
    
=cut

sub getTableDetails {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $q = $self->CGI();
    # container is the OME::Web object that is calling this code.
    my ($container,$which_tmpl) = @_;

    # load the appropriate information for the named template.
    my $tmplData = 
	$factory->findObject( '@BrowseTemplate', Name => $which_tmpl );

    
	
    # instantiate the template
    my $tmpl = 
	HTML::Template->new(filename => $tmplData->Template(),
			    case_sensitive=>1);
    


    # figure out what we have for rows and columns
    # if nothing is specified, we'll just stop.
    # if the same value is given for each dimension, we report an
    # error.
    $self->{rows} = $q->param('Rows');
    $self->{columns} = $q->param('Columns');
    my $cgName = $q->param('CategoryGroup');
    my $cg;
    if ($cgName) {
	$cg = $factory->findObject('@CategoryGroup',Name=>$cgName);
	$self->{CategoryGroup} = $cg;
    }

    # populate the pull-downs.
    my $types = $self->getTypes($tmpl);
    $self->getChoices($tmpl,$types);

    # do the list of categories
    # load  catlist
    
    # load CG st.
    my $categoryGroupST = $factory->findObject('OME::SemanticType', 
					       name =>'CategoryGroup');
    my @catGroupList = $factory->findObjects($categoryGroupST);
    my $cats =
	$self->Renderer()->renderArray(\@catGroupList,'list_of_options', {
	    default_value => $cg, type=> $categoryGroupST} );
    $tmpl->param('categoryGroups/render-list_of_options'=>$cats);


    if ($self->{rows} && $self->{columns}) {
	
	if ($self->{rows} eq $self->{columns}) {
	    $tmpl->param(errorMsg=>"You must choose different values for rows and columns\n");
	}
	else {
	    print STDERR "*** calling renderdims..\n";
	    my $hasData = $self->renderDims($tmpl,$types);
	    if ($hasData == 0) {
		$tmpl->param(errorMsg=>"No Data to Render\n");
	    }
	}
    }

    return $tmpl->output();
}

=head1

    getTypes - for the template. Finds the TMPL_VARS given in a 
    Path.load/types-[..] format. 
    
    this will be a list of paths, separated by commas.
    ecach path will be a colon-separated path of types leading from
    some root to a map that refers to an image.

    thus, 
    Path.load/types-[@Gene:@ProbeGene,@Probe:@ImageProbe,
                     @EmbryoStage:@ImageEmbryoStage]

    defines two dimensions.

    The result of this call will be a hash. The keys to the hash will
    be the first entries (the roots) in each of the dimension paths.

    
    For each key, the value will be the completely specified array of
    path objects.
    Thus, for the above example, we'll have the following result:

    { @Gene =>  ('@Gene','@ProbeGene','@Probe','@ImageProbe'),
      @EmbryoStage => ('@EmbryoStage','@ImageEmbryoStage') }
  
    The reference to the hash is returned as the value.

    TODO: Extend to handle Classifications.
=cut
sub getTypes {

    my $self= shift;
    my $tmpl = shift;
    my @parameters = $tmpl->param();
    my @found_params  = grep (m/\.load\/types/,@parameters);
    my $paramCount = scalar(@found_params);
    my %pathSet;
    # iterate over them in order
    for (my $i = 0; $i < $paramCount;  $i++) {

	my $param = $found_params[$i];

	# find the path value.
	$param =~ m/Path.load\/types-\[(.*)\]/;
	print STDERR "PARSING $param\n";
	#convert to array
	my @paths = split (/,/,$1);
	#now, each  entry in  @paths is something like
	#@Probe:@ProbeGene:@Probe:@ImageProbe,
	# etc.
	foreach my $path (@paths) {
	    print STDERR "splitting $path\n";
	    my @entries = split (/:/, $path);
	    # first item becomes a key
	    my $dimensionKey = $entries[0];
	    $pathSet{$dimensionKey} = \@entries;
	}
    }
    # return ref to array of refs.
    return \%pathSet;
}

=head1 getChoices

    getChoices populates the Columns and Rows pull-down menus in the
    template. This is done by iterating down the root types for each
    of the dimensions, stripping off the leading '@', and putting them
    into the template variable.
        
=cut
sub getChoices {
    my $self=shift;
    my $tmpl = shift;
    my $types = shift;

    my @rows;

    my @columns;
    foreach my $type (keys %$types) {
	# clear off header if it's an st
	$type =~ s/@(.*)/$1/;
	my %row;
	my %col;
	$row{rowName} = $type;
	push(@rows,\%row);
	$col{columnName} = $type;
	push (@columns,\%col);
    }
    $tmpl->param(Columns=>\@columns);
    $tmpl->param(Rows=>\@rows);
}

=head1 renderDims

    The main rendering code. Parameters are 
        $tmpl - the template being populated
        $rows - which dimension is selected for the row
              (as given by the 'Rows' parameter to the cgi or
                (eventually) the pull-down
        $columns  - similar to rows - the dimension selected for the colums
        $types - the types hash as returned from getTypes.

=cut

sub renderDims {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $q = $self->CGI();
    my ($tmpl,$types) = @_;
    my $rows = $self->{rows};
    my $columns = $self->{columns};
    my $hasData = 0;

    print STDERR "** in render dims.\n";
    # get the objects associated with the columns. Eventually, 
    # this will get replaced by something that drills down the row hierarchy
    my $rowKey = "@".$rows;
    my $rowPath = $types->{$rowKey};
    $self->{rowEntries} = $self->getObjects($rows,$rowPath);

    # same for columns.
    my $colKey = "@".$columns;
    my $colPath = $types->{$colKey};
    $self->{colEntries} = $self->getObjects($columns,$colPath);

    # populate the cells with data in a hash.
    # activeRows returns a list of rows that have data,
    # active cols indicates columns
    
    # will have to change this to have rows and columns be levels of
    # leaves in hierarchy, not "GEne",etc.
    my ($cells,$activeRows,$activeCols) =
	$self->populateCells($types);

    # if any data, populate the template
    if ($cells) {
	$hasData=1;

	# # of columns is the number of active columns + the 
	# number of columns needed for row paths..
	my $rowEntrySize = $self->getHeaderSize($self->{rowEntries});


	my $colCount =
	    scalar(@$activeCols)+$rowEntrySize;

	$tmpl->param(colCount=>$colCount);

	my $cHeaders = $self->populateColumnHeaders($activeCols,$rowEntrySize);
	$tmpl->param(columnHeaders=>$cHeaders);

	my $body =
	    $self->populateBody($cells,$activeRows,$activeCols);
	$tmpl->param(cells=>$body);
    }
    return $hasData;
}

=head1 

    getObjects gets the objects of interest for a given hierarchy.
    Given a Type (Probe,EbmbryoStage, etc.) and a set of paths from
    that type to something that maps to images, find the objects that
    are of interest.

    There are two possibilities. If there is a CGI parameter
    corresponding to the input type - (ie., if Type=Probe and there is
    a CGI parameter Probe=...), take the values given in that CGI
    parameter and use them to identify the root set. Otherwise, find
    all objects of the given root type.

    As the type specification given in the $paths argument can contain
    an arbitray list of types leading from some root down to the
    leaves, getObjects returns an array of paths. Each path is itself
    an array, with the first element being the name of the root object being
    searched for, and subsequent elements being names of objects along
    the way to the atual root objet, whih is the last item in the array.

=cut

sub getObjects {
    my $self=shift;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $q = $self->CGI();

    my $type =shift; # type is Probe,EmbryoStage, etc.
    my $paths = shift;

    # load the type
    my $typeST =
	$factory->findObject('OME::SemanticType',{name=>$type});
    $typeST->requireAttributeTypePackage();
    # get root vaalue
    my $root = $q->param($type);

    my $objsRef;
    if ($root) {
	# get objects that match the root
	print STDERR "*** root object $root, type - "  . $typeST->name . "\n";
	# do single object - or some set of objects
	$objsRef = $self->getRoots($typeST,$root);
    }
    else {
	# get all of the given type.
	my @objs = $factory->findObjects($typeST, {__order => 'id'});
	$objsRef = \@objs;
    }
    
    print STDERR "*****GET OBJECTS***\n";
    for (my $i =0; $i < (@$objsRef); $i++ ) {
	print STDERR "NAME: " . $objsRef->[$i]->Name . ", id " .
	    $objsRef->[$i]->id . "\n";
    }
    # now, objsRef is a reference to an aaray containing the list of
    # top-level items that I want to work with
    my $tree = $self->getTreeFromRootList($objsRef,@$paths);
    my $flatTree = $self->flattenTree($tree);
    # strip ids off of items.
    for (my $i = 0; $i < scalar(@$flatTree); $i++ ) {
	my $ent = $flatTree->[$i];
	for (my $j = 0; $j < scalar(@$ent)-1; $j++) {
	    my $val = $ent->[$j];
	    $val =~ m/([^_]*)__\d+/;
	    print STDERR "***VAL IS $val, match is $1\n";
	    $ent->[$j]=$1;
	}
    }
    return $flatTree;
}




=head1 getRoots 

    get the root objects corresponding to a comma-separated list of
    objects from the CGI parameter. load the object either by Name or
    by Id.
=cut

sub getRoots {
    my $self = shift;
    my ($rowType,$rootList) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my @objs;
    my @roots = split(/,/,$rootList);
    my $obj;
    foreach my $root (@roots) {
	undef $obj;
	if ($root =~ /^\d+$/) {
	    # load by id
	    $obj = $factory->loadObject($rowType,$root);
	}
	else {
	    $obj = $factory->findObject($rowType,Name=>$root);   
	}
	if ($obj) {
	    push(@objs,$obj);
	}
    }
    return \@objs;
}

=head1 getTreeFromRootList

    Given  a list of root objects and a list of object types, populate
    the tree. The result is a reference to a hash of hashes that
    contains the values in the tree.

    Thus, if the path is @Gene:@ProbeGene:@Probe:@ImageProbe, the
    resulting hash will be keyed with the names of all of the genes
    passed in as roots - @$objs.  For each gene, the hash will contain
    an entry for each Probe. The entry for each probe will be a hash
    keyed by the name of the probe, with the actual probe object as a
    value.

    Note that mapping classes are not included in the result, as they
    are only used to find the next level of descendant in the
    tree. Furthermore, we stop before we get to the last entry -
    (ImageProbe), as the combination of the entries at the second to
    last level (Probe) and the name of the last level (ImageProbe) is
    sufficient to get images for a given leaf object. To see why this
    is the case, note that the leaves will be Probe instances. So, to
    find the Images for a probe, we can look for images where
    ImageProbeList.Probe => our probe instance.

=cut

sub getTreeFromRootList {
    my $self =shift;
    my ($objs,@paths) = @_;

    shift @paths; # discard first type - root of list.
    my %tree;
    foreach my $obj (@$objs) {
	my $name = $obj->Name();
	my $id= $obj->id();
	my $key = $name . "__" . $id;
	$tree{$key} = $self->getTree($obj,@paths);
    }
    return \%tree;
}


=head1 getTree

    The workhorse that does the job of recursively building the tree
    for a given object.
=cut

sub getTree {
    my $self= shift;
    # note that we pass the type path in as an array, not a ref. to an
    # array. This guarantees that the array will be copied, so we
    # don't need to do an explicit copy with each recursion

    my ($obj,@paths) = @_;

    # now, $obj is a gene, $paths is
    # [@ProbeGene,@Probe,@ImageProbe]
    # or, map followed by class followed by map.

    #termination condition - stop when we've hit the last non-map
    #class (in this case, probe),  and   simply return the object.

    return $obj if (scalar(@paths) < 2);

    # strategy. find all of the maps 
    # load the mapping type (ie, ProbeGene)
    my $map = shift @paths;
    $map =~ s/@(.*)/$1/;

    # next type is probe.
    my $next = shift @paths;
    $next =~ s/@(.*)/$1/;

    my $accessor = "${map}List"; #
    my @maps = $obj->$accessor;  # ie., ProbeGeneList.
    my %tree;
    foreach my $map (@maps) { # for each map
	my $child = $map->$next; # follow the pointer to the next
				# object (ie., ProbeGeneList->Probe)
	my $name = $child->Name(); # get the name
	my $id = $child->id();
	my $key = $name . "__" . $id;
	$tree{$key} = $self->getTree($child,@paths); #recurse
    }
    return \%tree;
}


=head1 flattenTree

    given a tree from getTreeFromRootList, this will turn flatten it
    into an array of values. This array will contain one entry for
    each of the leaves in the tree. These entries will consist of the
    complete path from a root object to a leaf. For all items in the
    list except for the leaf, the name of the object is given. For the
    leaf, the object itself is given
    

    This data is, of course, very redundant, but it is useful for
    populating table columns and headers.


=cut
sub flattenTree {
    my $self=shift;
    my $tree = shift;
    my @rows;

    #termination - must return an array of arrays 
    if (ref($tree) ne 'HASH') {
	my @res;
	push @res,$tree;
	my @res2;
	push @res2,\@res;
	return \@res2;
    }

    #recursion
    foreach my $key (keys %$tree) {
	my $val = $tree->{$key};
	# recurse
	my $valRows = $self->flattenTree($val);
	foreach my $valRow (@$valRows) {
	    # for each val in valrows, 
	    # add key to the front
	    unshift @$valRow,$key;
	    push @rows,$valRow;
	}
    }
    # sort the rows by id of first item.
    my @sortedRows = sort sortByIdKey @rows;
    return \@sortedRows;
}


sub sortByIdKey {
    $a->[0]=~ /[^_]*__(\d+)/;
    my $aID = $1;
    $b->[0]=~ /[^_]*__(\d+)/;
    my $bID = $1;
    return $aID <=> $bID;
}

    


=head1 populateCells
    Get the objects to fill the cell.

    $rowName is the Name of the rows - Probe,etc.
    $rowEntries are those things found in the rows
        ditto for colname
    $types is the type hash
=cut
sub populateCells {
    my $self=shift;
    my $session = $self->Session();
    my $factory = $session->Factory();

    my ($types) = @_;
    my $rowName= $self->{rows};
    my $colName = $self->{columns};
    my $rowEntries = $self->{rowEntries};
    my $colEntries = $self->{colEntries};
    # get rows by accessor 'ImageProbeList.Probe
    # to do this, get type entry for row,
    # get last entry - that gets us image probe.
    my $rowAccessor = $self->getAccessorName($rowName,$types);
    my $columnAccessor = $self->getAccessorName($colName,$types);
    

    my $cells;
    my %activeRows;
    my %activeColumns;
    my $hasData =0;

    foreach my $row (@$rowEntries) {
	# this is the of objects that define the row. let's get the
	# last item
	my $rowLeaf = $row->[scalar(@$row)-1];
	my $rName = $rowLeaf->Name;
	foreach my $col (@$colEntries) {
	    my $colLeaf = $col->[scalar(@$col)-1];
	    my $cName = $colLeaf->Name;
	    # for each row and column, get images.
	    my @images = $factory->findObjects('OME::Image',
					       { $rowAccessor => $rowLeaf,
						 $columnAccessor =>
						     $colLeaf,
						     __distinct	=>'id'});
	    # if I find any, store them in double-hashed - keyed off
	    # of row name and column name.
	    # indicate when a row and column is active.
	    if (@images && scalar(@images) > 0) {
		$cells->{$rName}->{$cName}  = \@images;
		$activeRows{$rName}=1;
		$activeColumns{$cName} = 1;
		$hasData =1;
	    }
	}
    }
    return (undef,undef,undef) if ($hasData == 0);

    my $aRows = $self->getActiveList($rowEntries,\%activeRows);
    my $aColumns = $self->getActiveList($colEntries,\%activeColumns);
    return ($cells,$aRows,$aColumns);
}

=head1 getAccessorName

    Build up the accessor to $fieldName (ie., Probe).
    given an image, we would go to ${someType}List to get the mapping
    to an image, and then ${SomeType}List.${FieldName} to get to the
    object.
    
    Thus, if $fieldName is 'Probe', and $someType = {'ImageProbe'}
    the accessor name is ImageProbeList.Probe, which, when given a
    specifc probe value , can be used to grab the images corresponding
    to that probe
=cut

sub getAccessorName {
    my $self = shift;
    my ($fieldName,$types) = @_;
    
    # field name is the root of this particular dimension.
 
    # need to get last type - which is the map (ie., ImageProbe
    # and second to last - which is the items that we retrieved - the
    # last row/column item. (ie, Probe).
    
    print STDERR "****Getting accessor name for $fieldName\n";
    my $fName = "@" . $fieldName;
    my $path = $types->{$fName};
    print STDERR "** associated path is $path\n";
    my $count = scalar(@$path);
    my $listAccessor = $path->[$count-1];
    my $rootItem = $path->[$count-2];

    $listAccessor =~ s/@(.*)/$1/;
    $rootItem =~ s/@(.*)/$1/;
    my $accessor = "${listAccessor}List.$rootItem";
    print STDERR "accessor name is $accessor \n";
    return $accessor;
}

=head1 getActiveList
    We want to get things into a result list in the same order in which
    they were in the original list, so using keys of the hash is not
    enough. Sorting is also inappropriate, as position in list is
    semantically determined (1-cell, morula,blastocyst, etc), as opposed
    to lexicographically determined. So, assume that they  got in to the 
    list correctly, and we're just going to preserve those values.
=cut
sub getActiveList {
    my $self=shift;
    my ($items,$active) = @_;
    my @results;
    foreach my $entry (@$items) {
	my $item = $entry->[scalar(@$entry)-1];
	my $name = $item->Name;
	#push (@results,$name) if ($active->{$name});
	# store the whole entry, so we can use it to recontruct the
	# header
	push (@results,$entry) if ($active->{$name});
    }
    return \@results;
}
 

=head1 populateColumnHeaders

    put headers in the columns of the table.

=cut
sub populateColumnHeaders {
    my $self=shift;
    my ($columns,$rowSize) = @_;
    my  $emptyHeaders = $self->populateEmptyColumnHeaders($rowSize);
    my @headers;
    my $firstCol = $columns->[0];
    my $rowCount = scalar(@$firstCol)-1; # of rows in column headers
    # is one less than the number of element in the first column.

    my @prevColumns;
    for (my $i =0; $i < $rowCount; $i++)  {
	my %header;
	$header{emptyColumnHeaders} = $emptyHeaders;
	my @columns;

	for (my $j = 0; $j < scalar(@$columns); $j++) {
	    my  $val = $columns->[$j]->[$i];
	    print STDERR "** looking at $val, column $j, row $i, previous " 
		. " is " . $prevColumns[$i] . "\n";

	    my $same =1;
	    # look @ all previous entries in this column to see if
	    # they match
	    for (my $k = 0; $k <= $i; $k++) {
		if ($columns->[$j]->[$k] ne $prevColumns[$k]) { 
		    $same  = 0;
		    last;
		}
	    }
	    if (!$same) {
		my %column;
		my $colSpan =
		    $self->getRepeatCount($columns,$j,$i);
		print STDERR "*** get repeat count in columns is $colSpan\n";
		$column{columnNameEntry} = $val;
		$column{columnNameSpan} = $colSpan;
		push(@columns,\%column);
		$prevColumns[$i] = $val;
	    }
	}
	# do each of the headers.

	$header{columnNameEntries} = \@columns;
	push(@headers,\%header);
    }
    return \@headers;
}


sub populateEmptyColumnHeaders {
    my $self=shift;
    my $size = shift;
    
    my @headers;
    print STDERR "*** # of empty columns!!!  $size \n";
    for (my $i=0; $i < $size; $i++) {
	my %header;
	$header{emptyColumnHeader}="";
	push(@headers,\%header);
    }
    return \@headers;
}

=head1 getHeaderSize

    return the number of items that must be printed in the header for
    each row/column
=cut
sub getHeaderSize {
    my $self= shift;
    my $rowEntries = shift;
    my $row = $rowEntries->[0];
    my $size =scalar(@$row)-1;
    return $size;
}

=head1 populateBody

    Populate the body, one row at a time.
=cut

sub populateBody {
    my $self= shift;

    my ($cells,$activeRows,$activeCols) = @_;
    my @cellRows;

    my  @prev; # what's in the previously printed row.
    
    for (my $rowIndex= $0 ; $rowIndex <scalar(@$activeRows);
	 $rowIndex++) {
	my $row = $activeRows->[$rowIndex];
	my %rowContents;
	my @entries;
	
	my  $same=1; # are we in same row as previous?

	for (my $i = 0; $i < scalar(@$row)-1; $i++) {
	    my $val = $row->[$i];
	    if ($val ne $prev[$i] || $same == 0) {
		my %entry;
		my $rowSpan = 
		    $self->getRepeatCount($activeRows,$rowIndex,$i);
		$entry{rowNameEntry} = $val;
		$entry{rowNameSpan} = $rowSpan;
		push(@entries,\%entry);

		$prev[$i] = $val;
		$same = 0;
	    }
	    else {
		$same = 1;
	    }
	}
	$rowContents{rowName} = \@entries;
	$rowContents{rowCells} = $self->populateRow($cells,$row,$activeCols);
	push (@cellRows,\%rowContents);
    }
    return \@cellRows;

}


#sub getRepeatCount {
 #   my ($self,$entries,$start,$field,$val) = @_;
    
  #  my $cnt;
   # for (my $i=$start; $i < scalar(@$entries); $i++) {
	#my $rec = $entries->[$i];
	#if ($rec->[$field] eq $val) {
	#    $cnt++;
	#}
	#else {
	#    return $cnt;
	#}
#    }
#    return $cnt;
#}

sub getRepeatCount {
    my ($self,$entries,$start,$field) = @_;

    my $template = $entries->[$start];
    my $cnt = 1;
    for (my $j = $start+1; $j < scalar(@$entries); $j++) {
	my $rec = $entries->[$j];
	for (my $k = 0; $k <= $field; $k++) {
	    return $cnt if ($rec->[$k] ne $template->[$k]); # ok,
				# we're done - unequal filed
	}
	$cnt++;
    }
    return $cnt;
}
    
    
    
    
sub printHeaderInfo {
    my $self=shift;
    my ($field,$data) =@_;
    my @entries;
    for (my $i=0; $i < scalar(@$data)-1; $i++) {
	my %entry;
	$entry{$field} = $data->[$i];
	push(@entries,\%entry);
    }
    return \@entries;
}

=head1 populateRow

    put sets of images in each cell.
=cut
sub populateRow {
    my $self=shift;
    my ($cells,$row,$activeCols) = @_;
    my $cg= $self->{CategoryGroup};

    my $rowLeaf = $row->[scalar(@$row)-1];
    my $rowName = $rowLeaf->Name;
    my @cells;
    foreach my $col (@$activeCols) {
	# $col s the entire path array for each column
	# find the last entry in it.
	my $colLeaf = $col->[scalar(@$col)-1];
	my $colName = $colLeaf->Name;
	my $images = $cells->{$rowName}->{$colName};
	my $cell = $self->getRendering($images,$cg);
	push(@cells,$cell);
    }
    return \@cells;
}

sub getRendering {
    my ($self,$images,$cg) = @_;
    my %cell;
    if ($images) {
	my $sortedImages = $self->sortImagesByCG($images,$cg);
	my $rendering =
	    $self->Renderer()->renderArray($sortedImages,
					   'color_code_ref_mass_by_cg'
					   ,{type=>'OME::Image',
					     CategoryGroup =>
						 $cg});
	$cell{cell} = $rendering;
    }
    return \%cell;
}

# for each image, get the cg.
# populate a new array. each element in this array is a pair
# containing [$cgid, $image];
# sort the array by cg
# return the images.
sub sortImagesByCG {
    my ($self,$images,$cg) = @_;
    
    my @cgArray;
    foreach my $image (@$images) {
	my $classification = 
	    OME::Tasks::CategoryManager->getImageClassification($image,$cg);
	my $catName="";
	if ($classification) {
	    $catName = $classification->Category->Name;
	}
	my @imgDetail = ($catName,$image);
	push(@cgArray,\@imgDetail);
    }
    
    # sort by category group name
    my @sortedImages = sort { $a->[0] cmp $b->[0] } @cgArray;

    # pull images out of sorted list.
    my @newImages = map {$_->[1]} @sortedImages;

    return \@newImages;
}


1;




















