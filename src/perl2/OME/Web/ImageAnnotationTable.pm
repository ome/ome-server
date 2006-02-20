# OME/Web/ImageAnnotationTable.pm
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

=head1 NAME

OME::Web::ImageAnnotationTable - An OME page displaying a table of
    images as annotated in one or more hierarchies.

=head1 DESCRIPTION

    Analysis and interpretation of annotated images often requires
    displays tailored to specific experimentals. 

    Images from WISH screens of pre-implementation mouse embryos
    (Yoshikawa, et al., Gene Expression Patterns 6(2), January 2006)
    involve categorization of images by genes and associated probes
    (on the one hand) and stage of embryonic development (on the other). 

    Given these annotations, images can be displayed in  grid, with
    development stages as the columns and genes/probes forming the
    rows (Yoshikawa, et al., Figure 3). 

    ImageAnnotationTable is an OME::Web page tha supports this
    layout. Furthermore, for any given grid construction, images
    within a cell can be color-coded on the basis of values from a
    specified category group.

=head1 USAGE
    
    This page can be served via the usual OME dispatcher. Parameters
    needed for proper execution include:


    Template=GeneProbeTable:  - the name of an instance of the
    AnnotationTemplate semantic type. This intance must refer to an
    HTML::Template file that has a specification of the types that
    will be used to populate the output of the table. This
    specification will take the form of:

    <TMPL_VAR   NAME="Path.load/types-[Gene:ProbeGene:Probe:ImageProbe,
    EmbryoStage:ImageEmbryoStage]"> 

    This list has two items. Each are lists of data types and mapping types
    that go from some root type down to some mapping type that can be
    used to retrieve sets of images. Each list must start with a data
    type and then provide a mapping type that maps to some other data
    type. This pattern will repeat until a final mapping type is
    reached. The final mapping type will implicitly point to a list of
    images.

    Rows=Gene, Columns=EmbryoStage: These parameters will specify the
    root types to be used for the rows and columns of the output
    table. These names must correspond to the initial values given in
    the "Path.load/types" specification lists.
    
    CategoryGroup=Localization: the category group used for
    color-coding of the images. Note that no color-coding will be used
    if this value is left unspecified.

=head1 METHODS

=cut


use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use base qw(OME::Web);

sub new {
    my $proto =shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    
    # some private variables
    # the names for the rows, columns, and category group
    $self->{rows}="";
    $self->{columns}="";
    $self->{CategoryGroup}="";
    $self->{Category}="";
    $self->{Template} ="";
    # the actual rows and columns
    $self->{rowEntries} = undef;
    $self->{colEntries} = undef;
    
    return $self;
}

sub getPageTitle {
    return "OME: Image Annotation Table";
}

{
    my $menu_text = "Image Annotation Table";
    sub getMenuText { return $menu_text }
}


=head2 getPageBody
    
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
    $self->{Template}=$which_tmpl;


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

=head2 getTableDetails

    my $output = $self->getTableDetails($container,$which_tmpl);

    getTableDetails does the meat of the work of building this page.
    We load the template, populate pull-downs that let us switch x and
    y axes, and render the various dimensions.

    $container is the object that calls this code. 
    $which_tmpl is the template that we are populating
    
    
=cut

sub getTableDetails {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    # container is the OME::Web object that is calling this code.
    my ($container,$which_tmpl) = @_;
    my $q = $container->CGI();
    my %tmpl_data;
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



    # populate the pull-downs.
    my $types = $self->getTypes($tmpl);
    $self->getChoices(\%tmpl_data,$types);

    $tmpl_data{'categoryGroups/render-list_of_options'}=
	$self->getCategoryGroups($container);

    $self->{Category} = $q->param('Category');

    if ($self->{rows} && $self->{columns}) {
	
	if ($self->{rows} eq $self->{columns}) {
	    $tmpl_data{errorMsg}="You must choose different values for rows and columns\n";
	}
	else {
	    my $hasData = $self->renderDims($container,\%tmpl_data,$types);
	    if ($hasData == 0) {
		$tmpl_data{errorMsg}="No Data to Render\n";
	    }
	}
    }
    $tmpl->param(%tmpl_data);
    return $tmpl->output();
}


=head2

    my $types = $self->getTypes($tmpl);

    getTypes - for the template. For a gievn template, 
    finds the TMPL_VARS given in a  Path.load/types-[..] format. 
    
    this will be a list of paths, separated by commas.
    ecach path will be a colon-separated path of types leading from
    some root to a map that refers to an image.

    thus, 
    Path.load/types-[Gene:ProbeGene,Probe:ImageProbe,
                     EmbryoStage:ImageEmbryoStage]

    defines two dimensions.

    The result of this call will be a hash. The keys to the hash will
    be the first entries (the roots) in each of the dimension paths.

    
    For each key, the value will be the completely specified array of
    path objects.
    Thus, for the above example, we'll have the following result:

    { Gene =>  ('Gene','ProbeGene','Probe','ImageProbe'),
      EmbryoStage => ('EmbryoStage','ImageEmbryoStage') }
  
    The return value is the reference to the hash.
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
	#convert to array
	my @paths = split (/,/,$1);
	#now, each  entry in  @paths is something like
	#@Probe:@ProbeGene:@Probe:@ImageProbe,
	# etc.
	foreach my $path (@paths) {
	    my @entries = split (/:/, $path);
	    # first item becomes a key
	    my $dimensionKey = $entries[0];
	    $pathSet{$dimensionKey} = \@entries;
	}
    }
    # return ref to array of refs.
    return \%pathSet;
}

=head2 getChoices
    $self->getChoices(\%tmpl_data,$types);

    getChoices populates the Columns and Rows pull-down menus in the
    template. This is done by iterating down the root types for each
    of the dimensions, stripping off the leading '@', and putting them
    into the template variable.

    If something matching the "Rows" or "Columns" parameter is found,
        set that value to be selected
        
=cut
sub getChoices {
    my $self=shift;
    my $tmpl_data = shift;
    my $types = shift;

    my @rows;

    my @columns;
    
    my $rows= $self->{rows};
    my $cols = $self->{columns};

    foreach my $type (keys %$types) {
	# clear off header if it's an st
	my %row;
	my %col;
	$row{rowName} = $type;
	if ($type eq $rows) {
	    $row{selectedRow} = 1;
	}
	push(@rows,\%row);
	$col{columnName} = $type;
	if ($type eq $cols) {
	    $col{selectedCol} = 1;
	}
	push (@columns,\%col);
    }
    $tmpl_data->{Columns}=\@columns;
    $tmpl_data->{Rows}=\@rows;
}

=head2 prepareCategoryGroups 
    $cgs = $self->getCategoryGroups($container);

    prepare and populate the category groups parameter and pull-down 
=cut

sub getCategoryGroups {

    my $self=shift;
    my $container = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $q = $container->CGI();

    # do the list of categories
    my $cgParam = $q->param('CategoryGroup');
    my %cgHash;

    # set up hash to describe rendering. 
    $cgHash{type} = '@CategoryGroup';
    my $cg;
    if ($cgParam) {
	if ($cgParam =~ /\D+/) { # not numbers
	    $cg = $factory->findObject('@CategoryGroup',Name=>$cgParam);
	    if ($cg) {
		$self->{CategoryGroup} = $cg;
		$cgHash{default_value} = $cg->id();
	    }
	}
	else {
	    # $cgParam is now the id of a cg.
	    my  $cg =
		$factory->loadObject('@CategoryGroup',$cgParam);
	    if ($cg) {
		$self->{CategoryGroup} = $cg;
		$cgHash{default_value} = $cgParam;
	    }
	}
    }

    my @catGroupList = $factory->findObjects('@CategoryGroup');
    my $renderer=  $container->Renderer;
    my $cats =
	$renderer->renderArray(\@catGroupList,'list_of_options', 
				     \%cgHash);
    return $cats;
}

=head2 renderDims

    my $hasData = $self-renderDims($container,\%tmpl_data,$types);
    
    The main rendering code. Parameters are the container in which
    this is being executed, the template being populated, and the
    types hash as returned from getTypes.

    Return value is true if data is found, else false

=cut

sub renderDims {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($container,$tmpl_data,$types) = @_;
    my $q = $container->CGI();
    my $rows = $self->{rows};
    my $columns = $self->{columns};
    my $hasData = 0;

    
    my $rowPath = $types->{$rows};
    $self->{rowEntries} = $self->getObjects($container,$rows,$rowPath);

    # same for columns.
    my $colPath = $types->{$columns};
    $self->{colEntries} = $self->getObjects($container,$columns,$colPath);

    # populate the cells with data in a hash.
    # activeRows returns a list of rows that have data,
    # active cols indicates columns
    
    my ($cells,$activeRows,$activeCols) =
	$self->populateCells($types);


    # if any data, populate the template
    if ($cells) {
	$hasData=1;

	# # of columns is the number of active columns + the 
	# number of columns needed for row paths..
	my $rowEntrySize = $self->getHeaderSize($self->{rowEntries});
	$tmpl_data->{rowHeaderCount} = $rowEntrySize;

	my $cHeaders = 
	    $self->populateColumnHeaders($container,$activeCols,
					 $rowEntrySize,$colPath);
	$tmpl_data->{columnHeaders} =$cHeaders;

	my $body =
	    $self->populateBody($container,$cells,$activeRows,
				$activeCols,$rowPath);
	$tmpl_data->{cells}=$body;
    }
    return $hasData;
}

=head2 

    $self->{rowEntries} =
          $self->getObjects($container,$rows,$rowPath);

    getObjects gets the objects of interest for a given hierarchy.
    Given a container, a  type (Probe,EbmbryoStage, etc.), and a path
    that maps  that type to something that eventually maps to images,
    find the objects that     are of interest.

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
    the way to the atual root object, whih is the last item in the array.

=cut

sub getObjects {
    my $self=shift;
    my $container = shift;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $q = $container->CGI();

    my $type =shift; # type is Probe,EmbryoStage, etc.
    my $paths = shift;

    # load the type
    my $typeST =
	$factory->findObject('OME::SemanticType',{name=>$type});
    # get root vaalue
    my $root = $q->param($type);

    my $objsRef;
    if ($root) {
	# get objects that match the root
	# do single object - or some set of objects
	$objsRef = $self->getRoots($typeST,$root);
    }
    else {
	# get all of the given type.
	my @objs = $factory->findObjects($typeST, {__order => 'id'});
	$objsRef = \@objs;
    }
    
    # now, objsRef is a reference to an aaray containing the list of
    # top-level items that I want to work with

    # get a tree of objects

    my $tree = $self->getTreeFromRootList($objsRef,@$paths);
    # convert that tree into an array,
    my $flatTree = $self->flattenTree($tree);

    return $flatTree;
}




=head2 getRoots 

    my $arrayRef = $self->getRoots($type,$root);

    Get the root objects corresponding to a comma-separated list of
    objects from the CGI parameter. load the object either by Name or
    by Id.
=cut

sub getRoots {
    my $self = shift;
    my ($type,$rootList) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my @objs;
    my @roots = split(/,/,$rootList);
    my $obj;
    foreach my $root (@roots) {
	undef $obj;
	if ($root =~ /^\d+$/) {
	    # load by id
	    $obj = $factory->loadObject($type,$root);
	}
	else {
	    $obj = $factory->findObject($type,Name=>$root);   
	}
	if ($obj) {
	    push(@objs,$obj);
	}
    }
    return \@objs;
}

=head2 getTreeFromRootList

    my $tree = $self->getTreeFromRootList($objsRef,@$paths);

    Given  a list of root objects and a list of object types, populate
    the tree. The result is a reference to a hash of hashes that
    contains the values in the tree.

    Thus, if the path is Gene:ProbeGene:Probe:ImageProbe, the
    resulting hash will be keyed with the names and ids of all of the genes
    passed in as roots - @$objs.  For each gene, the hash will contain
    an entry for each Probe. The entry for each probe will be a hash 
    keyed by the name and id of the probe, with the actual probe
    object as a  value.

    For all of these hashes, the key will be a hybrid string resulting
    from the concatentation of the object name, two underscores "__"
    and the object id.  These underscores are necessary to allow for
    sorted by atributed_ids: without the id in the key, we would only
    be able to sort by name. However, for some STs  that have values
    with inherent order (such as EmbryoStage: 1-Cell, 2-Cell, 4-Cell,
    etc), this approach is not acceptable. So, we sort by attribute id
    instead, and strip these keys off later.

    Note that mapping classes are not included in the result, as they
    are only used to find the next level of descendant in the
    tree. Furthermore, we stop before we get to the last entry -
    (ImageProbe), as the combination of the entries at the second to
    last level (Probe) and the name of the last level (ImageProbe) is
    sufficient to get images for a given leaf object. To see why this
    is the case, note that the leaves will be Probe instances. So, to
    find the Images for a probe, we can look for images where
    ImageProbeList.Probe = our probe instance.

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


=head2 getTree

    my $tree = $self->getTre($obj, $path)
    The workhorse that does the job of recursively building the tree
    starting from a given object and walking down the types given in path.
    for a given object.
=cut

sub getTree {
    my $self= shift;
    # note that we pass the type path in as an array, not a ref. to an
    # array. This guarantees that the array will be copied, so we
    # don't need to do an explicit copy with each recursion

    my ($obj,@paths) = @_;

    # now, $obj is a gene, $paths is
    # [ProbeGene,Probe,ImageProbe]
    # or, map followed by class followed by map.

    #termination condition - stop when we've hit the last non-map
    #class (in this case, probe),  and   simply return the object.

    return $obj if (scalar(@paths) < 2);

    # strategy. find all of the maps 
    # load the mapping type (ie, ProbeGene)
    my $map = shift @paths;

    # next type is probe.
    my $next = shift @paths;

    # build the accessor.
    my $accessor = "${map}List"; #

    # find the maps
    my @maps = $obj->$accessor;  # ie., ProbeGeneList.
    my %tree;
    foreach my $map (@maps) { # for each map
	my $child = $map->$next; # follow the pointer to the next
				# object (ie., ProbeGeneList->Probe)
	my $name = $child->Name(); # get the name
	my $id = $child->id(); # and id 
	my $key = $name . "__" . $id; 
	# recurse.
	$tree{$key} = $self->getTree($child,@paths); 
    }
    return \%tree;
}


=head2 flattenTree

    my $arrayRef = $self->flattenTree($tree);

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

    #termination - must return an array containing one element,
    # which is an array of one element - the item in question
    # containing the last item
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
	# recurse - flatten the values
	my $valRows = $self->flattenTree($val);

	# for each val in valrows, 
	# add key to the front
	foreach my $valRow (@$valRows) {
	    unshift @$valRow,$key;
	    push @rows,$valRow;
	}
    }
    # sort the rows by id of first item.
    my @sortedRows = sort sortByIdKey @rows;

    # strip the ids off of the items.
    for (my $i = 0; $i < scalar(@sortedRows); $i++ ) {
	my $ent = $sortedRows[$i];
	for (my $j = 0; $j < scalar(@$ent)-1; $j++) {
	    my $val = $ent->[$j];
	    if ($val =~ m/([^_]*)__\d+/) {
		$ent->[$j]=$1;
	    }
	}
    }

    return \@sortedRows;
}

=head3 sortByIDKey
    sortByIDKey ($a,$b) 
    
    sorts the items by order of the ids contained in their
    "$name__$id" first element.


=cut
sub sortByIdKey {
    $a->[0]=~ /[^_]*__(\d+)/;
    my $aID = $1;
    $b->[0]=~ /[^_]*__(\d+)/;
    my $bID = $1;
    return $aID <=> $bID;
}

    


=head2 populateCells

    my ($cells,$activeRows,$activeCols) = $self->populateCells($types);

    Get the objects to fill the matrix. Return a nested hash:
    first-level keyed by row id, second by column, with value being
    the list of images in the cell defined by that row,column pair.

    $activeRows and $activeColumns are hashes indicating which
    rows/columns have data. Only those rows/columns with data will be
    drawn.

    

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

	#thus, for example $rowLeaf is a probe
	my $rName = $rowLeaf->Name;

	foreach my $col (@$colEntries) {
	    my $colLeaf = $col->[scalar(@$col)-1];
	    # and colLeaf is an embryoStage.
	    my $cName = $colLeaf->Name;
	    # for each row and column, get images.
	    # the filter clauses end up looking like 
	    # ImageProbeList.Probe = <probeName> (for row) and 
	    # ImageEmbryoStageList.EmbryoStage = <embryo stage name>
	    my @images = $factory->findObjects('OME::Image',
					       { $rowAccessor => $rowLeaf,
						 $columnAccessor =>
						     $colLeaf,
						     __distinct
						     =>'id'});
	    my $imagesRef = \@images;
	    if ($self->{Category} && $self->{CategoryGroup}) {
		$imagesRef = $self->filterByCategory($imagesRef);
	    }
	    # if I find any, store them in double-hashed - keyed off
	    # of row name and column name.
	    # indicate when a row and column is active.
	    if (@images && scalar(@$imagesRef) > 0) {
		$cells->{$rName}->{$cName}  = $imagesRef;
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

=head2 getAccessorName

    my $accessor = $self->getAccessorName($fieldName,$types);

    Build up the accessor to $fieldName (ie., Probe). Given an image,
    we would go to ${someType}List to get the mapping 
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
    

    # get the types out of the types hash
    my $path = $types->{$fieldName};
    my $count = scalar(@$path);

    # get the last two items.
    my $listAccessor = $path->[$count-1];
    my $rootItem = $path->[$count-2];

    #strip off loading ampersands.


    my $accessor = "${listAccessor}List.$rootItem";
    return $accessor;
}


=head2 filterByCategory
    my $imagesRef= $self->filterByCategory($imagesRef);

    filter a list of images, returning only those that have group and 
    category matching $self->{CategoryGroup} and $self->{Category}
=cut

sub filterByCategory {
    my ($self,$images) = @_;
    my $cg = $self->{CategoryGroup};
    my $cat = $self->{Category};
    my @filtered;

    foreach my $image (@$images) {
	my $classification = 
	    OME::Tasks::CategoryManager->getImageClassification($image,$cg);
	if ($classification) {
	    # potential match
	    if (ref($classification) eq 'ARRAY') {
		foreach my $class (@$classification) {
		    if ($class->Category->Name eq $cat) {
			push (@filtered,$image);
			last;
		    }
		}
	    }
	    else {
		if ($classification->Category->Name eq $cat) {
			push (@filtered,$image);
		}
	    }
	}
    }
    return \@filtered;
}

=head2 getActiveList
    

    my $arrayRef = $self->getActiveList($items,\%active)

    $items is the list of all items (either for all rows or all
    columns. We wish to filter this list to find only those things
    that are active - ie., those cells that have data.

    However, the cells are keyed off of the names of the last item in
    the entry list - that which is "closest" to the data. So, we look
    at the name of the last item in each entry in the items list. If
    that name is found in the active hash, we save it. These lets us
    keep only those items from $items that are active, and to keep
    them in the order in which they were found. The _entire_ active
    item is returned in the resulting array.

=cut
sub getActiveList {
    my $self=shift;
    my ($items,$active) = @_;
    my @results;
    foreach my $entry (@$items) {
	my $item = $entry->[scalar(@$entry)-1];
	my $name = $item->Name;
	# store the whole entry, so we can use it to recontruct the
	# header
	push (@results,$entry) if ($active->{$name});
    }
    return \@results;
}
 

=head2 populateColumnHeaders
    my $colHeaders =
       $self->populateColumnHeaders($container,$activeCols,
                $rowEntrySize,$colPath);

    Put headers in the columns of the table. $rowSize is the number of
    columns that will be needed for header information for row
    entries. $colPath is the path of types to the columns.

=cut
sub populateColumnHeaders {
    my $self=shift;
    my ($container,$columns,$rowSize,$colPath) = @_;

    # colPath is the returned value for types, which will have the
    # form ST, map, ST, map, etc. let's start by stripping out
    # every other item.
    my $colTypes = $self->filterOutMaps($colPath);
    
    
    # create empty headers as need be.
    my  $emptyHeaders = $self->populateEmptyColumnHeaders($rowSize);
    my @headers;
    my $firstCol = $columns->[0];
    my $rowCount = scalar(@$firstCol)-1; # of rows in column headers
    # is one less than the number of element in the first column.
    # this is also the # of field in the column..

    my @prevColumns;
    # for each row in columns
    for (my $i =0; $i < $rowCount; $i++)  {
	my %header;
	
	# get appropiate # of empty heders.
	$header{emptyColumnHeaders} = $emptyHeaders;
	my @columns;

	# for each column in that row.
	for (my $j = 0; $j < scalar(@$columns); $j++) {

	    my $same =1;
	    # look @ all previous entries in this column to see if
	    # they match  whatever was in the most recent column
	    for (my $k = 0; $k <= $i; $k++) {
		if (!$prevColumns[$k] || 
		    $columns->[$j]->[$k] ne $prevColumns[$k]) { 
		    # if any difference, bail out
		    $same  = 0;
		    last;
		}
	    }


	    # if it's not the same,
	    if (!$same) {
		# get the val.
		my  $val = $columns->[$j]->[$i];

		my %column;
		# find out how many times the column is repeating.
		my $colSpan =
		    $self->getRepeatCount($columns,$j,$i);
		$column{columnNameSpan} = $colSpan;
		
		# get the link content for this value
		$column{columnNameEntry} =  
		    $self->getTextFor($container,$val,$colTypes->[$i]);
	    

		push(@columns,\%column);
		# update the previous entry.
		$prevColumns[$i] = $val;
	    }
	}
	# do each of the headers.

	$header{columnNameEntries} = \@columns;
	push(@headers,\%header);
    }
    return \@headers;
}

=head2 populateEmptycolumnHeaders
    
    my $emptyColumns = $self->populateEmptyColumnHeaders($size);

   create  the requisite number of empty column headings.
=cut 


sub populateEmptyColumnHeaders {
    my $self=shift;
    my $size = shift;
    
    my @headers;
    for (my $i=0; $i < $size; $i++) {
	my %header;
	$header{emptyColumnHeader}="";
	push(@headers,\%header);
    }
    return \@headers;
}


=head2 getHeaderSize

    my $headerSize = $self->getHeaderSize($rowEntries)

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

=head2 populateBody

    my $body =	 $self->populateBody($container,$cells,$activeRows,
				$activeCols,$rowPath);
    Populate the body, one row at a time.

    Simimlar to populateColumnHeaders, except here we call
    populateRow, which eventually renders all of the images.
    
=cut

sub populateBody {
    my $self= shift;

    my ($container,$cells,$activeRows,$activeCols,$rowPath) = @_;

    # rowPath is the returned value for types, which will have the
    # form ST, map, ST, map, etc. let's start by stripping out
    # every other item.
    my $rowTypes = $self->filterOutMaps($rowPath);

    my @cellRows;

    my  @prev; # what's in the previously printed row.
    
    for (my $rowIndex= $0 ; $rowIndex <scalar(@$activeRows);
	 $rowIndex++) {
	my $row = $activeRows->[$rowIndex];
	my %rowContents;
	my @entries;
	
	my  $same=1; # are we in same row as previous?

	# $i is the index - which field in the row.
	for (my $i = 0; $i < scalar(@$row)-1; $i++) {
	    my $val = $row->[$i];
	    if ($val ne $prev[$i] || $same == 0) {
		my %entry;
		my $rowSpan = 
		    $self->getRepeatCount($activeRows,$rowIndex,$i);
		$entry{rowNameEntry} = $self->getTextFor($container,
							 $val,
							 $rowTypes->[$i]);
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
	$rowContents{rowCells} = 
	    $self->populateRow($container,$cells,$row,$activeCols);
	push (@cellRows,\%rowContents);
    }
    return \@cellRows;

}

=head2 filterOutMaps

    my $filteredPath = $self->filterOutMaps($path);

    Given a path consisting of the names of types, alternating between
    object types and map types, return an array containing only the
    object types.

=cut
sub filterOutMaps {
    my ($self,$path)  = @_;
    my @filtered;
    for (my $i =0,my $j=0; $i < scalar(@$path) ; $i+=2,$j++) {
	$filtered[$j]=$path->[$i];
    }
    return \@filtered;
}
   
=head2 
    my $cnt =$self->getRepeatCount($entries,$start,$field)

    How many times do we see repeats of the values in
    $entries->[$start], where fields 0..$field are all equal to 
    those in $entries->[$start]? Used to determine when a column/row
    header should span multiple columns/rows.
    

=cut
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
    
    
=head2 getTextFor

    my $text = $self->getTextFor($container,$name,$type);
    given a name of an item and the type of an item,
    find the string to put in a cell.
    3 posssibilities: 
    1) there is an external link. put an href to that link,
      with name as the visible text.
    2) there is an object detail url. return an appropriate href.
    3) otherwise, just put the name of the object.

=cut
sub getTextFor {
    my ($self,$container,$name,$type)  = @_;
    my $session = $self->Session;
    my $factory = $session->Factory;
    my $q = $container->CGI;

    my $text = $name; #default

    my $typeName = "@".$type;

    # find the object
    my $obj = $factory->findObject($typeName,Name=>$name);
    if ($obj) {
	my $mapType = $type."ExternalLinkList";
	
	my $map;
	# get the list of links, & find the first element in this list.
	eval{ my $maps = $obj->$mapType(); $map = $maps->next() };
	
	# if there's an error or no map give the object detail url or just
	# the name (if no details)
	if ($@ || !$map) {
	    my $detail = $self->getObjDetailURL($obj);
	    if ($detail) {
		$text = $q->a({href=>$detail},$name);
	    }
	}
	elsif ($map) { # but, if the link does exist, create it.
	    
	    my $link = $map->ExternalLink();
	    my $url = $link->URL();
	    $text = $q->a({href=>$url},$name);
	}
    }
    return $text;
}

=head2 populateRow

    my $rowCells = $self->populateRow($container,$cells,$row,$activeCols);
    

    put sets of images from cells into the output table.
=cut
sub populateRow {
    my $self=shift;
    my ($container,$cells,$row,$activeCols) = @_;
    my $cg= $self->{CategoryGroup};
	

    my $rowLeaf = $row->[scalar(@$row)-1];
    my $rowName = $rowLeaf->Name;
    my @cells;
    foreach my $col (@$activeCols) {
	# $col s the entire path array for each column
	# find the last entry in it.
	my $colLeaf = $col->[scalar(@$col)-1];
	my $colName = $colLeaf->Name;
	# get cells
	my $images = $cells->{$rowName}->{$colName};
	#render them.
	my $cell = $self->getRendering($container,$images,$cg);
	push(@cells,$cell);
    }
    return \@cells;
}


=head2 getRendering

    my $rendering = $self->getRendering($container,$images,$cg);

    Render the images according to the category group
=cut

sub getRendering {
    my ($self,$container,$images,$cg) = @_;
    my %cell;
    if ($images) {
	# sort them by category group first.
	my $sortedImages = $self->sortImagesByCG($images,$cg);
	my $renderer=$container->Renderer();
	my $rendering =
	    $renderer->renderArray($sortedImages,
				   'color_code_ref_mass_by_cg'
				   ,{type=>'OME::Image',
				     Rows => $self->{rows},
				     Columns=> $self->{columns},
				     Template=>$self->{Template},
				     CategoryGroup =>
					 $cg});
	$cell{cell} = $rendering;
    }
    return \%cell;
}

=head2

    my $sortedImageArrayRef = $self->sortImagesByCG($images,$cg);
   

    Sort the images by cateogory  in a given group.
=cut

sub sortImagesByCG {
    my ($self,$images,$cg) = @_;
    
    my @cgArray;
    foreach my $image (@$images) {
        # for each image, get the cg.
	my $classification = 
	    OME::Tasks::CategoryManager->getImageClassification($image,$cg);
	my $catName="";
	if ($classification) {
	    $catName = $classification->Category->Name;
	}
       # populate a new array. each element in this array is a pair
       # containing [$cgid, $image];

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




















