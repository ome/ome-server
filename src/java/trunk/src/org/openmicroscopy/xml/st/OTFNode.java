/*
 * org.openmicroscopy.xml.OTFNode
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

import java.util.List;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * OTFNode is the node corresponding to the
 * "OTF" XML element.
 *
 * Name: OTF
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Instrument.ome
 */
public class OTFNode extends AttributeNode
  implements OTF
{

  // -- Constructors --

  /**
   * Constructs an OTF node
   * with the given associated DOM element.
   */
  public OTFNode(Element element) { super(element); }

  /**
   * Constructs an OTF node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public OTFNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an OTF node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public OTFNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "OTF", attach);
  }

  /**
   * Constructs an OTF node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public OTFNode(CustomAttributesNode parent, Objective objective,
    Filter filter, Integer sizeX, Integer sizeY, String pixelType,
    Repository repository, String path, Boolean opticalAxisAverage,
    Instrument instrument)
  {
    this(parent, true);
    setObjective(objective);
    setFilter(filter);
    setSizeX(sizeX);
    setSizeY(sizeY);
    setPixelType(pixelType);
    setRepository(repository);
    setPath(path);
    setOpticalAxisAverage(opticalAxisAverage);
    setInstrument(instrument);
  }


  // -- OTF API methods --

  /**
   * Gets Objective referenced by Objective
   * attribute of the OTF element.
   */
  public Objective getObjective() {
    return (Objective)
      getAttrReferencedNode("Objective", "Objective");
  }

  /**
   * Sets Objective referenced by Objective
   * attribute of the OTF element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ObjectiveNode
   */
  public void setObjective(Objective value) {
    setAttrReferencedNode((OMEXMLNode) value, "Objective");
  }

  /**
   * Gets Filter referenced by Filter
   * attribute of the OTF element.
   */
  public Filter getFilter() {
    return (Filter)
      getAttrReferencedNode("Filter", "Filter");
  }

  /**
   * Sets Filter referenced by Filter
   * attribute of the OTF element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of FilterNode
   */
  public void setFilter(Filter value) {
    setAttrReferencedNode((OMEXMLNode) value, "Filter");
  }

  /**
   * Gets SizeX attribute
   * of the OTF element.
   */
  public Integer getSizeX() {
    return getIntegerAttribute("SizeX");
  }

  /**
   * Sets SizeX attribute
   * for the OTF element.
   */
  public void setSizeX(Integer value) {
    setAttribute("SizeX", value);  }

  /**
   * Gets SizeY attribute
   * of the OTF element.
   */
  public Integer getSizeY() {
    return getIntegerAttribute("SizeY");
  }

  /**
   * Sets SizeY attribute
   * for the OTF element.
   */
  public void setSizeY(Integer value) {
    setAttribute("SizeY", value);  }

  /**
   * Gets PixelType attribute
   * of the OTF element.
   */
  public String getPixelType() {
    return getAttribute("PixelType");
  }

  /**
   * Sets PixelType attribute
   * for the OTF element.
   */
  public void setPixelType(String value) {
    setAttribute("PixelType", value);  }

  /**
   * Gets Repository referenced by Repository
   * attribute of the OTF element.
   */
  public Repository getRepository() {
    return (Repository)
      getAttrReferencedNode("Repository", "Repository");
  }

  /**
   * Sets Repository referenced by Repository
   * attribute of the OTF element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of RepositoryNode
   */
  public void setRepository(Repository value) {
    setAttrReferencedNode((OMEXMLNode) value, "Repository");
  }

  /**
   * Gets Path attribute
   * of the OTF element.
   */
  public String getPath() {
    return getAttribute("Path");
  }

  /**
   * Sets Path attribute
   * for the OTF element.
   */
  public void setPath(String value) {
    setAttribute("Path", value);  }

  /**
   * Gets OpticalAxisAverage attribute
   * of the OTF element.
   */
  public Boolean isOpticalAxisAverage() {
    return getBooleanAttribute("OpticalAxisAverage");
  }

  /**
   * Sets OpticalAxisAverage attribute
   * for the OTF element.
   */
  public void setOpticalAxisAverage(Boolean value) {
    setAttribute("OpticalAxisAverage", value);  }

  /**
   * Gets Instrument referenced by Instrument
   * attribute of the OTF element.
   */
  public Instrument getInstrument() {
    return (Instrument)
      getAttrReferencedNode("Instrument", "Instrument");
  }

  /**
   * Sets Instrument referenced by Instrument
   * attribute of the OTF element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of InstrumentNode
   */
  public void setInstrument(Instrument value) {
    setAttrReferencedNode((OMEXMLNode) value, "Instrument");
  }

  /**
   * Gets a list of LogicalChannel elements
   * referencing this OTF node.
   */
  public List getLogicalChannelList() {
    return getAttrReferringNodes("LogicalChannel", "OTF");
  }

  /**
   * Gets the number of LogicalChannel elements
   * referencing this OTF node.
   */
  public int countLogicalChannelList() {
    return getAttrReferringCount("LogicalChannel", "OTF");
  }

}
