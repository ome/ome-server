<?xml version = "1.0" encoding = "UTF-8"?>
<xsl:transform xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" xmlns:OME = "http://www.openmicroscopy.org/XMLschemas/OME/RC6/ome.xsd" xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance">
	<xsl:template match = "OME:OME">
		<xsl:element name = "OME">
			<xsl:attribute name = "schemaLocation">
				<xsl:value-of select = "@xsi:schemaLocation"/>
			</xsl:attribute>
			<!-- Copy DocumentGroup in the original document -->
			
			<!-- Need to copy STD and AML also -->
			<xsl:copy-of select = "OME:DocumentGroup"/>
			<!-- Deal with the hierarchy -->
			<xsl:apply-templates select = "OME:Project"/>
			<xsl:apply-templates select = "OME:Dataset"/>
			<xsl:apply-templates select = "OME:Image"/>
			<!-- Deal with the global custom attributes -->
			<xsl:element name = "CustomAttributes">
				<!-- Copy descendants of CustomAttributes in the original document -->
				<xsl:copy-of select = "OME:CustomAttributes/*"/>
				<!-- Apply templates to children of OME excluding CustomAttributes and DocumentGroup (need to exclude STD and AML also) NOT TESTED! -->
				
				<!--xsl:apply-templates select = "*[name() != 'CustomAttributes'][name() != 'DocumentGroup']" mode = "Convert2CA"/-->
				<xsl:apply-templates select = "OME:Experimenter"/>
				<xsl:apply-templates select = "OME:Group"/>
				<xsl:apply-templates select = "OME:Experiment"/>
				<xsl:apply-templates select = "OME:Instrument"/>
				<xsl:apply-templates select = "OME:Plate"/>
				<xsl:apply-templates select = "OME:Screen"/>
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<!-- Project -->
	<xsl:template match = "OME:Project">
		<xsl:element name = "Project">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@ProjectID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "Description">
				<xsl:value-of select = "OME:Description"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:ExperimenterRef" mode = "MakeRefs"/>
			<xsl:apply-templates select = "OME:GroupRef" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- Dataset -->
	<xsl:template match = "OME:Dataset">
		<xsl:element name = "Dataset">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@DatasetID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "Description">
				<xsl:value-of select = "OME:Description"/>
			</xsl:attribute>
			<xsl:attribute name = "Locked">
				<xsl:value-of select = "@Locked"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:ExperimenterRef" mode = "MakeRefs"/>
			<xsl:apply-templates select = "OME:GroupRef" mode = "MakeRefs"/>
			<xsl:apply-templates select = "OME:ProjectRef" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- Image and the required Dimensions Image attribute -->
	<xsl:template match = "OME:Image">
		<xsl:element name = "Image">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@ImageID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "CreationDate">
				<xsl:value-of select = "OME:CreationDate"/>
			</xsl:attribute>
			<xsl:attribute name = "Description">
				<xsl:value-of select = "OME:Description"/>
			</xsl:attribute>
			<xsl:element name = "CustomAttributes">
				<xsl:element name = "Dimensions">
					<xsl:attribute name = "SizeX">
						<xsl:value-of select = "@SizeX"/>
					</xsl:attribute>
					<xsl:attribute name = "SizeY">
						<xsl:value-of select = "@SizeY"/>
					</xsl:attribute>
					<xsl:attribute name = "SizeZ">
						<xsl:value-of select = "@SizeZ"/>
					</xsl:attribute>
					<xsl:attribute name = "SizeC">
						<xsl:value-of select = "@NumChannels"/>
					</xsl:attribute>
					<xsl:attribute name = "SizeT">
						<xsl:value-of select = "@NumTimes"/>
					</xsl:attribute>
					<xsl:attribute name = "BitsPerPixel">
						<xsl:call-template name = "PixelType2BitsPerPixel">
							<xsl:with-param name = "PixelType">
								<xsl:value-of select = "OME:Pixels/@PixelType"/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:attribute>
					<xsl:attribute name = "PixelSizeX">
						<xsl:value-of select = "@PixelSizeX"/>
					</xsl:attribute>
					<xsl:attribute name = "PixelSizeY">
						<xsl:value-of select = "@PixelSizeY"/>
					</xsl:attribute>
					<xsl:attribute name = "PixelSizeZ">
						<xsl:value-of select = "@PixelSizeZ"/>
					</xsl:attribute>
					<xsl:attribute name = "PixelSizeC">
						<xsl:value-of select = "@WaveIncrement"/>
					</xsl:attribute>
					<xsl:attribute name = "PixelSizeT">
						<xsl:value-of select = "@TimeIncrement"/>
					</xsl:attribute>
				</xsl:element>
				<xsl:apply-templates select = "OME:ExperimentRef"/>
				<xsl:apply-templates select = "OME:GroupRef"/>
				<xsl:apply-templates select = "OME:DatasetRef"/>
				<xsl:apply-templates select = "OME:InstrumentRef"/>
				<xsl:apply-templates select = "OME:ImagingEnvironment"/>
				<xsl:apply-templates select = "OME:Thumbnail"/>
				<xsl:apply-templates select = "OME:ChannelInfo"/>
				<xsl:apply-templates select = "OME:DisplayOptions"/>
				<xsl:apply-templates select = "OME:StageLabel"/>
				<xsl:apply-templates select = "OME:PlateRef"/>
				<xsl:apply-templates select = "OME:Pixels"/>
				<xsl:copy-of select = "OME:Feature"/>
				<xsl:copy-of select = "OME:CustomAttributes"/>
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<!-- Image attributes -->

	<!-- ExperimentRef -->
	<xsl:template match = "OME:Image/OME:ExperimentRef">
		<xsl:element name = "ImageExperiment">
			<xsl:apply-templates select = "." mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- GroupRef -->
	<xsl:template match = "OME:Image/OME:GroupRef">
		<xsl:element name = "ImageGroup">
			<xsl:apply-templates select = "." mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- InstrumentRef -->
	<xsl:template match = "OME:Image/OME:InstrumentRef">
		<xsl:element name = "ImageInstrument">
			<xsl:apply-templates select = "." mode = "MakeRefs"/>
			<xsl:apply-templates select = "." mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>Objective</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>

	<!-- ImagingEnvironment -->
	<xsl:template match = "OME:Image/OME:ImagingEnvironment">
		<xsl:apply-templates select = "." mode = "E2A-Refs"/>
	</xsl:template>

	<!-- Thumbnail -->
	<xsl:template match = "OME:Image/OME:Thumbnail">
		<xsl:apply-templates select = "." mode = "E2A-Refs"/>
	</xsl:template>

	<!-- ChannelComponent -->
	<xsl:template match = "OME:ChannelInfo/OME:ChannelComponent">
		<xsl:element name = "ChannelComponent">
			<xsl:attribute name = "Index">
				<xsl:value-of select = "@Index"/>
			</xsl:attribute>
			<xsl:attribute name = "ColorDomain">
				<xsl:value-of select = "@ColorDomain"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>LogicalChannel</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ID">
					<xsl:value-of select = "generate-id(..)"/>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>

	<!-- ChannelInfo -->
	<xsl:template match = "OME:Image/OME:ChannelInfo">
		<xsl:element name = "LogicalChannel">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "generate-id()"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "SamplesPerPixel">
				<xsl:value-of select = "@SamplesPerPixel"/>
			</xsl:attribute>
			<xsl:attribute name = "LightAttenuation">
				<!--xsl:value-of select="descendant::LightSourceRef[not(@::AuxTechnique)/@Attenuation]"/-->
				<xsl:value-of select = "OME:LightSourceRef/@Attenuation"/>
			</xsl:attribute>
			<xsl:attribute name = "LightWavelength">
				<xsl:value-of select = "OME:LightSourceRef/@Wavelength"/>
			</xsl:attribute>
			<xsl:attribute name = "DetectorOffset">
				<xsl:value-of select = "OME:DetectorRef/@Offset"/>
			</xsl:attribute>
			<xsl:attribute name = "DetectorOffset">
				<xsl:value-of select = "OME:DetectorRef/@Gain"/>
			</xsl:attribute>
			<xsl:attribute name = "IlluminationType">
				<xsl:value-of select = "@IlluminationType"/>
			</xsl:attribute>
			<xsl:attribute name = "PinholeSize">
				<xsl:value-of select = "@PinholeSize"/>
			</xsl:attribute>
			<xsl:attribute name = "PhotometricInterpretation">
				<xsl:value-of select = "@PhotometricInterpretation"/>
			</xsl:attribute>
			<xsl:attribute name = "Mode">
				<xsl:value-of select = "@Mode"/>
			</xsl:attribute>
			<xsl:attribute name = "ContrastMethod">
				<xsl:value-of select = "@ContrastMethod"/>
			</xsl:attribute>
			<xsl:attribute name = "AuxLightAttenuation">
				<xsl:value-of select = "OME:AuxLightSourceRef/@Attenuation"/>
			</xsl:attribute>
			<xsl:attribute name = "AuxTechnique">
				<xsl:value-of select = "OME:AuxLightSourceRef/@AuxTechnique"/>
			</xsl:attribute>
			<xsl:attribute name = "AuxLightWavelength">
				<xsl:value-of select = "OME:AuxLightSourceRef/@Wavelength"/>
			</xsl:attribute>
			<xsl:attribute name = "ExcitationWavelength">
				<xsl:value-of select = "@ExWave"/>
			</xsl:attribute>
			<xsl:attribute name = "EmissionWavelength">
				<xsl:value-of select = "@EmWave"/>
			</xsl:attribute>
			<xsl:attribute name = "Fluor">
				<xsl:value-of select = "@Fluor"/>
			</xsl:attribute>
			<xsl:attribute name = "NDFilter">
				<xsl:value-of select = "@NDfilter"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:LightSourceRef" mode = "MakeRefs"/>
			<xsl:apply-templates select = "OME:AuxLightSourceRef" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>AuxLightSource</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ReferenceTo">
					<xsl:text>LightSourceID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select = "OME:OTFRef" mode = "MakeRefs"/>
			<xsl:apply-templates select = "OME:DetectorRef" mode = "MakeRefs"/>
			<xsl:apply-templates select = "OME:FilterRef" mode = "MakeRefs"/>
		</xsl:element>
		<xsl:apply-templates select = "OME:ChannelComponent"/>
	</xsl:template>

	<!-- DisplayOptions - DisplayChannels -->
	<xsl:template match = "OME:DisplayOptions/*" mode = "MakeDisplayChannel">
		<xsl:element name = "DisplayChannel">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "generate-id()"/>
			</xsl:attribute>
			<xsl:attribute name = "ChannelNumber">
				<xsl:value-of select = "@ChannelNumber"/>
			</xsl:attribute>
			<xsl:attribute name = "BlackLevel">
				<xsl:value-of select = "@BlackLevel"/>
			</xsl:attribute>
			<xsl:attribute name = "WhiteLevel">
				<xsl:value-of select = "@WhiteLevel"/>
			</xsl:attribute>
			<xsl:attribute name = "Gamma">
				<xsl:value-of select = "@Gamma"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<!-- DisplayOptions -->
	<xsl:template match = "OME:DisplayOptions">
		<xsl:element name = "DisplayOptions">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "generate-id()"/>
			</xsl:attribute>
			<xsl:attribute name = "Zoom">
				<xsl:value-of select = "@Zoom"/>
			</xsl:attribute>
			<xsl:attribute name = "ColorMap">
				<xsl:value-of select = "OME:GreyChannel/@ColorMap"/>
			</xsl:attribute>
			<xsl:attribute name = "ZStart">
				<xsl:value-of select = "OME:Projection/@Zstart"/>
			</xsl:attribute>
			<xsl:attribute name = "ZStop">
				<xsl:value-of select = "OME:Projection/@Zstop"/>
			</xsl:attribute>
			<xsl:attribute name = "TStart">
				<xsl:value-of select = "OME:Time/@Tstart"/>
			</xsl:attribute>
			<xsl:attribute name = "TStop">
				<xsl:value-of select = "OME:Time/@Tstop"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:RedChannel" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>RedChannel</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ID">
					<xsl:value-of select = "generate-id(OME:RedChannel)"/>
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select = "OME:GreenChannel" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>GreenChannel</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ID">
					<xsl:value-of select = "generate-id(OME:GreenChannel)"/>
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select = "OME:BlueChannel" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>BlueChannel</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ID">
					<xsl:value-of select = "generate-id(OME:BlueChannel)"/>
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select = "OME:GreyChannel" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>GreyChannel</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ID">
					<xsl:value-of select = "generate-id(OME:GreyChannel)"/>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
		<xsl:apply-templates select = "OME:RedChannel" mode = "MakeDisplayChannel"/>
		<xsl:apply-templates select = "OME:GreenChannel" mode = "MakeDisplayChannel"/>
		<xsl:apply-templates select = "OME:BlueChannel" mode = "MakeDisplayChannel"/>
		<xsl:apply-templates select = "OME:GreyChannel" mode = "MakeDisplayChannel"/>
		<xsl:apply-templates select = "OME:ROI"/>
	</xsl:template>

	<!-- DisplayOptions - ROI -->
	<xsl:template match = "OME:DisplayOptions/OME:ROI">
		<xsl:element name = "DisplayROI">
			<xsl:attribute name = "X0">
				<xsl:value-of select = "@X0"/>
			</xsl:attribute>
			<xsl:attribute name = "Y0">
				<xsl:value-of select = "@Y0"/>
			</xsl:attribute>
			<xsl:attribute name = "Z0">
				<xsl:value-of select = "@Z0"/>
			</xsl:attribute>
			<xsl:attribute name = "X1">
				<xsl:value-of select = "@X1"/>
			</xsl:attribute>
			<xsl:attribute name = "Y1">
				<xsl:value-of select = "@Y1"/>
			</xsl:attribute>
			<xsl:attribute name = "Z1">
				<xsl:value-of select = "@Z1"/>
			</xsl:attribute>
			<xsl:attribute name = "T0">
				<xsl:value-of select = "@T0"/>
			</xsl:attribute>
			<xsl:attribute name = "T1">
				<xsl:value-of select = "@T1"/>
			</xsl:attribute>
			<xsl:apply-templates select = ".." mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>DisplayOptions</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ID">
					<xsl:value-of select = "generate-id(..)"/>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>

	<!-- PlateRef -->
	<xsl:template match = "OME:Image/OME:PlateRef">
		<xsl:element name = "ImagePlate">
			<xsl:attribute name = "Well">
				<xsl:value-of select = "@Well"/>
			</xsl:attribute>
			<xsl:attribute name = "Sample">
				<xsl:value-of select = "@Sample"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- StageLabel -->
	<xsl:template match = "OME:StageLabel">
		<xsl:element name = "StageLabel">
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "X">
				<xsl:value-of select = "@X"/>
			</xsl:attribute>
			<xsl:attribute name = "Y">
				<xsl:value-of select = "@Y"/>
			</xsl:attribute>
			<xsl:attribute name = "Z">
				<xsl:value-of select = "@Z"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<!-- Pixels -->
	<!--xsl:template match = "OME:Pixels">
		<xsl:element name = "Pixels">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@PixelsID"/>
			</xsl:attribute>
			<xsl:attribute name = "Method">
				<xsl:value-of select = "OME:DerivedFrom/@Method"/>
			</xsl:attribute>
			<xsl:attribute name = "DimensionOrder">
				<xsl:value-of select = "@DimensionOrder"/>
			</xsl:attribute>
			<xsl:attribute name = "PixelType">
				<xsl:value-of select = "@PixelType"/>
			</xsl:attribute>
			<xsl:attribute name = "BigEndian">
				<xsl:value-of select = "@BigEndian"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:DerivedFrom" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>DerivedFrom</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ReferenceTo">
					<xsl:text>PixelsID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template-->


	<!--

		Global Attributes

	-->


	<!-- Experimenter -->
	<xsl:template match = "OME:Experimenter">
		<xsl:element name = "Experimenter">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@ExperimenterID"/>
			</xsl:attribute>
			<xsl:attribute name = "FirstName">
				<xsl:value-of select = "OME:FirstName"/>
			</xsl:attribute>
			<xsl:attribute name = "LastName">
				<xsl:value-of select = "OME:LastName"/>
			</xsl:attribute>
			<xsl:attribute name = "Email">
				<xsl:value-of select = "OME:email"/>
			</xsl:attribute>
			<xsl:attribute name = "Institution">
				<xsl:value-of select = "OME:Institution"/>
			</xsl:attribute>
			<xsl:attribute name = "OMEname">
				<xsl:value-of select = "OME:OMEname"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:GroupRef" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- Group -->
	<xsl:template match = "OME:Group">
		<xsl:element name = "Group">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@GroupID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:Leader" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>Leader</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ReferenceTo">
					<xsl:text>ExperimenterID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select = "OME:Contact" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>Contact</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ReferenceTo">
					<xsl:text>ExperimenterID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>

	<!-- Experiment -->
	<xsl:template match = "OME:Experiment">
		<xsl:element name = "Experiment">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@ExperimentID"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:attribute name = "Description">
				<xsl:value-of select = "OME:Description"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:ExperimenterRef" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument -->
	<xsl:template match = "OME:Instrument">
		<xsl:element name = "Instrument">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@InstrumentID"/>
			</xsl:attribute>
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "OME:Microscope/@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "OME:Microscope/@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "SerialNumber">
				<xsl:value-of select = "OME:Microscope/@SerialNumber"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "OME:Microscope/@Type"/>
			</xsl:attribute>
		</xsl:element>
		<xsl:apply-templates select = "OME:LightSource"/>
		<xsl:apply-templates select = "OME:Detector"/>
		<xsl:apply-templates select = "OME:Objective"/>
		<xsl:apply-templates select = "OME:Filter"/>
		<xsl:apply-templates select = "OME:OTF"/>
	</xsl:template>

	<!-- Instrument - LightSource -->
	<xsl:template match = "OME:Instrument/OME:LightSource">
		<xsl:element name = "LightSource">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@LightSourceID"/>
			</xsl:attribute>
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "SerialNumber">
				<xsl:value-of select = "@SerialNumber"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
		<xsl:apply-templates select = "OME:Laser"/>
		<xsl:apply-templates select = "OME:Filament"/>
		<xsl:apply-templates select = "OME:Arc"/>
	</xsl:template>

	<!-- LightSource - Laser -->
	<xsl:template match = "OME:LightSource/OME:Laser">
		<xsl:element name = "Laser">
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:attribute name = "Medium">
				<xsl:value-of select = "@Medium"/>
			</xsl:attribute>
			<xsl:attribute name = "Wavelength">
				<xsl:value-of select = "@Wavelength"/>
			</xsl:attribute>
			<xsl:attribute name = "FrequencyDoubled">
				<xsl:value-of select = "@FrequencyDoubled"/>
			</xsl:attribute>
			<xsl:attribute name = "Tunable">
				<xsl:value-of select = "@Tunable"/>
			</xsl:attribute>
			<xsl:attribute name = "Pulse">
				<xsl:value-of select = "@Pulse"/>
			</xsl:attribute>
			<xsl:attribute name = "Power">
				<xsl:value-of select = "@Power"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
			<xsl:apply-templates select = "OME:Pump" mode = "MakeRefs">
				<xsl:with-param name = "Name">
					<xsl:text>Pump</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "ReferenceTo">
					<xsl:text>LightSourceID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>

	<!-- LightSource - Filament -->
	<xsl:template match = "OME:LightSource/OME:Filament">
		<xsl:element name = "Filament">
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:attribute name = "Power">
				<xsl:value-of select = "@Power"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- LightSource - Arc -->
	<xsl:template match = "OME:LightSource/OME:Arc">
		<xsl:element name = "Arc">
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:attribute name = "Power">
				<xsl:value-of select = "@Power"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument - Dectector -->
	<xsl:template match = "OME:Instrument/OME:Detector">
		<xsl:element name = "Detector">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@DetectorID"/>
			</xsl:attribute>
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "SerialNumber">
				<xsl:value-of select = "@SerialNumber"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:attribute name = "Gain">
				<xsl:value-of select = "@Gain"/>
			</xsl:attribute>
			<xsl:attribute name = "Voltage">
				<xsl:value-of select = "@Voltage"/>
			</xsl:attribute>
			<xsl:attribute name = "Offset">
				<xsl:value-of select = "@Offset"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument - Objective -->
	<xsl:template match = "OME:Instrument/OME:Objective">
		<xsl:element name = "Objective">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@ObjectiveID"/>
			</xsl:attribute>
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "SerialNumber">
				<xsl:value-of select = "@SerialNumber"/>
			</xsl:attribute>
			<xsl:attribute name = "LensNA">
				<xsl:value-of select = "OME:LensNA"/>
			</xsl:attribute>
			<xsl:attribute name = "Magnification">
				<xsl:value-of select = "OME:Magnification"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument - Filter -->
	<xsl:template match = "OME:Instrument/OME:Filter">
		<xsl:element name = "Filter">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@FilterID"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
		<xsl:apply-templates select = "OME:ExFilter"/>
		<xsl:apply-templates select = "OME:Dichroic"/>
		<xsl:apply-templates select = "OME:EmFilter"/>
		<xsl:apply-templates select = "OME:FilterSet"/>
	</xsl:template>

	<!-- Instrument - Filter - ExFilter -->
	<xsl:template match = "OME:Instrument/OME:Filter/OME:ExFilter">
		<xsl:element name = "ExcitationFilter">
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "LotNumber">
				<xsl:value-of select = "@LotNumber"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument - Filter - Dichroic -->
	<xsl:template match = "OME:Instrument/OME:Filter/OME:Dichroic">
		<xsl:element name = "Dichroic">
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "LotNumber">
				<xsl:value-of select = "@LotNumber"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument - Filter - EmFilter -->
	<xsl:template match = "OME:Instrument/OME:Filter/OME:EmFilter">
		<xsl:element name = "EmissionFilter">
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "LotNumber">
				<xsl:value-of select = "@LotNumber"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument - Filter - FilterSet -->
	<xsl:template match = "OME:Instrument/OME:Filter/OME:FilterSet">
		<xsl:element name = "FilterSet">
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "LotNumber">
				<xsl:value-of select = "@LotNumber"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
		</xsl:element>
	</xsl:template>

	<!-- Instrument - OTF -->
	<xsl:template match = "OME:Instrument/OME:OTF">
		<xsl:element name = "OpticalTransferFunction">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@OTFID"/>
			</xsl:attribute>
			<xsl:attribute name = "SizeX">
				<xsl:value-of select = "@SizeX"/>
			</xsl:attribute>
			<xsl:attribute name = "SizeY">
				<xsl:value-of select = "@SizeY"/>
			</xsl:attribute>
			<xsl:attribute name = "PixelType">
				<xsl:value-of select = "@PixelType"/>
			</xsl:attribute>
			<xsl:attribute name = "OpticalAxisAverage">
				<xsl:value-of select = "@OpticalAxisAvrg"/>
			</xsl:attribute>
			<xsl:apply-templates select = "." mode = "MakeParentRef"/>
			<xsl:apply-templates select = "OME:ObjectiveRef" mode = "MakeRefs"/>
			<xsl:apply-templates select = "OME:FilterRef" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!-- Screen -->
	<xsl:template match = "OME:Screen">
		<xsl:element name = "Screen">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@ScreenID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "Description">
				<xsl:value-of select = "OME:Description"/>
			</xsl:attribute>
			<xsl:attribute name = "ExternalReference">
				<xsl:value-of select = "@ExternRef"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<!-- Plate -->
	<xsl:template match = "OME:Plate">
		<xsl:element name = "Plate">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@PlateID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "ExternalReference">
				<xsl:value-of select = "@ExternRef"/>
			</xsl:attribute>
			<xsl:apply-templates select = "OME:ScreenRef" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!--

		Utility Templates

	-->

	<!--
		A general template to convert child elements and attributes to attributes
		and also deal with references
	-->
	<xsl:template match = "*" mode = "E2A-Refs">
		<xsl:element name = "{name()}">
			<xsl:apply-templates select = "." mode = "Element2Attributes"/>
			<xsl:apply-templates select = "*[substring(name(),string-length(name())-2,3) = 'Ref']" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template>

	<!--
		A utility template to convert child elements and attributes to attributes.
		Does not deal with grand-child elements correctly
	-->
	<xsl:template match = "*" mode = "Element2Attributes">
		<xsl:for-each select = "@*">
			<xsl:choose>
				<xsl:when test = "substring(name(),string-length(name())-1,2) = 'ID'">
					<xsl:attribute name = "ID">
						<xsl:value-of select = "../@*[name() = concat(name(..),'ID')]"/>
					</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name = "{name()}">
						<xsl:value-of select = "."/>
					</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<xsl:for-each select = "*[name() != 'CustomAttributes'][substring(name(),string-length(name())-2,3) != 'Ref']">
			<xsl:attribute name = "{name()}">
				<xsl:value-of select = "."/>
			</xsl:attribute>
		</xsl:for-each>
	</xsl:template>
	
	<!-- A utility template to make a reference to a parent element -->
	<xsl:template match = "*" mode = "MakeParentRef">
		<xsl:apply-templates select = ".." mode = "MakeRefs">
			<xsl:with-param name = "Name">
				<xsl:value-of select = "name(..)"/>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:template>

	<!-- A utility template to make references -->
	<xsl:template match = "*" mode = "MakeRefs">
	<!--
		By default, $Name is composed of the element name minus its last three letters
		(i.e. ExperimenterRef element will set $Name to 'Experimenter'.
		By default, $ReferenceTo is composed of the $Name  with 'ID' tacked on to the end.
	-->
		<xsl:param name = "Name" select = "substring(name(),1,string-length(name())-3)"/>
		<xsl:param name = "ReferenceTo" select = "concat($Name,'ID')"/>
		<xsl:param name = "ID" select = "@*[name() = $ReferenceTo]"/>
		<xsl:element name = "Ref">
			<xsl:attribute name = "Name">
				<xsl:value-of select = "$Name"/>
			</xsl:attribute>
			<xsl:attribute name = "ID">
				<xsl:value-of select = "$ID"/>
			</xsl:attribute>
			<xsl:if test = "@DocumentID">
				<xsl:attribute name = "DocID">
					<xsl:value-of select = "@DocumentID"/>
				</xsl:attribute>
			</xsl:if>
		</xsl:element>
	</xsl:template>

	<!-- Convert PixelTypes to BitsPerPixel -->
	<xsl:template name = "PixelType2BitsPerPixel">
		<xsl:param name = "PixelType" select = "string()"/>
		<xsl:choose>
			<xsl:when test = "$PixelType = 'bit'">
				<xsl:text>1</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'int8'">
				<xsl:text>8</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'int16'">
				<xsl:text>16</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'int32'">
				<xsl:text>32</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'Uint8'">
				<xsl:text>8</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'Uint16'">
				<xsl:text>16</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'Uint32'">
				<xsl:text>32</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'float'">
				<xsl:text>32</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'double'">
				<xsl:text>64</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'complex'">
				<xsl:text>64</xsl:text>
			</xsl:when>
			<xsl:when test = "$PixelType = 'double-complex'">
				<xsl:text>128</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- This just prints out the names of whatever nodes it gets -->
	<xsl:template match = "*" mode = "print">
		<xsl:value-of select = "name()"/>
	</xsl:template>

	<!-- This copies whatever nodes it gets -->
	<xsl:template match = "*" mode = "copy">
		<xsl:copy/>
	</xsl:template>
	<xsl:template match = "*"/>
</xsl:transform>