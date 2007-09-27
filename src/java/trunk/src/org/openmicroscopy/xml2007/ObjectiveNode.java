/*
 * org.openmicroscopy.xml2007.ObjectiveNode
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

import org.w3c.dom.Element;

/**
 * A description of the microscope's objective lens.
 * Required elements include the lens numerical aperture, and the magnification, both of which a floating point (real) numbers.
 */
public class ObjectiveNode extends ManufactSpecNode {

  // -- Constructor --

  public ObjectiveNode(Element element) { super(element); }

  // -- ObjectiveNode API methods --

  /** The coating applied to the lens */
  public String getCorrection() {
    return getCData("Correction");
  }

  public void setCorrection(String correction) {
    setCData("Correction", correction);
  }

  /** The immersion medium the lens is designed for */
  public String getImmersion() {
    return getCData("Immersion");
  }

  public void setImmersion(String immersion) {
    setCData("Immersion", immersion);
  }

  /** The numerical aperture of the lens expressed as a floating point (real) number. */
  public Float getLensNA() {
    return getFloatCData("LensNA");
  }

  public void setLensNA(Float lensNA) {
    setCData("LensNA", lensNA);
  }

  /** The magnification of the lens as specified by the manufacturer - i.e. '60' is a 60X lens. */
  public Integer getNominalMagnification() {
    return getIntegerCData("NominalMagnification");
  }

  public void setNominalMagnification(Integer nominalMagnification) {
    setCData("NominalMagnification", nominalMagnification);
  }

  /** The magnification of the lens as measured by a calibration process- i.e. '59.987' for a 60X lens. */
  public Float getCalibratedMagnification() {
    return getFloatCData("CalibratedMagnification");
  }

  public void setCalibratedMagnification(Float calibratedMagnification) {
    setCData("CalibratedMagnification", calibratedMagnification);
  }

  /** The working distance of the lens expressed as a floating point (real) number. Units are um. */
  public Float getWorkingDistance() {
    return getFloatCData("WorkingDistance");
  }

  public void setWorkingDistance(Float workingDistance) {
    setCData("WorkingDistance", workingDistance);
  }

  // -- OMEXML API methods --

  public boolean hasID() { return true; }

}
