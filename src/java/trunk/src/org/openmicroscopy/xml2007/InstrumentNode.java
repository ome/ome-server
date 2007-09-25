/*
 * org.openmicroscopy.xml2007.InstrumentNode
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
 * This element describes the instrument used to capture the Image.
 * It is primarily a container for manufacturer's model and catalog numbers for the
 * Microscope, LightSource, Detector, Objective and Filters components.
 * Additionally, one or more OTF elements may be specified, describing the optical transfer function under different conditions.
 * The Objective element contains the additional elements LensNA and Magnification.
 * The Filters element can be composed either of separate excitation, emission filters and a dichroic mirror
 * or a single filter set.  Within the Image itself, a reference is made to this one Filter element.
 * The OTF element contains an optical transfer function.
 * The same OTF can be used for all wavelengths, or there may be one per wavelength.
 * There may be multiple light sources, detectors, objectives and filters on a microscope.
 * Each of these has their own ID attribute, which can be referred to from LogicalChannel.
 * It is understood that the light path configuration can be different for each channel,
 * but cannot be different for each timepoint or each plane of an XYZ stack.
 */
public class InstrumentNode extends OMEXMLNode {

  // -- Constructor --

  public InstrumentNode(Element element) { super(element); }

  // -- InstrumentNode API methods --

  public MicroscopeNode getMicroscope() {
    return (MicroscopeNode) getChildNode("Microscope");
  }

  public int getLightSourceCount() {
    return getChildCount("LightSource");
  }

  public Vector getLightSourceList() {
    return getChildNodes("LightSource");
  }

  public int getDetectorCount() {
    return getChildCount("Detector");
  }

  public Vector getDetectorList() {
    return getChildNodes("Detector");
  }

  public int getObjectiveCount() {
    return getChildCount("Objective");
  }

  public Vector getObjectiveList() {
    return getChildNodes("Objective");
  }

  public int getFilterSetCount() {
    return getChildCount("FilterSet");
  }

  public Vector getFilterSetList() {
    return getChildNodes("FilterSet");
  }

  public int getFilterCount() {
    return getChildCount("Filter");
  }

  public Vector getFilterList() {
    return getChildNodes("Filter");
  }

  public int getDichroicCount() {
    return getChildCount("Dichroic");
  }

  public Vector getDichroicList() {
    return getChildNodes("Dichroic");
  }

  public int getOTFCount() {
    return getChildCount("OTF");
  }

  public Vector getOTFList() {
    return getChildNodes("OTF");
  }

}
