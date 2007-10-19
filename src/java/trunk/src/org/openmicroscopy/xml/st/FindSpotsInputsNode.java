/*
 * org.openmicroscopy.xml.FindSpotsInputsNode
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
 * Created by curtis via Xmlgen on Oct 19, 2007 5:03:39 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * FindSpotsInputsNode is the node corresponding to the
 * "FindSpotsInputs" XML element.
 *
 * Name: FindSpotsInputs
 * AppliesTo: G
 * Location: OME/src/xml/OME/Analysis/FindSpots/spotModules.ome
 */
public class FindSpotsInputsNode extends AttributeNode
  implements FindSpotsInputs
{

  // -- Constructors --

  /**
   * Constructs a FindSpotsInputs node
   * with the given associated DOM element.
   */
  public FindSpotsInputsNode(Element element) { super(element); }

  /**
   * Constructs a FindSpotsInputs node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FindSpotsInputsNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a FindSpotsInputs node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FindSpotsInputsNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "FindSpotsInputs", attach);
  }

  /**
   * Constructs a FindSpotsInputs node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public FindSpotsInputsNode(CustomAttributesNode parent, Integer timeStart,
    Integer timeStop, String channel, Float minimumSpotVolume,
    String thresholdType, Float thresholdValue, Integer fadeSpotsTheT,
    Boolean darkSpots)
  {
    this(parent, true);
    setTimeStart(timeStart);
    setTimeStop(timeStop);
    setChannel(channel);
    setMinimumSpotVolume(minimumSpotVolume);
    setThresholdType(thresholdType);
    setThresholdValue(thresholdValue);
    setFadeSpotsTheT(fadeSpotsTheT);
    setDarkSpots(darkSpots);
  }


  // -- FindSpotsInputs API methods --

  /**
   * Gets TimeStart attribute
   * of the FindSpotsInputs element.
   */
  public Integer getTimeStart() {
    return getIntegerAttribute("TimeStart");
  }

  /**
   * Sets TimeStart attribute
   * for the FindSpotsInputs element.
   */
  public void setTimeStart(Integer value) {
    setAttribute("TimeStart", value);  }

  /**
   * Gets TimeStop attribute
   * of the FindSpotsInputs element.
   */
  public Integer getTimeStop() {
    return getIntegerAttribute("TimeStop");
  }

  /**
   * Sets TimeStop attribute
   * for the FindSpotsInputs element.
   */
  public void setTimeStop(Integer value) {
    setAttribute("TimeStop", value);  }

  /**
   * Gets Channel attribute
   * of the FindSpotsInputs element.
   */
  public String getChannel() {
    return getAttribute("Channel");
  }

  /**
   * Sets Channel attribute
   * for the FindSpotsInputs element.
   */
  public void setChannel(String value) {
    setAttribute("Channel", value);  }

  /**
   * Gets MinimumSpotVolume attribute
   * of the FindSpotsInputs element.
   */
  public Float getMinimumSpotVolume() {
    return getFloatAttribute("MinimumSpotVolume");
  }

  /**
   * Sets MinimumSpotVolume attribute
   * for the FindSpotsInputs element.
   */
  public void setMinimumSpotVolume(Float value) {
    setAttribute("MinimumSpotVolume", value);  }

  /**
   * Gets ThresholdType attribute
   * of the FindSpotsInputs element.
   */
  public String getThresholdType() {
    return getAttribute("ThresholdType");
  }

  /**
   * Sets ThresholdType attribute
   * for the FindSpotsInputs element.
   */
  public void setThresholdType(String value) {
    setAttribute("ThresholdType", value);  }

  /**
   * Gets ThresholdValue attribute
   * of the FindSpotsInputs element.
   */
  public Float getThresholdValue() {
    return getFloatAttribute("ThresholdValue");
  }

  /**
   * Sets ThresholdValue attribute
   * for the FindSpotsInputs element.
   */
  public void setThresholdValue(Float value) {
    setAttribute("ThresholdValue", value);  }

  /**
   * Gets FadeSpotsTheT attribute
   * of the FindSpotsInputs element.
   */
  public Integer getFadeSpotsTheT() {
    return getIntegerAttribute("FadeSpotsTheT");
  }

  /**
   * Sets FadeSpotsTheT attribute
   * for the FindSpotsInputs element.
   */
  public void setFadeSpotsTheT(Integer value) {
    setAttribute("FadeSpotsTheT", value);  }

  /**
   * Gets DarkSpots attribute
   * of the FindSpotsInputs element.
   */
  public Boolean isDarkSpots() {
    return getBooleanAttribute("DarkSpots");
  }

  /**
   * Sets DarkSpots attribute
   * for the FindSpotsInputs element.
   */
  public void setDarkSpots(Boolean value) {
    setAttribute("DarkSpots", value);  }

}
