#! /usr/local/bin/perl -w

# DICOM.pm ver 0.3
# Andrew Crabb (ahc@jhu.edu), May 2002.
# Perl module to read DICOM headers.
#
# Modified by Tom Macura (tmacura@nih.gov) to work with OME. 
# (1) replace all local file read calls with remote (against OMEIS) file read calls
# (2) remove functionality we don't need. This includes all DICOM writing functionality
#     and all GUI, CLI components. Basically whats left is a lean DICOM header reading
#     utility. The rest is gone.
# (3) OX value representations handling changed. OX value representations are used
#     for pixels data and large binary objects. Therefore I only store the file set not
#     the actual bytes in the perl hash.
#     This breaks things for JPEG encoded pixels. We don't support that anyway.
package OME::ImportEngine::DICOM;

use strict;
use Carp;

use OME::File;
use OME::ImportEngine::DICOMconstants;	# Standard header definitions.

# Class variables.
my %dict;		      # DICOM dictionary.
our @dicom_fields;
our @dicom_private;

# Initialize dictionary only once.
# Read the contents of the DICOM dictionary into a hash by group and element.
# dicom_private is read after dicom_fields, so overrides common fields.
BEGIN {
  foreach my $line (@OME::ImportEngine::DICOMconstants::dicom_fields, 
  					@OME::ImportEngine::DICOMconstants::dicom_private) {
    next if ($line =~ /^\#/);
    my ($group, $elem, $code, $numa, $name) = split(/\s+/, $line);
    my @lst = ($code, $name);
    $dict{$group}{$elem} = [@lst];
  }
}

sub new {
  my $class = shift;

  my $elements = {};
  bless $elements, $class;
  return $elements;
}

# Fill in hash with header members from given file.
sub fill {
	my ($this, $file) = @_; # N.B: file is a OME::File object
	my $buff;
	my $element;
	
	# prepare the file for reading
	$file->open('r');
	$file->setCurrentPosition(0,0);
	
	# If DICM, store initial preamble and leave file ptr at 0x84.
	my $preamblebuff = $file->readData(128);
	$buff = $file->readData(4);
	$buff eq 'DICM' or die "file passed into DICOM.pm's fill is not a dicom file";
	
	until ($file->eof()) {
		$element = OME::ImportEngine::DICOM_element->new();
		$element->fill($file, \%dict) or return 1;
		
		$element->print();
		
		# store the element's references in two hashes
		# (1) by group and element hex numbers and (2) by fieldname
		my ($gp, $el, $fn);
		$gp = $element->{'group'};
		$el = $element->{'element'};
		$fn = $element->{'name'};
		
		$this->{$gp}{$el} = $element;
		$this->{$fn}      = $element;
	}
	
	$file->close();
	return 0;
}

# This is the method you want to use to get DICOM tag values after you
# read them (via the fill function) from the DICOM file. It can be called
# either by specifying the group and element numbers, of just by specifying
# the field name
#
#	$dicom_tags->fill($file);
#	$date = $dicom_tags->value('0008', '0020');
#   $date = $dicom_tags->value('StudyDate');

sub value {
	my $this = shift;
  	my $elem;
  	
  	# specfied field name so we need to search for element and group numbers
  	if ( scalar(@_) == 1) {
  		my ($fn) = @_;
  		$elem = $this->{$fn}
  	} elsif (scalar(@_) == 2) {
  		my ($gp, $el) = @_;
  	  	$elem = $this->{$gp}{$el};
  	} else {
  		croak "the parameters are wrong\n";
  	}
  	
  	return undef unless defined($elem);
  	return (defined($elem->value())) ? $elem->value() : "";
}

# The DICOM_element package is from 
# DICOM_element.pm ver 0.3 by Andrew Crabb (ahc@jhu.edu), May 2002.
# 
#
# Each element is a hash with the following keys:
#   group	Group (hex).
#   element	Element within group (hex).
#   offset	Offset from file start (dec).
#   code	Field code eg 'US', 'UI'.
#   length	Field value length (dec).
#   name	Field descriptive name.
#   value	Value.s
#   header	All bytes up to value, for easy writing.

package OME::ImportEngine::DICOM_element;

use strict;
use Carp;

use OME::File;
use OME::ImportEngine::DICOMconstants;

my %VR;			            # Value Representations (DICOM Std PS 3.5 Sect 6.2)
my ($SHORT, $INT) = (2, 4);	# Constants: Byte sizes.

# Names of the element fields.
my @fieldnames = qw(group element offset code length name value header);

# Initialize VR hash only once.
BEGIN {
	my @VR_dict = @OME::ImportEngine::DICOMconstants::VR_dict;	
	foreach my $line (@VR_dict) {
		next if ($line =~ /^\#/);
		my ($vr, $name, $len, $fix) = split(/\t+/, $line);
		$VR{$vr} = [($name, $len, $fix)];
	}
}

sub new {
  my $type = shift;
  my $self = {};
  return bless $self, $type;
}

# Fill in self from file.
sub fill {	
	my ($this, $file, $dictref) = @_;
  	my %dict = %$dictref;
  
  	my ($group, $element, $offset, $code, $length, $name, $value, $header);
  
	# Tag holds group and element numbers in two bytes each.
	$offset  = $file->getCurrentPosition();
	$group   = sprintf "%04X", readInt($file, $SHORT);
	$element = sprintf "%04X", readInt($file, $SHORT);
		
	# Next 4 bytes are either explicit VR or length (implicit VR).
	$length = readLength($file);
	
	# Go to record start, read bytes up to value field, store in header.
	my $diff = $file->getCurrentPosition() - $offset;
	$file->setCurrentPosition($offset,0);
	$header = $file->readData($diff);
	
	if (exists($dict{$group}{$element})) {
		($code,$name) = @{$dict{$group}{$element}};
	} else {
		($code, $name) = ("--", "UNKNOWN");
	}
	
	# Read in the value field.  Certain fields need to be decoded.
	$value = "";
	if ($length > 0) {
		SWITCH: {		
			# Decode ints and shorts.
			if ($code eq "UL") {$value = readInt($file, $INT,   $length); last SWITCH;}
			if ($code eq "US") {$value = readInt($file, $SHORT, $length); last SWITCH;}
			
			# Certain VRs not yet implemented: Single and double precision floats.
			if ($code eq "FL") { warn "Unsupported VR: FL\n"; last SWITCH; }
			if ($code eq "FD") { warn "Unsupported VR: FD\n"; last SWITCH; }
			
			# For an offset, don't read in the data but store the offset
			# however, move the file cursor to pretend you read the file
			if ($code eq "OX") { 
				$value = $file->getCurrentPosition();
				$file->setCurrentPosition($length-1, 1);
				last SWITCH;
			}
			
			# Made it to here: Read bytes verbatim.
			my $bytes_read;
			($value, $bytes_read) = $file->readData($length);
		}
		
		# UI may be padded with single trailing NULL (PS 3.5: 6.2.1)
		($code eq "UI") and $value =~ s/\0$//;
	}
	
	# Fill in hash of values and return them.	
	$this->{"group"}   = $group;
	$this->{"element"} = $element;
	$this->{"offset"}  = $offset;
	$this->{"code"}    = $code;
	$this->{"length"}  = $length;
	$this->{"name"}    = $name;
	$this->{"value"}   = $value;
	$this->{"header"}  = $header;

	return $this;
}

# readInt(file, bytelength, fieldlength).
#   file:    	 OME::File Object that can either be local or from OMEIS 
#                (OME Image Server)
#   bytelength:  SHORT (2) or INT (4) bytes.
#   fieldlength: Total number of bytes in the field.
#
# If fieldlength > bytelength, multiple values are read in and stored as 
# a string representation of an array.
sub readInt {
  my ($file, $bytes, $len) = @_;
  my ($buff, $val, @vals);
  
  # Perl little endian decode format for short (v) or int (V).
  my $format = ($bytes == $SHORT) ? "v" : "V";
  $len = $bytes unless (defined($len));

  $buff = $file->readData($len) or die;
  if ($len == $bytes) {
    $val = unpack($format, $buff);
  } else {
    # Multiple values: Create array.
    for (my $pos = 0; $pos < $len; $pos += 2) {
      push(@vals, unpack("$format", substr($buff, $pos, 2)));
    }
    $val = "[" . join(", ", @vals) . "]";
  }

  return $val;
}

# Return the Value Field length, and length before Value Field.
# Implicit VR: Length is 4 byte int.
# Explicit VR: 2 bytes hold VR, then 2 byte length.
sub readLength {
  my ($file) = @_;
  my ($b0, $b1, $b2, $b3);
  my ($buff, $vrstr);
  
  # Read 4 bytes into b0, b1, b2, b3.
  $b0 = unpack ("C", $file->readData(1));
  $b1 = unpack ("C", $file->readData(1));
  $b2 = unpack ("C", $file->readData(1));
  $b3 = unpack ("C", $file->readData(1));

  # Temp string to test for explicit VR
  $vrstr = pack("C", $b0) . pack("C", $b1);
  
  # Assume that this is explicit VR if b0 and b1 match a known VR code.
  # Possibility (prob 26/16384) exists that the two low order field length 
  # bytes of an implicit VR field will match a VR code.

  # DICOM PS 3.5 Sect 7.1.2: Data Element Structure with Explicit VR
  # Explicit VRs store VR as text chars in 2 bytes.
  #
  # VRs of OB, OW, SQ, UN, UT have VR chars, then 0x0000, then 32 bit VL:
  # +-----------------------------------------------------------+
  # |  0 |  1 |  2 |  3 |  4 |  5 |  6 |  7 |  8 |  9 | 10 | 11 |
  # +----+----+----+----+----+----+----+----+----+----+----+----+
  # |<Group-->|<Element>|<VR----->|<0x0000->|<Length----------->|<Value->
  #
  # Other Explicit VRs have VR chars, then 16 bit VL:
  # +---------------------------------------+
  # |  0 |  1 |  2 |  3 |  4 |  5 |  6 |  7 |
  # +----+----+----+----+----+----+----+----+
  # |<Group-->|<Element>|<VR----->|<Length->|<Value->
  #
  # Implicit VRs have no VR field, then 32 bit VL:
  # +---------------------------------------+
  # |  0 |  1 |  2 |  3 |  4 |  5 |  6 |  7 |
  # +----+----+----+----+----+----+----+----+
  # |<Group-->|<Element>|<Length----------->|<Value->

  foreach my $vr (keys %VR) {
  	if ($vrstr eq $vr) {
  		# Have a code for an explicit VR: Retrieve VR element
      	my $ref = $VR{$vr};
      	my ($name, $bytes, $fixed) = @$ref;
      	if ($bytes == 0) {
			# This is an OB, OW, SQ, UN or UT: 32 bit VL field.
			# Have seen in some files length 0xffff here...
			return readInt($file, $INT);
      	} else {
			# This is an explicit VR with 16 bit length.
			return ($b3 << 8) + $b2;
      	}
     }
  }

  # Made it to here: Implicit VR, 32 bit length.
  return ($b3 << 24) + ($b2 << 16) + ($b1 << 8) + $b0;
}

# Print formatted representation of element to stdout.
sub print {
	my $this = shift;
	if ($this->{'code'} ne '--') {
		printf "(%04X, %04X) %s %6d: %-33s = %s\n", 
			hex($this->{'group'}),
			hex($this->{'element'}), 
			$this->{'code'},
			$this->{'length'},
			$this->{'name'},
			$this->{'value'};
	} else {
		# don't print the values of unknown dicom fields
		printf "(%04X, %04X) %s %6d: %-33s \n", 
			hex($this->{'group'}),
			hex($this->{'element'}), 
			$this->{'code'},
			$this->{'length'},
			$this->{'name'};
	}
}

# return the value of a particular element. This is alled by value() from DICOM package
sub value {
  my $this = shift;
  return $this->{'value'};
}
1;
