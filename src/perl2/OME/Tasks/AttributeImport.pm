package OME::Tasks::AttributeImport;

use strict;
use XML::LibXML;

sub new {
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my %params = @_;
	my $debug = $params{debug} || 0;
	
	print STDERR $proto . "->new called with parameters:\n\t" . join( "\n\t", map { $_."=>".$params{$_} } keys %params ) ."\n" 
		if $debug > 1;
	
	my @requiredParams = ('session','semanticTypes','semanticColumns');
	
	foreach (@requiredParams) {
		die ref ($class) . "->new called without required parameter '$_'"
			unless exists $params{$_}
	}

	my $self = {
		session         => $params{session},
		debug           => $params{debug} || 0,
		semanticTypes   => $params{semanticTypes},
		semanticColumns => $params{semanticColumns},
		_parser         => $params{_parser},
		references      => $params{references},
	};
	
	if (!defined $self->{_parser}) {
		my $parser = XML::LibXML->new();
		die "Cannot create XML parser"
		  unless defined $parser;
		
		$parser->validation(exists $params{ValidateXML}?
							$params{ValidateXML}: 0);
		$self->{_parser} = $parser;
	}

	# this is for development only! to be replaced w/ id's from db after linkage happens!
	$self->{idSeq} = 0;

	bless($self,$class);
	print STDERR ref ($self) . "->new returning successfully\n" 
		if $debug > 1;
	return $self;
}


###############################################################################
#
# processDOM
# parameters:
#	$root element (DOM model)
# 	$parentType - Denotes what container these attributes belong to.
# 	$parentDBID - Database ID of the container holding these attributes
# 		(unless global attribute)
#
sub processDOM() {
	my $self       = shift;
	my $root       = shift;
	my $parentType = shift; # this can be 'G', 'D', 'I', or 'F'
	my $parentDBID = shift;

	my $attrHash   = {};
	my $session    = $self->{session};
	my $factory    = $session->Factory();
	my $debug      = $self->{debug};

	
	###########################################################################
	#
	# find custom attributes that are DIRECT DESCENDENTS OF THIS NODE or return undef
	#
	my @tmp = grep {
		$_->parentNode()->tagName() eq $root->tagName()} 
			@{$root->getElementsByLocalName('CustomAttributes')}
		or return undef;
	my $customAttributesXML = shift @tmp;
	#
	###########################################################################


	###########################################################################
	#
	# find attribute nodes, process them
	#
	my @attributesXML = grep{ $_->nodeType eq 1 } $customAttributesXML->childNodes();
	foreach my $attributeXML ( @attributesXML ) {
	
		#######################################################################
		#
		# parse attributes & store data. record ID for to reference later.
		#
# !!!!!   validate attribute structure & content against $self->{semanticTypes}   !!!!!
		my %data = map{ $_->name() => $_->value() } $attributeXML->attributes();
		
		#
		#######################################################################
		
		
		#######################################################################
		#
		# record references in a hash entry called 'refs'.
		#
		foreach my $refXML (@{ $attributeXML->getElementsByLocalName('Ref') }) {
			my $ref = {};
			$ref->{Refer} = $refXML->getAttribute( 'Refer' );
			$ref->{XMLID} = $refXML->getAttribute( 'ID' );
			$ref->{DocID} = $refXML->getAttribute( 'DocumentRef' );
			push( @ {$data{refs}}, $ref );
		}
		#
		#######################################################################

		push( @{ $attrHash->{ $attributeXML->tagName() } }, \%data );
	}
	#
	###########################################################################
	

	###########################################################################
	#
	# Store Attributes and record DB ID.
	#
	foreach my $attributeType ( keys %$attrHash ) {
		foreach my $attribute ( @{ $attrHash->{$attributeType} } ) {
			# Store to DB. Use variables
			# $parentDBID and $parentType as necessary.
			
			# populate $self->{references}. I'm using $self->{idSeq} in leau of a database ID.
			$self->{idSeq} += 1;
			$self->{references}->{$attributeType . $attribute->{ID} } = 
				$self->{idSeq}
				if exists $attribute->{ID};
		}
	}
	#
	###########################################################################

	
	###########################################################################
	#
	# resolve references. Need to redo when we support DocumentRef
	#
	# produce a list of refs hashes
	my @refs = 
		map( @{ $_->{refs} },
			grep( exists $_->{refs}, 
				map( @$_, values %$attrHash ) ) );

	# resolve the reference & set a DBID in each refs hash	
	foreach my $ref ( @refs ) {
		$ref->{DBID} = $self->{references}->{ $ref->{Refer} . $ref->{XMLID} } or
			die "Could not resolve reference. reference is to: \n\t". 
				join( "\n\t", map ( $_." => ".$ref->{$_}, keys %$ref ) )."\n";
	}
	#
	###########################################################################
	
	
	###########################################################################
	#
	# Show what we've got.
	#
	if( $debug ) {
	my %names = ( G => 'Global', D => 'Dataset', I => 'Image', F => 'Feature' );
	print STDERR "Processing ".$names{ $parentType }." attributes.\n";
	foreach my $attributeType ( keys %$attrHash ) {

		print STDERR $attributeType."\n";
		foreach my $attribute ( @{ $attrHash->{$attributeType} } ) {
			# print indented attribute info, doublely indented ref info, followed by newline
			print STDERR "\t".join( "\n\t", map( $_." => ".$attribute->{$_}, 
				grep{ $_ if ($_ ne 'refs')} keys %$attribute ) );
			print STDERR "\n\tReferences:"
				if($attribute->{refs});
			foreach my $ref( @{ $attribute->{refs} } ) {
				print STDERR "\n\t\t".join("\t",
					map( $_." => ".$ref->{$_}, keys %$ref ) );
			}
			
			print STDERR "\n\n";
		}
	} }
	#
	###########################################################################

	# return attributes?

}
#
# END sub processAttributes
#
###############################################################################


=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=head1 SEE ALSO

OME/src/xml/schemas/AnalysisModule.xsd - XML specification documents should conform to.
OME/src/xml/schemas/CLIExecutionInstructions.xsd - XML specification documents should conform to.

=cut


1;
