<?xml version = "1.0" encoding = "UTF-8"?>
<xsl:transform
	xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0"
	xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
	xmlns:CA = "http://www.openmicroscopy.org/XMLschemas/CA/RC1/CA.xsd"
	xmlns:Bin = "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd"
	xmlns:STD = "http://www.openmicroscopy.org/XMLschemas/STD/RC1/STD.xsd"
	xmlns = "http://www.openmicroscopy.org/XMLschemas/OME/RC6/ome.xsd">
	<xsl:template match = "CA:OME">
		<xsl:element name = "OME">
			<xsl:attribute name = "xsi:schemaLocation">
				<xsl:value-of select = "@xsi:schemaLocation"/>
			</xsl:attribute>
			<xsl:apply-templates select = "CA:DocumentGroup"/>
			<xsl:apply-templates select = "CA:Project"/>
			<xsl:apply-templates select = "CA:Dataset"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:Experiment"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:Plate"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:Screen"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:Experimenter"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:Group"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:Instrument"/>
			<xsl:apply-templates select = "CA:Image"/>
		</xsl:element>
	</xsl:template>
	<!--
		DocumentGroup 
		This is merely a copy, but without messing with the namespace attribute.
	-->
	<xsl:template match = "CA:DocumentGroup">
		<xsl:element name = "DocumentGroup">
			<xsl:apply-templates select = "CA:Include"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Include">
		<xsl:element name = "Include">
			<xsl:attribute name = "DocumentID">
				<xsl:value-of select = "@DocumentID"/>
			</xsl:attribute>
			<xsl:attribute name = "href">
				<xsl:value-of select = "@href"/>
			</xsl:attribute>
			<xsl:attribute name = "SHA1">
				<xsl:value-of select = "@SHA1"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- This is a general template for the Description elements -->
	<xsl:template match = "@Description">
		<xsl:if test = "string-length(.) > 0">
			<xsl:element name = "{name()}">
				<xsl:value-of select = "."/>
			</xsl:element>
		</xsl:if>
	</xsl:template>
	<!-- This is a general template for attributes that become optional elements (check for string length of the attribute value) -->
	<xsl:template match = "@*" mode = "Attribute2OptionalElement">
		<xsl:if test = "string-length(.) > 0">
			<xsl:element name = "{name()}">
				<xsl:value-of select = "."/>
			</xsl:element>
		</xsl:if>
	</xsl:template>
	<!-- This is a general template for attributes that become optional attributes (check for string length of the attribute value) -->
	<xsl:template match = "@*" mode = "Attribute2OptionalAttribute">
		<xsl:if test = "string-length(.) > 0">
			<xsl:attribute name = "{name()}">
				<xsl:value-of select = "."/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	<!-- General template for making a reference -->
	<xsl:template match = "CA:Ref" mode = "MakeOMEref">
		<xsl:param name = "RefName" select = "concat(string(@Name),'Ref')"/>
		<xsl:param name = "RefIDName" select = "concat(string(@Name),'ID')"/>
		<xsl:element name = "{$RefName}">
			<xsl:if test = "@DocID">
				<xsl:attribute name = "DocumentID">
					<xsl:value-of select = "@DocID"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:attribute name = "{$RefIDName}">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- Specific sections of the OME Schema -->
	<xsl:template match = "CA:Project">
		<xsl:element name = "Project">
			<xsl:attribute name = "ProjectID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Description" mode = "Attribute2OptionalElement"/>
			<xsl:apply-templates select = "CA:Ref" mode = "MakeOMEref"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Dataset">
		<xsl:element name = "Dataset">
			<xsl:attribute name = "DatasetID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "Locked">
				<xsl:value-of select = "@Locked"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Description" mode = "Attribute2OptionalElement"/>
			<xsl:apply-templates select = "CA:Ref" mode = "MakeOMEref"/>
			<xsl:copy-of select = "CA:CustomAttributes"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Image">
		<xsl:variable name = "ImageID" select = "@ID"/>
		<xsl:element name = "Image">
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "ImageID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "SizeX">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@SizeX"/>
			</xsl:attribute>
			<xsl:attribute name = "SizeY">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@SizeY"/>
			</xsl:attribute>
			<xsl:attribute name = "SizeZ">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@SizeZ"/>
			</xsl:attribute>
			<xsl:attribute name = "NumChannels">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@SizeC"/>
			</xsl:attribute>
			<xsl:attribute name = "NumTimes">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@SizeT"/>
			</xsl:attribute>
			<xsl:attribute name = "PixelSizeX">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@PixelSizeX"/>
			</xsl:attribute>
			<xsl:attribute name = "PixelSizeY">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@PixelSizeY"/>
			</xsl:attribute>
			<xsl:attribute name = "PixelSizeZ">
				<xsl:value-of select = "CA:CustomAttributes/CA:Dimensions/@PixelSizeZ"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@CreationDate"/>
			<xsl:apply-templates select = "@Description" mode = "Attribute2OptionalElement"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:ImageExperiment/CA:Ref" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:ImageGroup/CA:Ref" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "CA:Ref [@Name='Dataset']" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:ImageInstrument"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:ImagingEnvironment"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:Thumbnail"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:LogicalChannel"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:DisplayOptions"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:StageLabel"/>
			<xsl:apply-templates select = "CA:CustomAttributes/CA:ImagePlate"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "@CreationDate">
		<xsl:element name = "CreationDate">
			<xsl:value-of select = "."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Experiment">
		<xsl:element name = "Experiment">
			<xsl:attribute name = "ExperimentID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Description" mode = "Attribute2OptionalElement"/>
			<xsl:apply-templates select = "CA:Ref" mode = "MakeOMEref"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Plate">
		<xsl:element name = "Plate">
			<xsl:attribute name = "PlateID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:if test = "string-length(@ExternalReference) > 0">
				<xsl:attribute name = "ExternRef">
					<xsl:value-of select = "@ExternalReference"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select = "CA:Ref" mode = "MakeOMEref"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Screen">
		<xsl:element name = "Screen">
			<xsl:attribute name = "ScreenID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:if test = "string-length(@ExternalReference) > 0">
				<xsl:attribute name = "ExternRef">
					<xsl:value-of select = "@ExternalReference"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select = "@Description" mode = "Attribute2OptionalElement"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Experimenter">
		<xsl:element name = "Experimenter">
			<xsl:attribute name = "ExperimenterID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:element name = "FirstName">
				<xsl:value-of select = "@FirstName"/>
			</xsl:element>
			<xsl:element name = "LastName">
				<xsl:value-of select = "@LastName"/>
			</xsl:element>
			<xsl:element name = "Email">
				<xsl:value-of select = "@Email"/>
			</xsl:element>
			<xsl:element name = "Institution">
				<xsl:value-of select = "@Institution"/>
			</xsl:element>
			<xsl:element name = "OMEName">
				<xsl:value-of select = "@OMEName"/>
			</xsl:element>
			<xsl:apply-templates select = "CA:Ref" mode = "MakeOMEref"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Group">
		<xsl:element name = "Group">
			<xsl:attribute name = "GroupID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:apply-templates select = "CA:Ref [@Name='Leader']" mode = "MakeOMEref">
				<xsl:with-param name = "RefName">
					<xsl:text>Leader</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "RefIDName">
					<xsl:text>ExperimenterID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select = "CA:Ref [@Name='Contact']" mode = "MakeOMEref">
				<xsl:with-param name = "RefName">
					<xsl:text>Contact</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "RefIDName">
					<xsl:text>ExperimenterID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Instrument">
		<xsl:variable name = "InstrumentID" select = "@ID"/>
		<xsl:element name = "Instrument">
			<xsl:attribute name = "InstrumentID">
				<xsl:value-of select = "$InstrumentID"/>
			</xsl:attribute>
			<xsl:element name = "Microscope">
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
			</xsl:element>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:LightSource [CA:Ref/@ID=$InstrumentID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:Detector [CA:Ref/@ID=$InstrumentID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:Objective [CA:Ref/@ID=$InstrumentID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:Filter [CA:Ref/@ID=$InstrumentID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:OpticalTransferFunction [CA:Ref/@ID=$InstrumentID]"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:LightSource">
		<xsl:variable name = "LightSourceID" select = "@ID"/>
		<xsl:element name = "LightSource">
			<xsl:attribute name = "LightSourceID">
				<xsl:value-of select = "$LightSourceID"/>
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
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:Laser [CA:Ref/@ID=$LightSourceID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:Filament [CA:Ref/@ID=$LightSourceID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:Arc [CA:Ref/@ID=$LightSourceID]"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Laser">
		<xsl:element name = "Laser">
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:attribute name = "Medium">
				<xsl:value-of select = "@Medium"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Wavelength" mode = "Attribute2OptionalAttribute"/>
			<xsl:apply-templates select = "@FrequencyDoubled" mode = "Attribute2OptionalAttribute"/>
			<xsl:apply-templates select = "@Tunable" mode = "Attribute2OptionalAttribute"/>
			<xsl:apply-templates select = "@Pulse" mode = "Attribute2OptionalAttribute"/>
			<xsl:apply-templates select = "@Power" mode = "Attribute2OptionalAttribute"/>
			<xsl:apply-templates select = "CA:Ref [@Name='Pump']" mode = "MakeOMEref">
				<xsl:with-param name = "RefName">
					<xsl:text>Pump</xsl:text>
				</xsl:with-param>
				<xsl:with-param name = "RefIDName">
					<xsl:text>LightSourceID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Filament">
		<xsl:element name = "Filament">
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Power" mode = "Attribute2OptionalAttribute"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Arc">
		<xsl:element name = "Arc">
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Power" mode = "Attribute2OptionalAttribute"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Detector">
		<xsl:element name = "Detector">
			<xsl:attribute name = "DetectorID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
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
			<xsl:apply-templates select = "@Gain" mode = "Attribute2OptionalAttribute"/>
			<xsl:apply-templates select = "@Voltage" mode = "Attribute2OptionalAttribute"/>
			<xsl:apply-templates select = "@Offset" mode = "Attribute2OptionalAttribute"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Objective">
		<xsl:element name = "Objective">
			<xsl:attribute name = "ObjectiveID">
				<xsl:value-of select = "@ID"/>
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
			<xsl:apply-templates select = "@LensNA" mode = "Attribute2OptionalElement"/>
			<xsl:apply-templates select = "@Magnification" mode = "Attribute2OptionalElement"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Filter">
		<xsl:variable name = "FilterID" select = "@ID"/>
		<xsl:element name = "Filter">
			<xsl:attribute name = "FilterID">
				<xsl:value-of select = "$FilterID"/>
			</xsl:attribute>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:FilterSet [CA:Ref/@ID=$FilterID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:ExcitationFilter [CA:Ref/@ID=$FilterID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:EmissionFilter [CA:Ref/@ID=$FilterID]"/>
			<xsl:apply-templates select = "/CA:OME/CA:CustomAttributes/CA:Dichroic [CA:Ref/@ID=$FilterID]"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:FilterSet">
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
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:ExcitationFilter">
		<xsl:element name = "ExFilter">
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "LotNumber">
				<xsl:value-of select = "@LotNumber"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Type" mode = "Attribute2OptionalAttribute"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:EmissionFilter">
		<xsl:element name = "EmFilter">
			<xsl:attribute name = "Manufacturer">
				<xsl:value-of select = "@Manufacturer"/>
			</xsl:attribute>
			<xsl:attribute name = "Model">
				<xsl:value-of select = "@Model"/>
			</xsl:attribute>
			<xsl:attribute name = "LotNumber">
				<xsl:value-of select = "@LotNumber"/>
			</xsl:attribute>
			<xsl:apply-templates select = "@Type" mode = "Attribute2OptionalAttribute"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Dichroic">
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
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:OpticalTransferFunction">
		<xsl:element name = "OTF">
			<xsl:attribute name = "OTFID">
				<xsl:value-of select = "@ID"/>
			</xsl:attribute>
			<xsl:attribute name = "PixelType">
				<xsl:value-of select = "@PixelType"/>
			</xsl:attribute>
			<xsl:attribute name = "OpticalAxisAvrg">
				<xsl:value-of select = "@OpticalAxisAverage"/>
			</xsl:attribute>
			<xsl:attribute name = "SizeX">
				<xsl:value-of select = "@SizeX"/>
			</xsl:attribute>
			<xsl:attribute name = "SizeY">
				<xsl:value-of select = "@SizeY"/>
			</xsl:attribute>
			<xsl:apply-templates select = "CA:Ref [@Name='Objective']" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "CA:Ref [@Name='Filter']" mode = "MakeOMEref"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:ImagingEnvironment">
		<xsl:element name = "ImagingEnvironment">
			<xsl:attribute name = "Temperature">
				<xsl:value-of select = "@Temperature"/>
			</xsl:attribute>
			<xsl:attribute name = "AirPressure">
				<xsl:value-of select = "@AirPressure"/>
			</xsl:attribute>
			<xsl:attribute name = "Humidity">
				<xsl:value-of select = "@Humidity"/>
			</xsl:attribute>
			<xsl:attribute name = "CO2Percent">
				<xsl:value-of select = "@CO2Percent"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:ImageInstrument">
		<xsl:element name = "InstrumentRef">
			<xsl:if test = "CA:Ref/@DocID">
				<xsl:attribute name = "DocumentID">
					<xsl:value-of select = "CA:Ref/@DocID"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:attribute name = "InstrumentID">
				<xsl:value-of select = "CA:Ref/@ID [../@Name='Instrument']"/>
			</xsl:attribute>
			<xsl:attribute name = "ObjectiveID">
				<xsl:value-of select = "CA:Ref/@ID [../@Name='Objective']"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:Thumbnail">
		<xsl:element name = "Thumbnail">
			<xsl:attribute name = "href">
				<xsl:value-of select = "@href"/>
			</xsl:attribute>
			<xsl:attribute name = "MIMEtype">
				<xsl:value-of select = "@MIMEtype"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:LogicalChannel">
		<xsl:variable name = "LogicalChannelID" select = "@ID"/>
		<xsl:element name = "ChannelInfo">
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "ExWave">
				<xsl:value-of select = "@ExcitationWavelength"/>
			</xsl:attribute>
			<xsl:attribute name = "EmWave">
				<xsl:value-of select = "@EmissionWavelength"/>
			</xsl:attribute>
			<xsl:attribute name = "Fluor">
				<xsl:value-of select = "@Fluor"/>
			</xsl:attribute>
			<xsl:attribute name = "NDfilter">
				<xsl:value-of select = "@NDFilter"/>
			</xsl:attribute>
			<xsl:apply-templates select = "CA:Ref [@Name='LightSource']" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "CA:Ref [@Name='AuxLightSource']" mode = "MakeOMEref">
				<xsl:with-param name = "RefIDName">
					<xsl:text>LightSourceID</xsl:text>
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select = "CA:Ref [@Name='OTF']" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "CA:Ref [@Name='Detector']" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "CA:Ref [@Name='Filter']" mode = "MakeOMEref"/>
			<xsl:apply-templates select = "/CA:OME/CA:Image/CA:CustomAttributes/CA:ChannelComponent [CA:Ref/@ID=$LogicalChannelID]"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:ChannelComponent">
		<xsl:element name = "ChannelComponent">
			<xsl:attribute name = "Index">
				<xsl:value-of select = "@Index"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:DisplayOptions">
		<xsl:variable name = "DisplayOptionsID" select = "@ID"/>
		<xsl:element name = "DisplayOptions">
			<xsl:attribute name = "Zoom">
				<xsl:value-of select = "@Zoom"/>
			</xsl:attribute>
			<xsl:apply-templates select = "CA:Ref [@Name='RedChannel']" mode="MakeDisplayChannel"/>
			<xsl:apply-templates select = "CA:Ref [@Name='GreenChannel']" mode="MakeDisplayChannel"/>
			<xsl:apply-templates select = "CA:Ref [@Name='BlueChannel']" mode="MakeDisplayChannel"/>
			<xsl:apply-templates select = "CA:Ref [@Name='GreyChannel']" mode="MakeDisplayChannel"/>
			<xsl:if test = "string-length(@ZStart) > 0 or string-length(@ZStop) > 0">
				<xsl:element name = "Projection">
					<xsl:if test = "string-length(@ZStart) > 0">
						<xsl:attribute name = "Zstart">
							<xsl:value-of select = "@ZStart"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:if test = "string-length(@ZStop) > 0">
						<xsl:attribute name = "Zstop">
							<xsl:value-of select = "@ZStop"/>
						</xsl:attribute>
					</xsl:if>
				</xsl:element>
			</xsl:if>
			<xsl:if test = "string-length(@TStart) > 0 or string-length(@TStop) > 0">
				<xsl:element name = "Time">
					<xsl:if test = "string-length(@TStart) > 0">
						<xsl:attribute name = "Tstart">
							<xsl:value-of select = "@TStart"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:if test = "string-length(@TStop) > 0">
						<xsl:attribute name = "Tstop">
							<xsl:value-of select = "@TStop"/>
						</xsl:attribute>
					</xsl:if>
				</xsl:element>
			</xsl:if>
			<xsl:apply-templates select = "../CA:DisplayROI [CA:Ref/@ID=$DisplayOptionsID]"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:DisplayOptions/CA:Ref" mode="MakeDisplayChannel">
		<xsl:variable name = "DisplayChannelID" select = "@ID"/>
		<xsl:element name = "{@Name}">
			<xsl:apply-templates select = "../../CA:DisplayChannel/@* [../@ID=$DisplayChannelID] [name() != 'ID']"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:DisplayChannel/@*">
		<xsl:attribute name = "{name()}">
			<xsl:value-of select = "."/>
		</xsl:attribute>
	</xsl:template>
	<xsl:template match = "CA:DisplayROI">
		<xsl:element name = "ROI">
			<xsl:attribute name = "X0">
				<xsl:value-of select = "@X0"/>
			</xsl:attribute>
			<xsl:attribute name = "X1">
				<xsl:value-of select = "@X1"/>
			</xsl:attribute>
			<xsl:attribute name = "Y0">
				<xsl:value-of select = "@Y0"/>
			</xsl:attribute>
			<xsl:attribute name = "Y1">
				<xsl:value-of select = "@Y1"/>
			</xsl:attribute>
			<xsl:attribute name = "Z0">
				<xsl:value-of select = "@Z0"/>
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
		</xsl:element>
	</xsl:template>
	<xsl:template match = "CA:StageLabel">
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
	<xsl:template match = "CA:ImagePlate">
		<xsl:element name = "PlateRef">
			<xsl:if test = "CA:Ref/@DocID">
				<xsl:attribute name = "DocumentID">
					<xsl:value-of select = "CA:Ref/@DocID"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:attribute name = "PlateID">
				<xsl:value-of select = "CA:Ref/@ID [../@Name='Plate']"/>
			</xsl:attribute>
			<xsl:attribute name = "Well">
				<xsl:value-of select = "@Well"/>
			</xsl:attribute>
			<xsl:attribute name = "Sample">
				<xsl:value-of select = "@Sample"/>
			</xsl:attribute>
		</xsl:element>
		<xsl:element name = "PlateRef">
		</xsl:element>
	</xsl:template>
	<xsl:template match = "*" mode = "print">
		<xsl:element name = "{name()}">
			<xsl:value-of select = "."/>
		</xsl:element>
	</xsl:template>
</xsl:transform>