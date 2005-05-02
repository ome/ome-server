
# OME/Remote/Facades/ChainRetrievalFacade.pm

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


package OME::Remote::Facades::ChainRetrievalFacade;
use OME;
use OME::Remote::Facades::XMLUtils;
our $VERSION = $OME::VERSION;

use OME::Session;



=head1 NAME

OME::Remote::Facades::ChainRetrievalFacade: a facade for 
    special-purpose retrieval of chains.

=head1 DESCRIPTION

    Generalized retrieval of DTOs from the OME database via DBObject and
    Factory can be inefficient. For cases where known queries will be
    commonly repeated, construction and managemetn of custom queries
    that will be hand-converted into appropriate DTOs can provide
    significant performance improvements.

    This manager provides just such a custom implementation for
    retrieving all of the chains in an OME database.

=cut

# several queries that are needed to assemble the chain data.
# the general approach here is to build several indvidual queries,
# each of which involves either one chain or multiple chains  
# that are joined via one-one relationships. Any joins involving
# has-many or many-many relationships should be handled by multiple
# queries, as seen below.

# Desired fields for a chain, along with the owner.
use constant CHAIN_QUERY => <<CHAIN_SQL;
Select a.analysis_chain_id,a.name,a.description,a.locked,o.FirstName, 
    o.LastName from analysis_chains a, experimenters o where 
    a.owner=o.attribute_id;
CHAIN_SQL

# Fields for chain ndoes. Note that the containing chain id must be
# retrieved. As will be seen below, the chain id will be cleared out
# when no longer needed. 
    use constant NODE_QUERY =>   <<NODE_SQL;
select n.analysis_chain_node_id,n.analysis_chain_id, m.module_id, m.name
    from analysis_chain_nodes n, modules m where n.module_id=m.module_id;
NODE_SQL

# for a link, get the id, chain id, from output, to input, and to and
#from nodes.
use constant LINK_QUERY => <<LINK_SQL;
select analysis_chain_link_id,analysis_chain_id,
from_output,to_input, from_node,to_node from 
analysis_chain_links;
LINK_SQL

# formal inputs get the associated semantic type as well
    use constant FINS_QUERY => <<FINS_SQL;
select fi.formal_input_id,fi.name,  stin.semantic_type_id, 
    stin.name from formal_inputs fi, semantic_types stin
    where fi.semantic_type_id=stin.semantic_type_id;
FINS_SQL

# as do formal outputs get the associated semantic type as well
# note that as some outputs may be untyped, we must do an outer join,
# or else we won't see any outputs without semantic types
    use constant FOUTS_QUERY => <<FOUTS_SQL;
select fo.formal_output_id,fo.name,  stout.semantic_type_id, 
    stout.name from formal_outputs fo LEFT OUTER JOIN semantic_types stout
    on fo.semantic_type_id=stout.semantic_type_id;
FOUTS_SQL

# fields for the various objects and sub-objects. Each of these lists specifies
# exactly those columns, in order, that will be present in the above queries. 
# These arrays will be used to provide hash keys for these fields in the
# resulting hash of hashes (which will eventually be encoded as XMLRPC and
# returned to the caller. Note that regardless of their names in the database,
#id fields are simply named "id". Note also that nodes and links have
# analysis_chain_ids, which will be cleared once those objects are placed in the # appropriate chain.
    my @chain_fields = qw[id name description locked];
my @owner_fields = qw[FirstName LastName ];
my @node_fields = qw[id analysis_chain_id];
my @module_fields = qw[id name];
my @link_fields = qw[id  analysis_chain_id from_output
					to_input from_node to_node];
my @input_fields = qw[id name];
my @output_fields = qw[id name];
my @st_fields = qw[id name];


sub retrieveChains {

    # start by grabbing the appropriate entry points to the OME Database
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $dbh = $factory->obtainDBH();

    # do chains with hash by Id. Although we want a list, we hash by id to 
    # provide easy access to chains by id. Eventually, we'll return the values
    # of this hash.
    my $chains= {};
    
    #the current chain and owner
    my $chain;
    my $owner;
    my $SQL=CHAIN_QUERY;

    # execute chain query.
    my $sth = $dbh->prepare($SQL);
    $sth->execute();

    # run across the rows.
    while (my @row = $sth->fetchrow_array) {
	my $i=0;
	# look at columns that hold the chain and populate them
	$chain = fill_fields(\$i,\@row,\@chain_fields);
	#same for  owner
	$owner = fill_fields(\$i,\@row,\@owner_fields);
	# put the owner into the chain
	$chain->{'owner'} = $owner;
	# put the chain into the hash.
	$chains->{$chain->{'id'}} = $chain;
    }

    # do nodes 
    my $node;
    my $module;
    # nodes without modules
    # Each node  will occur _three+ times in the output DTO: 
    # once as an entry in the node list, once as  a "from node" in a link,
    # and once as a "to node".
    # In the list of nodes, it will contain its module, but it's just an id in 
    # the links. Thus, $node will have the module, while $baseNode won't, and 
    # $baseNode gets stuck in links.
    # This may seem inefficient (having a node appear 3 times!?), but it's 
    # actually ok, as 2 of the three instances are just ID ints.
    my $baseNode;
    my $baseNodes;
    

    # run the node query
    $SQL=NODE_QUERY;
    $sth = $dbh->prepare($SQL);
    $sth->execute();

    while (my @row = $sth->fetchrow_array) {
	my $i=0;
	# populate the node and base node.
	$node= fill_fields(\$i,\@row,\@node_fields);
	undef $baseNode;
	$baseNode->{'id'} = $node->{'id'};
	# populate the module
	$module = fill_fields(\$i,\@row,\@module_fields);
	# stick the module into the node (but not into the baseNode)
	$node->{'module'} = $module;
	
	# cache the basenode.
	my $baseXml = getBaseNodeXml($baseNode);
	$baseNodes->{$baseNode->{'id'}}=$baseXml;
	
	# put nodes into chains. Note that here we use the node _with_
	# the module.
	# get the chain id
	my $chain_id = $node->{'analysis_chain_id'};
	my $nodexml = getNodeXml($node,$module);
	# find the chain in the hash
	$chain = $chains->{$chain_id};
	
	# add node to the chain's list of nodes.
	push @{$chain->{'nodes'}},$nodexml;
	# don 't need the node to keep the chain's id anymore.
	delete $node->{'analysis_chain_id'};
    }

    # do formal inputs
    my $fin;
    my $fins;
    my $st;
    $SQL = FINS_QUERY;
    $sth = $dbh->prepare($SQL);
    $sth->execute();



    
    while (my @row = $sth->fetchrow_array) {
	my $i=0;
	# get formal input and st
	$fin= fill_fields(\$i,\@row,\@input_fields);
	$st = fill_fields(\$i,\@row,\@st_fields);
	# cache input
	my $finxml =
	    OME::Remote::Facades::XMLUtils::getParameterXml($fin,$st); 
	$fins->{$fin->{'id'}} = $finxml;
    }

    # do formal outputs
    my $fout;
    my $fouts;
    $SQL = FOUTS_QUERY;
    $sth = $dbh->prepare($SQL);
    $sth->execute();

    while (my @row = $sth->fetchrow_array) {
	my $i=0;
	$fout= fill_fields(\$i,\@row,\@output_fields);
	$st = fill_fields(\$i,\@row,\@st_fields);
	my $foutxml = 
	    OME::Remote::Facades::XMLUtils::getParameterXml($fout,$st);
	$fouts->{$fout->{'id'}} = $foutxml;
    }


    # do links
    my $link;
    $SQL = LINK_QUERY;

    $sth = $dbh->prepare($SQL);
    $sth->execute();

    #processing liknks is somewhat tricky, as we must grab stuff from
    # $baseNodes, $fins, and $fouts for each link
    while (my @row = $sth->fetchrow_array) {
	my $i=0;

	# populate the link
	$link = fill_fields(\$i,\@row,\@link_fields);



	# fixup nodes and links at this point, I have a from_node id
	# and a to_node id in link. find the actual nodes and replace 
	# $link->{'from_node'} with the node as found in the cache
	
	# from
	my $from_id = $link->{'from_node'};
	my $from_node = $baseNodes->{$from_id};
	$link->{'from_node'} = $from_node;
	
	#to
	my $to_id = $link->{'to_node'};
	my $to_node = $baseNodes->{$to_id};
	$link->{'to_node'} = $to_node;
	
	# now, similar for input and output
	$to_id = $link->{'to_input'};
	my $to_input = $fins->{$to_id};
	$link->{'to_input'} = $to_input;
	
	$from_id = $link->{'from_output'};
	my $from_output = $fouts->{$from_id};
	$link->{'from_output'} = $from_output;
	
     	# put links into chains by grabbing chain id, finding chain,
	# adding link to list, and finally clearing out chain id.
	my $chain_id = $link->{'analysis_chain_id'};
	$chain = $chains->{$chain_id};
	my $linkXml = getLinkXml($link);
	push @{$chain->{'links'}}, $linkXml;
    }
    
    my $res = getChainsXml(values %$chains);
    return (bless (\$res,'OME::Remote::Response::XMLRPC'));
}

# to fill the fields of a given object from a row,
# take the row, along with a starting point in the row,
# and the list of fields to fill. March down the fieldlist and the
# row, using entries from the fieldlist as keys and the row as
# values. Advance the index pointer to point to the next available
# column in the table. 

sub fill_fields {

    my ($startindex,$row,$fieldlist)=@_;

    my $i = $$startindex;
    my @fields = @$fieldlist;
    my $res;
    for (my $j=0; $j <=$#fields; $j++) {
    	my $val = $row->[$i++];
    	if (defined $val) {
	    $res->{$fields[$j]} = $val;
	}
    }
    $$startindex= $i;
    return $res;
}


#full node in node list.
#   <struct>
#      <member>
#        <name>module</name>
#         <value>
#           <struct>
#           <member>		
#             <name>id</name>
#                 <value>
#					<int>12</int>
#                  </value>
#              </member>
#               <member>
#                <name>name</name>
#                <value> 
#                <string>Dataset signature test</string>
#                 </value>
#               </member>
#            </struct>
#         </value>
#     </member>
#      <member>
#         <name>id</name>
#         <value><int>8</int>
#         </value>
#       </member>
#     </struct>
sub getNodeXml {
    my($node,$module) =@_;
    
    # wrapper  - start struct and start module
    my $xml="<struct><member><name>module</name><value>";
    
    #module id
    $xml = $xml . "<struct><member><name>id</name><value><int>" . 
	$module->{'id'};
    $xml = $xml . "</int></value></member>";
    
    #module name
    $xml = $xml . "<member><name>name</name><value><string>". 
	$module->{'name'};
    $xml = $xml . "</string></value></member>";
    
    # end module
    $xml = $xml . "</struct></value></member>";
    
    # node id
    $xml = $xml . "<member><name>id</name><value><int>" . $node->{'id'};
    $xml = $xml . "</int></value></member></struct>";
    return $xml;
}

# base node - for use as from_node/to_node in link
# <struct>
#     <member>
#      <name>id</name>
#      <value><int>274</int>                                                         
#         </value>
#      </member>
#       </struct>
sub getBaseNodeXml {

    my($node) = @_;
    my $xml = "<struct><member><name>id</name><value>";
    $xml = $xml . "<int>" . $node->{'id'} . "</int></value></member></struct>";
    return $xml;
}

# link
# <struct>
#   <member>
#      <name>id</name>
#       <value>
#        <int>14</int>
#        </value>
#    </member>
#	  <member>
#      <name>from_output</name>
#      <value>
#   ...from output
#       </value>
#      </member>
#      <member>
#        <name>from_node</name>
#         <value>
#     .. .from node                                                            
#        </value>
#      </member>
#       <member>
#       <name>to_node</name>
#         <value>
#       ... to_node..
#         </value>
#       </member>
#       <member>
#          <name>to_input</name>
#         <value>
#    .. to_input ..
#         </value>
#     </member>
#     </struct>

sub getLinkXml {
    my $link = shift;

    # id
    my $xml = "<struct><member><name>id</name><value><int> " . $link->{'id'};
    $xml = $xml . "</int></value></member>";
    
    # from output
    $xml = $xml . "<member><name>from_output</name><value> " . 
	$link->{'from_output'} . "</value></member>";
    
    # from node 
    $ xml = $xml  . "<member><name>from_node</name><value> " . 
	$link->{'from_node'} . "</value></member>";
    
    # to node 
    $ xml = $xml  . "<member><name>to_node</name><value> " . 
	$link->{'to_node'} . "</value></member>";
    
    # to input
    $ xml = $xml  . "<member><name>to_input</name><value> " . 
	$link->{'to_input'} . "</value></member>";
    
    # end 
    $xml  = $xml . "</struct>";
    return $xml;
}


# chains

sub getChainsXml{

    my $res; 
    $res = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
    $res = $res. "<methodResponse><params><param><value><array><data>";
    #print header 
    
    
    #iterate
    foreach my $chain (@_) {
	$ res = $res . "<value>" . getChainXml($chain) . "</value>";
    }
    
    #close up
    $res  = $ res ."</data></array></value></param></params></methodResponse>";
    
    return $res;
} 

# a chain
# <struct>
#   <member>
#    <name>id</name>
#     <value>
#      <int>3</int>
#      </value>
#      </member>
#     <member>
#      <name>name</name>
#       <value>
#        <string>Dataset test chain</string>
#      </value>
#      </member>
#	 <member>
#		<name>description</name>
#	    <value><string>this is a description</string></value>
#	 </member>
#	 <member>
#		<name>Owner</name>
#		<value>
#			<struct>
#	  		  <member>
#  			 <name>FirstName</name>
#	  		  <value><string>first</string></value>
#		     </member>
#	  		  <member>
#  			 <name>LastName</name>
#	  		  <value><string>last</string></value>
#		     </member>
#            </struct>
#        </value>
#     </member>
#    <!-- something here for owner eventually ->
#    <member>
#     <name>locked</name>
#      <value>
#      <int>0</int> </value>
#      </member>
#	 <member>
#	 <name>nodes</name>
#    <value>
#      <array>
#		<data>
# .. nodefor each
#		<value>
#     node
#		</value>
#		</data>
#      </array>
#	  </value>
#	 </member>	 
#   <member>
#   <name>links</name>
#   <value><array><data>
# ..for each link
#		<value>
#			..link
#		</value>
#	</data>
#	</array>
#	</member>
#	</struct>



sub getChainXml { 
    my $chain = shift;
    
    #preamble
    my $xml = "<struct>";
    
    # id
    $ xml = $xml . "<member><name>id</name><value><int>" . $chain->{'id'} . 
	"</int></value></member>";
    
    # name
    $ xml = $xml . "<member><name>name</name><value><string>" 
	. $chain->{'name'} . "</string></value></member>";
    
    #description
    my $description = $chain->{'description'};
    $description = $OME::Remote::SerializerXMLRPC::NULL_STRING
	unless (defined $chain->{'description'});
    
    $ xml = $xml . "<member><name>description</name><value><string>" .
	$description . "</string></value></member>";
    #locked
    $ xml = $xml . "<member><name>locked</name><value><int>" .
	$chain->{'locked'} . "</int></value></member>";
    
    # owner
    $xml = $xml . "<member><name>owner</name><value><struct>";
    $xml = $xml . "<member><name>FirstName</name>";
    $xml = $xml . "<value><string>" . $chain->{'owner'}->{'FirstName'} . 
	"</string></value></member>";

    $xml = $xml . "<member><name>LastName</name>";
    $xml = $xml . "<value><string>" . $chain->{'owner'}->{'LastName'}  .
	"</string></value> ";
    $xml = $xml . "</member></struct></value></member>";

    
    #nodes
    $xml = $xml . "<member><name>nodes</name><value><array><data>";
    foreach my $node( @{$chain->{'nodes'}}) {
	$xml = $xml . "<value>$node</value>";
    }
    $xml = $xml . "</data></array></value></member>";

    # links
    $xml = $xml . "<member><name>links</name><value>";

    my $lnkCount = $#{$chain->{'links'}} +1;
    if ($lnkCount > 0) {
	#links		
	$xml = $xml . "<array><data>";
	foreach my $link ( @{$chain->{'links'}}) {
	    $xml = $xml . "<value>$link</value>";
	}
	$xml = $xml . "</data></array>";
    } else { # no links
	$xml = $xml . "<string>$OME::Remote::SerializerXMLRPC::NULL_STRING";
	$xml = $xml . "</string>";
	   }
    $xml = $xml . "</value></member>";
    
    # end 
    $xml = $xml . "</struct>";
    return $xml;
}	
1;

__END__
=head1 AUTHOR

Harry Hochheiser (hsh@nih.gov)

=cut
