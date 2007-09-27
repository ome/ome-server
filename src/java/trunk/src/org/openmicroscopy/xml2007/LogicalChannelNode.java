/*
 * org.openmicroscopy.xml2007.LogicalChannelNode
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2007 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee,
 *      University of Wisconsin-Madison
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *-----------------------------------------------------------------------------
 */

/*-----------------------------------------------------------------------------
 *
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by user via NameOfAutogenerator on Sep 22, 2007 12:00:00 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml2007;

import java.util.Vector;
import org.w3c.dom.Element;

/**
 * There must be one per channel in the Image, even for a single-plane image.  In OME, Channels (e.g. 'FITC', 'Texas Red', etc) are specified as Logical Channels,
 * And information about how each of them was acquired is stored in the various optional *Ref elements.  Each Logical Channel is composed of one or more
 * ChannelComponents.  For example, an entire spectrum in an FTIR experiment may be stored in a single Logical Channel with each discrete wavenumber of the spectrum
 * constituting a ChannelComponent of the FTIR Logical Channel.  An RGB image where the Red, Green and Blue components do not reflect discrete probes but are
 * instead the output of a color camera would be treated similarly - one Logical channel with three ChannelComponents in this case.
 * The total number of ChannelComponents for a set of pixels must equal SizeC.
 * The SamplesPerPixel attribute is the number of channel components in the logical channel.
 * The IlluminationType attribute is a string enumeration which may be set to 'Transmitted', 'Epifluorescence', 'Oblique', or 'NonLinear'.
 * The optional PinholeAize attribute allows specifying adjustable pin hole diameters for confocal microscopes.
 * The PhotometricInterpretation attribute is used to describe how to display a multi-component channel.  This attribute may be set to:
 * 'monochrome', 'RGB', 'ARGB', 'CMYK', 'HSV'.  The default for single-component channels is 'monochrome'.
 * The Model attribute describes the type of microscopy performed for each channel.  This may be set to:
 * 'Wide-field','Wide-field','Laser Scanning Microscopy','Laser Scanning Confocal','Spinning Disk Confocal','Slit Scan Confocal','Multi-Photon Microscopy',
 * 'Structured Illumination','Single Molecule Imaging','Total Internal Reflection','Fluorescence-Lifetime','Spectral Imaging',
 * 'Fluorescence Correlation Spectroscopy','Near Field Scanning Optical Microscopy','Second Harmonic Generation Imaging'.
 * The ContrastMethod attribute may be set to 'Brightfield','Phase','DIC','Hoffman Modulation','Oblique Illumination','Polarized Light','Darkfield','Fluorescence'.
 * The ExWave, EmWave and Fluor attributes allow specifying the nominal excitation and emission wavelengths and the type of fluor being imaged in a particular channel.
 * The Fluor attribute is used for fluorescence images, while the Name attribute is used to name channels that are not imaged using fluorescence techniques.
 * The user interface logic for labeling a given channel for the user should use the first existing attribute in the following sequence:
 * Name -> Fluor -> EmWave -> ChannelComponent/Index.
 * The NDfilter attribute is used to specify (in O.D. units) the combined effect of any neutral density filters used.
 */
public class LogicalChannelNode extends OMEXMLNode {

  // -- Constructor --

  public LogicalChannelNode(Element element) { super(element); }

  // -- LogicalChannelNode API methods --

  public LightSourceNode getLightSource() {
    return (LightSourceNode) getReferencedNode("LightSource", "LightSourceRef");
  }

  public OTFNode getOTF() {
    return (OTFNode) getReferencedNode("OTF", "OTFRef");
  }

  public DetectorNode getDetector() {
    return (DetectorNode) getReferencedNode("Detector", "DetectorRef");
  }

  public FilterSetNode getFilterSet() {
    return (FilterSetNode) getReferencedNode("FilterSet", "FilterSetRef");
  }

  public int getChannelComponentCount() {
    return getChildCount("ChannelComponent");
  }

  public Vector getChannelComponentList() {
    return getChildNodes("ChannelComponent");
  }

  public String getName() {
    return getAttribute("Name");
  }

  public void setName(String name) {
    setAttribute("Name", name);
  }

  public String getSamplesPerPixel() {
    return getAttribute("SamplesPerPixel");
  }

  public void setSamplesPerPixel(String samplesPerPixel) {
    setAttribute("SamplesPerPixel", samplesPerPixel);
  }

  public FilterNode getSecondaryEmissionFilter() {
    return (FilterNode) getAttrReferencedNode("Filter", "SecondaryEmissionFilter");
  }

  public FilterNode getSecondaryExcitationFilter() {
    return (FilterNode) getAttrReferencedNode("Filter", "SecondaryExcitationFilter");
  }

  /**
   * Attribute is called Illumination in EA diagram - ajp
   * Added NonLinear - ajp
   */
  public String getIlluminationType() {
    return getAttribute("IlluminationType");
  }

  public void setIlluminationType(String illuminationType) {
    setAttribute("IlluminationType", illuminationType);
  }

  public Integer getPinholeSize() {
    return getIntegerAttribute("PinholeSize");
  }

  public void setPinholeSize(Integer pinholeSize) {
    setAttribute("PinholeSize", pinholeSize);
  }

  /**
   * To Do - Add more documentation - ajp
   * Added ColorMap - ajp
   */
  public String getPhotometricInterpretation() {
    return getAttribute("PhotometricInterpretation");
  }

  public void setPhotometricInterpretation(String photometricInterpretation) {
    setAttribute("PhotometricInterpretation", photometricInterpretation);
  }

  public String getMode() {
    return getAttribute("Mode");
  }

  public void setMode(String mode) {
    setAttribute("Mode", mode);
  }

  public String getContrastMethod() {
    return getAttribute("ContrastMethod");
  }

  public void setContrastMethod(String contrastMethod) {
    setAttribute("ContrastMethod", contrastMethod);
  }

  public Integer getExWave() {
    return getIntegerAttribute("ExWave");
  }

  public void setExWave(Integer exWave) {
    setAttribute("ExWave", exWave);
  }

  public Integer getEmWave() {
    return getIntegerAttribute("EmWave");
  }

  public void setEmWave(Integer emWave) {
    setAttribute("EmWave", emWave);
  }

  public String getFluor() {
    return getAttribute("Fluor");
  }

  public void setFluor(String fluor) {
    setAttribute("Fluor", fluor);
  }

  public Float getNdFilter() {
    return getFloatAttribute("NdFilter");
  }

  public void setNdFilter(Float ndFilter) {
    setAttribute("NdFilter", ndFilter);
  }

  public Integer getPockelCellSetting() {
    return getIntegerAttribute("PockelCellSetting");
  }

  public void setPockelCellSetting(Integer pockelCellSetting) {
    setAttribute("PockelCellSetting", pockelCellSetting);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return true; }

}
