/*
 * org.openmicroscopy.xml.SignalNode
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
 * Created by curtis via Xmlgen on Dec 18, 2007 12:41:44 PM CST
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import ome.xml.OMEXMLNode;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * SignalNode is the node corresponding to the
 * "Signal" XML element.
 *
 * Name: Signal
 * AppliesTo: F
 * Location: OME/src/xml/OME/Analysis/FindSpots/spotModules.ome
 * Description: Spectral information about a feature
 */
public class SignalNode extends AttributeNode
  implements Signal
{

  // -- Constructors --

  /**
   * Constructs a Signal node
   * with the given associated DOM element.
   */
  public SignalNode(Element element) { super(element); }

  /**
   * Constructs a Signal node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public SignalNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Signal node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public SignalNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Signal", attach);
  }

  /**
   * Constructs a Signal node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public SignalNode(CustomAttributesNode parent, Integer theC, Float centroidX,
    Float centroidY, Float centroidZ, Float integral, Float mean,
    Float geometricMean, Float sigma, Float geometricSigma, Float background)
  {
    this(parent, true);
    setTheC(theC);
    setCentroidX(centroidX);
    setCentroidY(centroidY);
    setCentroidZ(centroidZ);
    setIntegral(integral);
    setMean(mean);
    setGeometricMean(geometricMean);
    setSigma(sigma);
    setGeometricSigma(geometricSigma);
    setBackground(background);
  }


  // -- Signal API methods --

  /**
   * Gets TheC attribute
   * of the Signal element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the Signal element.
   */
  public void setTheC(Integer value) {
    setAttribute("TheC", value);  }

  /**
   * Gets CentroidX attribute
   * of the Signal element.
   */
  public Float getCentroidX() {
    return getFloatAttribute("CentroidX");
  }

  /**
   * Sets CentroidX attribute
   * for the Signal element.
   */
  public void setCentroidX(Float value) {
    setAttribute("CentroidX", value);  }

  /**
   * Gets CentroidY attribute
   * of the Signal element.
   */
  public Float getCentroidY() {
    return getFloatAttribute("CentroidY");
  }

  /**
   * Sets CentroidY attribute
   * for the Signal element.
   */
  public void setCentroidY(Float value) {
    setAttribute("CentroidY", value);  }

  /**
   * Gets CentroidZ attribute
   * of the Signal element.
   */
  public Float getCentroidZ() {
    return getFloatAttribute("CentroidZ");
  }

  /**
   * Sets CentroidZ attribute
   * for the Signal element.
   */
  public void setCentroidZ(Float value) {
    setAttribute("CentroidZ", value);  }

  /**
   * Gets Integral attribute
   * of the Signal element.
   */
  public Float getIntegral() {
    return getFloatAttribute("Integral");
  }

  /**
   * Sets Integral attribute
   * for the Signal element.
   */
  public void setIntegral(Float value) {
    setAttribute("Integral", value);  }

  /**
   * Gets Mean attribute
   * of the Signal element.
   */
  public Float getMean() {
    return getFloatAttribute("Mean");
  }

  /**
   * Sets Mean attribute
   * for the Signal element.
   */
  public void setMean(Float value) {
    setAttribute("Mean", value);  }

  /**
   * Gets GeometricMean attribute
   * of the Signal element.
   */
  public Float getGeometricMean() {
    return getFloatAttribute("GeometricMean");
  }

  /**
   * Sets GeometricMean attribute
   * for the Signal element.
   */
  public void setGeometricMean(Float value) {
    setAttribute("GeometricMean", value);  }

  /**
   * Gets Sigma attribute
   * of the Signal element.
   */
  public Float getSigma() {
    return getFloatAttribute("Sigma");
  }

  /**
   * Sets Sigma attribute
   * for the Signal element.
   */
  public void setSigma(Float value) {
    setAttribute("Sigma", value);  }

  /**
   * Gets GeometricSigma attribute
   * of the Signal element.
   */
  public Float getGeometricSigma() {
    return getFloatAttribute("GeometricSigma");
  }

  /**
   * Sets GeometricSigma attribute
   * for the Signal element.
   */
  public void setGeometricSigma(Float value) {
    setAttribute("GeometricSigma", value);  }

  /**
   * Gets Background attribute
   * of the Signal element.
   */
  public Float getBackground() {
    return getFloatAttribute("Background");
  }

  /**
   * Sets Background attribute
   * for the Signal element.
   */
  public void setBackground(Float value) {
    setAttribute("Background", value);  }

}
