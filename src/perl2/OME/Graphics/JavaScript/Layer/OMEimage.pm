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



sub JSinstance {
my $self = shift;
my $JStype = $self->{JStype};
my $objName = $self->{name};
my $LayerCGI = $self->{LayerCGI};
my $JSoptions = $self->{OptionsString};
my $isRGB = $self->{isRGB} ? 'true' : 'false';

# At this juncture, the layer must have been added to the parent, otherwise, we're missing a lot of vital info we need to
# instantiate the JS instance (like the Image and ImageID for instance).
	die "JSinstance was called, but this layer has no Parent!\n" unless exists $self->{Parent} and defined $self->{Parent};

	my $image = $self->{Parent}->{Image} || die "JSinstance called without a defined Image object in Parent\n";

	$self->{Path} = $image->getFullPath();
	$self->{JS_Dims} = join (',', @{$self->{Parent}->{Dims}});

# Now make the WBS JS 'object'
# The WBS array is specified as a comma-separated list in the DB, which becomes a string in our {WBS} field.
# The JS_WBS represents this as a JS Array.
# Call the get method to make sure its kickin - we'll refer to it by field later.
	$self->WBS();
	$self->RGBon();


	return <<ENDJS;
var $objName = new $JStype ("$LayerCGI","$objName","$self->{JS_Dims}","$self->{Path}",$isRGB,$self->{JS_WBS},"$self->{RGBon}","$JSoptions",$self->{JS_Wavelengths},$self->{JS_Stats});
ENDJS
}

# FIXME: This is a direct SQL query to get wavelengths and statistics for the image.
sub Wavelengths {
	my $self = shift;
	return $self->{Wavelengths} if exists $self->{Wavelengths} and defined $self->{Wavelengths};
	
	my $DBH = $self->{Parent}->{Session}->DBH() || die "MakeWaves called without a session object\n";
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

sub JS_Wavelengths {
	my $self = shift;
	return $self->{JS_Wavelengths} if exists $self->{JS_Wavelengths} and defined $self->{JS_Wavelengths};
	$self->Wavelengths();
	return $self->{JS_Wavelengths};
}

#
# RGBon is a 3-member array of 0|1 specifying which of the three RGB channels are on
sub RGBon {
	my $self = shift;
	return $self->{RGBon} if exists $self->{RGBon} and defined $self->{RGBon};

	my $Wavelengths = $self->Wavelengths();
	my $fluorsColors = $self->GetFLuorsColors();
	
	if (scalar (@$Wavelengths) > 2) {
		$self->{RGBon} = '1,1,1';
	} else {
		my $color;
		my @RGBon = (0,0,0);
		my $i;
		for ($i = 0; $i < scalar (@$Wavelengths); $i++) {
			$color = undef;
			if (exists $fluorsColors->{$Wavelengths->[$i]->[2]}) {$color = $fluorsColors->{$Wavelengths->[$i]->[2]};}
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
	# the scale is 255 / white level.
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
		'<TR><TD>'.$self->Form_visible."</TD><TD>$self->{name}</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="radio" name="RGBradio" $RGBchecked onclick="$objRef.setType(this.checked)">RGB</TD>'.
		qq '<TD colspan="3"><input type="radio" name="RGBradio" $GSchecked onclick="$objRef.setType(!this.checked)">Grayscale&nbsp;\n'.$self->MakeWaveMenu(9)."</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="checkbox" name="RedCheckBox" $rOn onclick="$objRef.setRGBon(0,this.checked)">Red</TD><TD>&nbsp;\n'.$self->MakeWaveMenu(0)."</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="checkbox" name="GrnCheckBox" $gOn onclick="$objRef.setRGBon(1,this.checked)">Green</TD><TD>&nbsp;\n'.$self->MakeWaveMenu(3)."</TD></TR>\n".
		qq '<TR><TD></TD><TD><input type="checkbox" name="BluCheckBox" $bOn onclick="$objRef.setRGBon(2,this.checked)">Blue</TD><TD>&nbsp;\n'.$self->MakeWaveMenu(6)."</TD></TR>\n";

}


sub Fluors {
my $fluors = {
		FITC   => [528,'G'],
		TR     => [617,'R'],
		GFP    => [528,'G'],
		DAPI   => [457,'B']
	};
return 	$fluors;
}

sub GetFLuorsColors {
my $self = shift;
my $fluors = $self->Fluors();
my $fluorsColors;

	foreach (keys (%$fluors)) {
		$fluorsColors->{$_} = $fluors->{$_}->[1];
	}

	return $fluorsColors;
}

sub GetFluorsWaves {
my $self = shift;
my $fluors = $self->Fluors();
my $fluorsWaves;

	foreach (keys (%$fluors)) {
		$fluorsWaves->{$_} = $fluors->{$_}->[0];
	}

	return $fluorsWaves;
}

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

