package OME::Graphics::JavaScript::Layer::OMEimage;
use strict;
use OME::Session;
use OME::Graphics::JavaScript::Layer;
use vars qw($VERSION @ISA);
$VERSION = '1.0';
@ISA = ("OME::Graphics::JavaScript::Layer");

my $JStype = 'OMEimage';
my $JSobject = <<ENDJSOBJECT
function $JStype (CGI_URL,name,Dims,Path,isRGB,WBS,RGBon,optionsStr,Wavelengths,Stats) {
	this.base = Layer;
	this.base(CGI_URL,name,optionsStr);
	this.optionsStr = optionsStr;

	this.Dims = Dims;
	this.options.push ('Dims');
	this.Path = Path;
	this.options.push ('Path');
	this.optionsStr = optionsStr;
	this.Wavelengths = Wavelengths;
	this.Stats = Stats;
	
	this.WBS = WBS;
	this.optionsTypeIdx = this.options.length;
	if (isRGB) {
		this.options.push ('RGB');
		this.isRGB = true;
	} else {
		this.options.push ('Gray');
		this.isRGB = false;
	}
	this.RGB = WBS.slice(0,9).join();
	this.Gray = WBS.slice(9,12).join();
	this.RGBon = RGBon;
	this.options.push ('RGBon');

// Stats does not seem to be used. WBS needs to be updated with change to t and 
// wavelengths. It needs info from Stats to do this.
	
	this.setParam = setParam;
	this.setType  = setType;
	this.setRGBon = setRGBon;
	
	return this;
	
	function setParam (theParam, theValue) {
		if (theParam < 0 || theParam > 11) return;
		this.WBS[theParam] = theValue;
		this.RGB = WBS.slice(0,9).join(',');
		this.Gray = WBS.slice(9,12).join(',');

//		alert ("theParam:"+theParam+" theValue:"+theValue+"\\nWBS:"+this.WBS+"\\nRGB:"+this.RGB+"\\nGray:"+this.Gray);
		if (this.isRGB && theParam >= 0 && theParam < 9) {
			this.Dirty();
			this.RedrawImage();
		} else if (!this.isRGB && theParam > 8 && theParam < 12) {
			this.Dirty();
			this.RedrawImage();
		}
	}
	
	function setType (isRGB) {
		isRGB = isRGB ? true : false;
		if (isRGB == this.isRGB) return;
		
		if (isRGB) {
			this.options[this.optionsTypeIdx] = 'RGB';
			this.isRGB = true;
//			alert ('isRGB -> true\\n'+this.options[this.optionsTypeIdx]+': '+this.RGB);
		} else {
			this.options[this.optionsTypeIdx] = 'Gray';
			this.isRGB = false;
//			alert ('isRGB -> false\\n'+this.options[this.optionsTypeIdx]+': '+this.Gray);
		}
		this.Dirty();
		this.RedrawImage();
	}
	
	function setRGBon (chanel,isOn){
		isOn = isOn ? 1 : 0;
		if (chanel < 0 || chanel > 2) return;
		var RGBon = this.RGBon.split(',');
		if (RGBon[chanel] == isOn) return;
		RGBon[chanel] = isOn;
		this.RGBon = RGBon.join(',')
		this.Dirty();
		this.RedrawImage();
	}
	
}
$JStype.prototype = new Layer;

ENDJSOBJECT
;

# initial draft of pod added by Josiah Johnston, siah@nih.gov
=pod

=head1 OMEimage.pm

=head1 Package information

L<"Description">, L<"Path">, L<"Package name">, L<"Dependencies">, L<"Function calls to OME Modules">, L<"Data references to OME Modules">

=head2 Description

A subclass of L<OME::Graphics::JavaScript::Layer> that handles OME images. 

=head2 Path

src/perl2/OME/Graphics/JavaScript/Layer/OMEimage.pm

=head2 Package name

OME::Graphics::JavaScript::Layer::OMEimage

=head2 Dependencies

B<inherits from>
	L<OME::Graphics::JavaScript::Layer>
B<OME Modules>
	L<OME::Session>

=head2 Function calls to OME Modules

=over 4

=item L<OME::Graphics::JavaScript::Layer/"Form_visible()">

=back

=head2 Data references to OME Modules

none

=head1 Externally referenced Functions

=head2 new()

=over 4

=item Description

constructor

=item Parameters

The parameters specified in its parent class: L<OME::Graphics::JavaScript::Layer>.

=item Returns

I<$self>

=item Overrides function in L<OME::Graphics::JavaScript::Layer/"new()">

=item Uses functions

L<OME::Graphics::JavaScript::Layer/"new()">

=back

=cut



# new
# ---

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %params = @_;
	my $self = $class->SUPER::new(@_);
	bless $self,$class;
print STDERR ref($self)."->new()\n";
	$self->{JStype} = $JStype;
	push (@{$self->{JSdeps}},$JStype);
	push (@{$self->{JSdefs}},$JSobject);



	return $self;
}


=pod

=head2 Form()

=over 4

=item Description

Makes html form elements to control the javascript object associated with this layer.
The form elements are inside of table rows.

=item Parameters

none

=item Returns

An HTML snippet.

=item Uses functions

=over 4

=item L<OME::Graphics::JavaScript::Layer/"Form_visible()">

=item L<"RGBon()">

Uses this to find which RGB channels are turned on.

=item L<"MakeWaveMenu()">

Uses this to generate a combo box of wavelengths.

=back

=back

=cut

#
sub Form {
my $self = shift;
my ($RGBchecked,$GSchecked) = ('','');
my $objRef = $self->{ObjectRef};
my @RGBon = split (',',$self->RGBon());
my ($rOn,$gOn,$bOn);

	$rOn = 'checked' if $RGBon[0];
	$gOn = 'checked' if $RGBon[1];
	$bOn = 'checked' if $RGBon[2];

	$RGBchecked = 'checked' if $self->{isRGB};
	$GSchecked = 'checked' if not $self->{isRGB};

	return
		'<TR><TD>'.$self->Form_visible()."</TD><TD>$self->{name}</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="radio" name="RGBradio" $RGBchecked onclick="$objRef.setType(this.checked)">RGB</TD>'.
		qq '<TD colspan="3"><input type="radio" name="RGBradio" $GSchecked onclick="$objRef.setType(!this.checked)">Grayscale&nbsp;\n'.$self->MakeWaveMenu(9)."</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="checkbox" name="RedCheckBox" $rOn onclick="$objRef.setRGBon(0,this.checked)">Red</TD><TD>&nbsp;\n'.$self->MakeWaveMenu(0)."</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="checkbox" name="GrnCheckBox" $gOn onclick="$objRef.setRGBon(1,this.checked)">Green</TD><TD>&nbsp;\n'.$self->MakeWaveMenu(3)."</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="checkbox" name="BluCheckBox" $bOn onclick="$objRef.setRGBon(2,this.checked)">Blue</TD><TD>&nbsp;\n'.$self->MakeWaveMenu(6)."</TD></TR>\n";

}

=pod

=head2 JSinstance()

=over 4

=item Description

Makes a javascript command to instantiate the javascript object OMEimage.

=item Parameters

none

=item Returns

A line of javascript.

=item Overrides function L<OME::Graphics::JavaScript::Layer/"JSinstance()">

=item Uses functions

=over 4

=item L<OME::Factory/"loadObject()">

=item L<OME::Image/"getFullPath()">

=item L<"WBS()">

Uses this to get a WBS table to send to the JavaScript function as an initialzation
parameter.

=item L<"RGBon()">

Uses this to find which RGB channels should be on. It needs this for initialization
parameters for the JavaScript function.

=back

=item Accesses external data

=over 4

=item OME::Graphics::JavaScript->{Dims}

=item OME::Graphics::JavaScript->{Session}

=item OME::Session->{Factory}

=back

=back

=cut

sub JSinstance {
my $self = shift;
my $JStype = $self->{JStype};
my $objName = $self->{name};
my $LayerCGI = $self->{LayerCGI};
my $JSoptions = $self->{OptionsString};
my $isRGB = $self->{isRGB} ? 'true' : 'false';

# At this juncture, the layer must have been added to the parent, otherwise, we're missing a lot of vital info we need to
# instantiate the JS instance (like the Image and ImageID for instance).
	die ref($self)."JSinstance was called, but this layer has no Parent!\n" unless exists $self->{Parent} and defined $self->{Parent};

	my $image = $self->{Parent}->{Session}->Factory()->loadObject("OME::Image",$self->{Parent}->{ImageID})
		|| die "JSinstance called without a defined Image object in Parent\n";

	$self->{Path} = $image->getFullPath();
	$self->{JS_Dims} = join (',', @{$self->{Parent}->{Dims}});

# Now make the WBS JS 'object'
# The WBS array is specified as a comma-separated list in the DB, which becomes a string in our {WBS} field.
# The JS_WBS represents this as a JS Array.
# Call the get method to make sure its kickin - we'll refer to it by field later.
	$self->WBS();  #this has side affect of calling Wavelengths & Stats. This side affect is used below.
	$self->RGBon();


	return <<ENDJS;
var $objName = new $JStype ("$LayerCGI","$objName","$self->{JS_Dims}","$self->{Path}",$isRGB,$self->{JS_WBS},"$self->{RGBon}","$JSoptions",$self->{JS_Wavelengths},$self->{JS_Stats});
ENDJS
}

=pod

=head1 Internally referenced functions

=head2 Wavelengths()

=over 4

=item Description

Issues a direct SQL query to get wavelengths and statistics for the image. It uses these
results to fill the variables I<$self-E<gt>{Wavelengths}> and I<$self-E<gt>{JS_Wavelengths}>.
It will generate emmission wavelength and fluor if one is specified and the other is not.

I<$self-E<gt>{Wavelengths}> is a reference to a list of wavelengths. These wavelengths are a list of wavenumber, 
emission wavelength, and fluor.
I<$self-E<gt>{JS_Wavelengths}> is a string to be interpretted in Javascript. In javascript it is an array of hashtables. It
contains the same information as I<$self-E<gt>{Wavelengths}>.

=item Parameters

none

=item Returns

I<$self->{Wavelengths}>

See Description above for explanation of this variable.

=item Uses functions

=over 4

=item L<OME::Session/"DBH()">

=item DBI->prepare()

=item $sth->execute()

=item $sth->fetchrow_array()

=item L<"GetFluorsWaves">

=item L<"GetWavesFluors">

=back

=item Accesses external data

=over 4

=item OME::Graphics::JavaScript->{Session}

=item OME::Graphics::JavaScript->{ImageID}

=back

=item Accesses database table

image_wavelengths

=back

=cut

# FIXME: This is a direct SQL query to get wavelengths and statistics for the image.
sub Wavelengths {
	my $self = shift;
	return $self->{Wavelengths} if exists $self->{Wavelengths} and defined $self->{Wavelengths};
	
	my $DBH = $self->{Parent}->{Session}->DBH() || die "Wavelengths called without a session object\n";
	my $ImageID = $self->{Parent}->{ImageID};
	my $fluors = $self->GetFluorsWaves;
	my $waveFluors = $self->GetWavesFluors;

#image_wavelengths: image_id | wavenumber | ex_wavelength | em_wavelength | fluor | nd_filter
	my $sth;
	my @wavelengths;
	my @wavelengthSorted;
	my @rowArray;
	my @JS_Wavelengths;
	
	$sth = $DBH->prepare ("SELECT wavenumber,em_wavelength,fluor FROM image_wavelengths WHERE image_id=?");
	$sth->execute($ImageID);
	while ( @rowArray = $sth->fetchrow_array) { push (@wavelengths,[@rowArray]); }

# Assign em_wavelength based on fluor or based on wavenumber as a last resort.
# Set the fluor to the fluor, or to a fluor matching em_wavelength or to the em_wavelength as a last resort
# The fluor is what the user sees in the selection menu.
	foreach (@wavelengths) {
		$_->[1] = $fluors->{$_->[2]} unless defined $_->[1] and $_->[1];
		$_->[1] = $_->[0]+1 unless defined $_->[1] and $_->[1];
		if (not defined $_->[2] and exists $waveFluors->{$_->[1]}) {$_->[2] = $waveFluors->{$_->[1]}};
		$_->[2] = $_->[1] unless defined $_->[2];
	}

	# Sort on em_wavelength
	$self->{Wavelengths} = [sort {$b->[1] <=> $a->[1]} @wavelengths];
	
	# Convert to JavaScript
	foreach (@{$self->{Wavelengths}}) {
		push (@JS_Wavelengths,'{WaveNum:'.$_->[0].',Emission:'.$_->[1].',Fluor:"'.$_->[2].'"}');
	}
	$self->{JS_Wavelengths} = '['.join (',',@JS_Wavelengths).']';
	
	return $self->{Wavelengths};
}

=pod

=head2 JS_Wavelengths()

=over 4

=item Description

Returns I<$self-E<gt>{JS_Wavelengths}>. It calls a function to generate it if it doesn't exist. See L<"Wavelengths()">
for a description of this varaible.

=item Parameters

none

=item Returns

I<$self-E<gt>{JS_Wavelengths}>. 

See L<"Wavelengths()"> for a description of this varaible.

=item Uses functions

=over 4

=item L<"Wavelengths()">

=back

=back

=cut

sub JS_Wavelengths {
	my $self = shift;
	return $self->{JS_Wavelengths} if exists $self->{JS_Wavelengths} and defined $self->{JS_Wavelengths};
	$self->Wavelengths();
	return $self->{JS_Wavelengths};
}

=pod

=head2 RGBon()

=over 4

=item Description

Decides what RBG channels should be on.
This info is stored in a string representing a javascript three member array of 0|1. 
This is stored in I<$self-E<gt>RGBon>.

=item Parameters

none

=item Returns

A string that, in javascript, is a three member array of 0|1.

=item Uses functions

=over 4

=item L<"Wavelengths()">

=item L<"GetFluorsColors()">

=back

=back

=cut

#
# RGBon is a javascript 3-member array of 0|1 specifying which of the three RGB channels are on
sub RGBon {
	my $self = shift;
	return $self->{RGBon} if exists $self->{RGBon} and defined $self->{RGBon};

	my $Wavelengths = $self->Wavelengths();
	my $fluorsColors = $self->GetFluorsColors();
	
	if (scalar (@$Wavelengths) > 2) {
		$self->{RGBon} = '1,1,1';
	} else {
		my $color;
		my @RGBon = (0,0,0);
		my $i;
		for ($i = 0; $i < scalar (@$Wavelengths); $i++) {
			$color = undef;
			if (exists $fluorsColors->{$Wavelengths->[$i]->[2]}) {$color = $fluorsColors->{$Wavelengths->[$i]->[2]};}
			# this is screwy.
			#	Say at $i=0, $color isn't defined. So red ($RGB[0]) is turned on.
			#	And at $i=1, $color is defined to be R. So red is turned on again.
			#   Two wavelengths exist, and one channel is turned on.
			# It needs to turn on defined colors, then go back over the list
			# and turn on more channels if necessary.
			if (not defined $color) {
				$RGBon[$i] = 1;
			} else {
				$RGBon[0] = 1 if $color eq 'R';
				$RGBon[1] = 1 if $color eq 'G';
				$RGBon[2] = 1 if $color eq 'B';
			}
		}
		$self->{RGBon} = join (',',@RGBon);
	}
	
	return $self->{RGBon};
	
	
}

=pod

=head2 Stats()

=over 4

=item Description

This is a direct SQL query to get wavelengths and statistics for the image. This data is stored in I<$self-E<gt>{Stats}>
and I<$self-E<gt>{JS_Stats}>.

I<$self-E<gt>{Stats}> is a two dimensional array indexed by [wavenumber][timepoint]. Each element in the array is a hash
with the keys of: min, max, mean, geomean, and sigma.

I<$self-E<gt>{JS_Stats}> contains the same information and structure. But it is converted into a string for use in javascript.

=item Parameters

none

=item Returns

I<$self-E<gt>{Stats}>

See Description above for explanation of this variable.

=item Uses functions

=over 4

=item L<OME::Session/"DBH()">

=item DBI->prepare()

=item $sth->execute()

=item $sth->fetchrow_array()

=back

=item Accesses external data

=over 4

=item OME::Graphics::JavaScript->{Session}

=back

=item Accesses database table

xyz_image_info

=back

=cut

# FIXME: This is a direct SQL query to get wavelengths and statistics for the image.
sub Stats {
	my $self = shift;
	return $self->{Stats} if exists $self->{Stats} and defined $self->{Stats};

	my $DBH = $self->{Parent}->{Session}->DBH() || die ref($self)."->Stats: DB Handle undefined - Stats called without a Session object\n";
	my $sth;
	my @rowArray;
	my @stats_js;

#xyz_image_info: image_id | wavenumber | timepoint | min | max | mean | geomean | sigma
	$self->{JS_Stats} ="";
	$sth = $DBH->prepare ("SELECT wavenumber,timepoint,min,max,mean,geomean,sigma FROM xyz_image_info WHERE image_id=?");
	$sth->execute($self->{Parent}->{ImageID});
	while ( @rowArray = $sth->fetchrow_array) {
		$self->{Stats}->[$rowArray[0]][$rowArray[1]] = {
			min => $rowArray[2],max => $rowArray[3],mean => $rowArray[4],geomean => $rowArray[5],sigma => $rowArray[6]};
		$stats_js[$rowArray[0]][$rowArray[1]] = '{min:'.$rowArray[2].',max:'.$rowArray[3].
			',mean:'.$rowArray[4].',geomean:'.$rowArray[5].',sigma:'.$rowArray[6].'}';
	}

# Convert to JavaScript
#	[[{min:123,max:456,...},{min:123,max:123,...},...],...]
	my @JS_Stats_Waves;
	for (my $i=0;$i<scalar (@stats_js);$i++) {
		push (@JS_Stats_Waves,'['.join (',',@{$stats_js[$i]}).']');
	}
	$self->{JS_Stats} = '['.join (',',@JS_Stats_Waves).']';
	
	return $self->{Stats};
}

=pod

=head2 WBS()

=over 4

=item Description

Constructs the WBS array with defaults. This information is stored in I<$self-E<gt>{WBS}> and I<$self-E<gt>{JS_WBS}>.

I<$self-E<gt>{WBS}> is a one dimensional array of 12 elements. Data is stored in four groups of three. Each of the
four groups represented a channel. The order of the channels is Red, Green, Blue, and Grey. The data in each of
the groups is wavenumber, black level, and scale. Go somewhere else if you need the function of these explained.

The default black level of a channel is the geomean of the xyz stack selected by the
channel's wavelength and theT.
The default scale of a channel is currently 255 / (4*sigma). sigma is the standard
deviation of the xyz stack.

I<$self-E<gt>{JS_WBS}> contains the same data and structure converted to a string for use in javascript.

=item Parameters

none

=item Returns

I<$self-E<gt>{WBS}>

see Description above for explanation of this variable.

=item Uses functions

=over 4

=item L<"Wavelengths()">

Uses the sorted list of wavenumbers Wavelengths provides. This is used to assign
waves to RGB channels. 

=item L<"Stats()">

Uses the stat info this provides to generate default black level and scale.

=back

=item Accesses external data

=over 4

=item OME::Graphics::JavaScript->{Dims}

=item OME::Graphics::JavaScript->{theT}

=back

=back

=cut

# This method gets called to set up the WBS array with defaults.
# Because the defaults are 'intelligent', we need to consult the DB.
# The WBS field may be stored as part of the Options string in the DB, and converted to a field of this object.
# If the WBS field exists, then its a string of comma-sparated numbers.
# For now, we're keeping this field as a string of comma-sparated numbers.
sub WBS {
	my $self = shift;
	return $self->{WBS} if exists $self->{WBS} and defined $self->{WBS};

	my $Wavelengths = $self->Wavelengths();
	my $Stats = $self->Stats();
	
	# Assign the wavenumbers
	my $redWave = $Wavelengths->[0]->[0];
	my $grnWave = $Wavelengths->[$self->{Parent}->{Dims}->[3] / 2]->[0];
	my $bluWave = $Wavelengths->[$self->{Parent}->{Dims}->[3] - 1]->[0];
	my $gryWave = 0;
	my $theT = $self->{Parent}->{theT};
	my @WBS;
			
	$WBS[0] = $redWave;
	$WBS[3] = $grnWave;
	$WBS[6] = $bluWave;
	$WBS[9] = $gryWave;
	
	# Assign the black level (default is geomean)
	$WBS[ 1] = sprintf ('%d',$Stats->[$redWave][$theT]->{geomean});
	$WBS[ 4] = sprintf ('%d',$Stats->[$grnWave][$theT]->{geomean});
	$WBS[ 7] = sprintf ('%d',$Stats->[$bluWave][$theT]->{geomean});
	$WBS[10] = sprintf ('%d',$Stats->[$gryWave][$theT]->{geomean});

	# Assign the scale based on the white level, which is set to geomean + 4*sigma
	# the scale is 255 / 4*sigma.
	$WBS[ 2] = sprintf ('%.5f',255 / ($Stats->[$redWave][$theT]->{sigma} * 4));
	$WBS[ 5] = sprintf ('%.5f',255 / ($Stats->[$grnWave][$theT]->{sigma} * 4));
	$WBS[ 8] = sprintf ('%.5f',255 / ($Stats->[$bluWave][$theT]->{sigma} * 4));
	$WBS[11] = sprintf ('%.5f',255 / ($Stats->[$gryWave][$theT]->{sigma} * 4));

	# Jonvert to DB Options form
	$self->{WBS} = join (',',@WBS);	
	# Either the WBS came from the DB or it was set above to defaults.
	# Convert the WBS field from DB form to JS form - a JS hash.
	$self->{JS_WBS} = '['.$self->{WBS}.']';
	
	return $self->{WBS};
}

=pod

=head2 MakeWaveMenu()

=over 4

=item Description

This generates a html comboBox (AKA SELECT) form control that lists all the wavelengths.
Depending on available information, wavelengths will be represented by fluors, physical 
wavelengths, or wavenumbers.

=item Parameters

I<$WBSidx>

valid values of I<$WBSidx> are 0, 3, 6, and 9. Respectively, these will represent the wavenumbers assigned to the
Red, Green, Blue, and Grey channels by L<"WBS()">. Basically, use the number that corrosponds with the channel the generated
combo box will control. It uses this to find the wave in the combo box that nees to be
selected.

=item Returns

An HTML SELECT element

=item Uses functions

=over 4

=item L<"WBS()">

Uses this to find what wavenumber is assigned to a given channel.

=item L<"Wavelengths()">

Uses this to get a list of the fluors this image has. It uses the fluors (or whatever
information ends up in that field) as content for the combo box.

=back

=back

=cut

sub MakeWaveMenu {
my $self = shift;
my $WBSidx = shift;
my @WBS = split (',',$self->WBS());
my $waveNum = $WBS[$WBSidx];
my $name = $self->{name}."Wavelengths";
my $objName = $self->{name};
my $objRef = $self->{ObjectRef};
my $JS = qq '	<SELECT NAME="$name" onchange="$objRef.setParam($WBSidx,parseInt(this.options[this.selectedIndex].value));">\n';
my $Wavelengths = $self->Wavelengths;


	
	foreach (@{$Wavelengths}) {
		$JS .= qq '		<option value="$_->[0]"';
		$JS .= ' selected' if $_->[0] eq $waveNum;
		$JS .= ">$_->[2]</option>\n";
	}
	$JS .= "\t</SELECT>\n";

	return $JS;
}


=pod

=head2 Fluors()

=over 4

=item Description

Returns a hash. The keys are the names of fluors. The elements are a list of [wavelength, R|G|B]. wavelength is an integer.
The second element of the table indicates the approximate color of the fluor.

=item Parameters

none

=item Returns

A hash table. See Description above for details.

=item Uses NO functions

=back

=cut

# FIXME: This should get its info from the database.
sub Fluors {
my $fluors = {
		FITC   => [528,'G'],
		TR     => [617,'R'],
		GFP    => [528,'G'],
		DAPI   => [457,'B']
	};
return 	$fluors;
}

=pod

=head2 GetFluorsColors()

=over 4

=item Description

Generates a hash. The keys are fluor names. The elements are the color of the fluor (R|G|B).

=item Parameters

none

=item Returns

A hash. See Description above for details.

=item Uses functions

=over 4

=item L<"Fluors()">

=back

=back

=cut

sub GetFluorsColors {
my $self = shift;
my $fluors = $self->Fluors();
my $fluorsColors;

	foreach (keys (%$fluors)) {
		$fluorsColors->{$_} = $fluors->{$_}->[1];
	}

	return $fluorsColors;
}

=pod

=head2 GetFluorsWaves()

=over 4

=item Description

Generates a hash. The keys are fluor names. The elements are physical wavelengths.

=item Parameters

none

=item Returns

A hash. See Description above for explanation.

=item Uses functions

=over 4

=item L<"Fluors()">

=back

=back

=cut

sub GetFluorsWaves {
my $self = shift;
my $fluors = $self->Fluors();
my $fluorsWaves;

	foreach (keys (%$fluors)) {
		$fluorsWaves->{$_} = $fluors->{$_}->[0];
	}

	return $fluorsWaves;
}

=pod

=head2 GetWavesFluors()

=over 4

=item Description

Generates a hash with information on known fluors. Keys are wavelengths. Elements are fluor names.

=item Parameters

none

=item Returns

A hash. See Description above for explanation.

=item Uses functions

=over 4

=item L<"Fluors()">

=back

=back

=cut

sub GetWavesFluors {
my $self = shift;
my $fluors = $self->Fluors();
my $waveFluors;

	foreach (keys (%$fluors)) {
		$waveFluors->{$fluors->{$_}->[0]} = $_;
	}

	return $waveFluors;
}
1;