<?xml version = "1.0" encoding = "UTF-8"?>
<xsl:transform xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "" xmlns:OME = "http://www.openmicroscopy.org/XMLschemas/OME/RC6/ome.xsd" xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance">
	<xsl:template match = "OME:OME">
		<xsl:element name = "OME">
			<xsl:attribute name = "schemaLocation" namespace = "http://www.w3.org/2001/XMLSchema-instance">
				<xsl:value-of select = "@xsi:schemaLocation"/>
			</xsl:attribute>
			<!-- Copy DocumentGroup in the original document -->
			
			<!-- Need to copy STD and AML also -->
			<xsl:copy-of select = "OME:DocumentGroup"/>
			<!-- Deal with the hierarchy -->
			<xsl:apply-templates select = "OME:Project" mode = "E2A-Refs"/>
			<xsl:apply-templates select = "OME:Dataset" mode = "E2A-Refs"/>
			<xsl:apply-templates select = "OME:Image"/>
			<!-- Deal with the global custom attributes -->
			<xsl:element name = "CustomAttributes">
				<!-- Copy descendants of CustomAttributes in the original document -->
				<xsl:copy-of select = "OME:CustomAttributes/*"/>
				<!-- Apply templates to children of OME excluding CustomAttributes and DocumentGroup (need to exclude STD and AML also) NOT TESTED! -->
				
				<!--xsl:apply-templates select = "*[name() != 'CustomAttributes'][name() != 'DocumentGroup']" mode = "Convert2CA"/-->
				<xsl:apply-templates select = "OME:Experimenter" mode = "E2A-Refs"/>
				<xsl:apply-templates select = "OME:Experiment" mode = "E2A-Refs"/>
				<xsl:apply-templates select = "OME:Plate" mode = "E2A-Refs"/>
				<xsl:apply-templates select = "OME:Screen" mode = "E2A-Refs"/>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template match = "OME:Image">
		<xsl:element name = "Image">
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@ImageID"/>
			</xsl:attribute>
			<xsl:attribute name = "Name">
				<xsl:value-of select = "@Name"/>
			</xsl:attribute>
			<xsl:attribute name = "Description">
				<xsl:value-of select = "@Description"/>
			</xsl:attribute>
			<xsl:attribute name = "Type">
				<xsl:value-of select = "@Type"/>
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
						<xsl:value-of select = "//OME:Data/@PixelType"/>
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
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<!-- A general template  -->
	<xsl:template match = "*" mode = "E2A-Refs">
		<xsl:element name = "{name()}">
			<xsl:apply-templates select = "." mode = "Element2Attributes"/>
			<xsl:apply-templates select = "*[substring(name(),string-length(name())-2,3) = 'Ref']" mode = "MakeRefs"/>
			<xsl:copy-of select = "OME:CustomAttributes/*"/>
		</xsl:element>
	</xsl:template>
	<!-- Make templates for child-elements of OME -->
	
	<!--xsl:template match = "OME:Instrument">
		<xsl:element name = "{name()}">
			<xsl:apply-templates select = "." mode = "Element2Attributes"/>
			<xsl:apply-templates select = "*" mode = "MakeRefs"/>
		</xsl:element>
	</xsl:template-->
	
	<!-- A utility template to convert child elements and attributes to attributes.  Does not deal with grand-child elements correctly -->
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
	<!-- A utility template to convert reference elements. -->
	<xsl:template match = "*[substring(name(),string-length(name())-2,3) = 'Ref']" mode = "MakeRefs">
		<xsl:element name = "Ref">
			<xsl:attribute name = "Refer">
				<xsl:value-of select = "substring(name(),1,string-length(name())-3)"/>
			</xsl:attribute>
			<xsl:attribute name = "ID">
				<xsl:value-of select = "@*[name() = concat(substring(name(),1,string-length(name())-2),'ID')]"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- This just prints out the names of whatever nodes it gets -->
	<xsl:template match = "*" mode = "print">
		<xsl:element name = "{name()}"/>
	</xsl:template>
	<!-- This copies whatever nodes it gets -->
	<xsl:template match = "*" mode = "copy">
		<xsl:copy/>
	</xsl:template>
	<xsl:template match = "*"/>
</xsl:transform>