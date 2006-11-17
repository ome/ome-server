/*
 * org.openmicroscopy.xml.ImageNode
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2006 Open Microscopy Environment
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
 * Written by:    Curtis Rueden <ctrueden@wisc.edu>
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml;

import java.util.Calendar;
import java.util.List;
import org.openmicroscopy.ds.dto.Image;
import org.openmicroscopy.ds.st.*;
import org.openmicroscopy.xml.st.*;
import org.w3c.dom.Element;

/** ImageNode is the node corresponding to the "Image" XML element. */
public class ImageNode extends OMEXMLNode implements Image {

  // -- Constructors --

  /** Constructs a Image node with the given associated DOM element. */
  public ImageNode(Element element) { super(element); }

  /**
   * Constructs an Image node, creating its associated
   * DOM element beneath the given parent.
   */
  public ImageNode(OMENode parent) { this(parent, true); }

  /**
   * Constructs an Image node, creating its associated
   * DOM element beneath the given parent.
   */
  public ImageNode(OMENode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().createElement("Image"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an Image node, creating its associated DOM element
   * beneath the given parent, using the specified parameter values.
   */
  public ImageNode(OMENode parent, String name,
    String creationDate, String description)
  {
    this(parent, true);
    setName(name);
    setCreated(creationDate);
    setDescription(description);
  }


  // -- ImageNode API methods --

  /** Gets Group referenced by Group attribute of the Image element. */
  public Group getGroup() {
    return (Group) createReferencedNode(GroupNode.class, "Group", "Group");
  }

  /**
   * Sets Group referenced by Group attribute of the Image element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of GroupNode
   */
  public void setGroup(Group value) {
    setReferencedNode((OMEXMLNode) value, "Group", "Group");
  }

  /** Gets node corresponding to CustomAttributes child element. */
  public CustomAttributesNode getCustomAttributes() {
    return (CustomAttributesNode)
      createChildNode(CustomAttributesNode.class, "CustomAttributes");
  }

  /** Adds this Image to a Dataset. */
  public void addToDataset(DatasetNode dataset) { createReference(dataset); }


  // -- Image API methods --

  /** Returns -1. Primary key IDs are not applicable for external OME-XML. */
  public int getID() { return -1; }

  /** Does nothing. Primary key IDs are not applicable for external OME-XML. */
  public void setID(int value) { }

  /** Gets Name attribute of the Image element. */
  public String getName() { return getAttribute("Name"); }

  /** Sets Name attribute for the Image element. */
  public void setName(String value) { setAttribute("Name", value); }

  /** Gets Description attribute of the Image element. */
  public String getDescription() { return getAttribute("Description"); }

  /** Sets Description atrribute for the Image element. */
  public void setDescription(String value) {
    setAttribute("Description", value);
  }

  /**
   * Gets Experimenter referenced by Experimenter
   * attribute of the Image element.
   */
  public Experimenter getOwner() {
    return (Experimenter) createReferencedNode(ExperimenterNode.class,
      "Experimenter", "Experimenter");
  }

  /**
   * Sets Experimenter referenced by Experimenter
   * attribute of the Image element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setOwner(Experimenter value) {
    setReferencedNode((OMEXMLNode) value, "Experimenter", "Experimenter");
  }

  /** Gets CreationDate attribute of the Image element. */
  public String getCreated() { return getAttribute("CreationDate"); }

  /** Sets CreationDate attribute for the Image element. */
  public void setCreated(String value) {
    if (value == null && getCreated() == null) {
      // CreationDate is required; initialize a default value (current time)
      // use ISO 8601 dateTime format (e.g., 1988-04-07T18:39:09)
      StringBuffer sb = new StringBuffer();
      Calendar now = Calendar.getInstance();
      int year = now.get(Calendar.YEAR);
      int month = now.get(Calendar.MONTH);
      int day = now.get(Calendar.DAY_OF_MONTH);
      int hour = now.get(Calendar.HOUR_OF_DAY);
      int min = now.get(Calendar.MINUTE);
      int sec = now.get(Calendar.SECOND);
      sb.append(year);
      sb.append("-");
      if (month < 9) sb.append("0");
      sb.append(month + 1);
      sb.append("-");
      if (day < 10) sb.append("0");
      sb.append(day);
      sb.append("T");
      if (hour < 10) sb.append("0");
      sb.append(hour);
      sb.append(":");
      if (min < 10) sb.append("0");
      sb.append(min);
      sb.append(":");
      if (sec < 10) sb.append("0");
      sb.append(sec);
      value = sb.toString();
    }
    setAttribute("CreationDate", value);
  }

  /** Returns null. Not applicable for external OME-XML. */
  public String getInserted() { return null; }

  /** Does nothing. Not applicable for external OME-XML. */
  public void setInserted(String value) { }

  /**
   * Gets Pixels referenced by DefaultPixels attribute of the Image element.
   */
  public Pixels getDefaultPixels() {
    return (Pixels) createReferencedNode(PixelsNode.class,
      "Pixels", "DefaultPixels");
  }

  /**
   * Sets Pixels referenced by DefaultPixels attribute of the Image element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of PixelsNode
   */
  public void setDefaultPixels(Pixels value) {
    setReferencedNode((OMEXMLNode) value, "Pixels", "DefaultPixels");
  }

  /** Gets a list of Datasets referenced by the Image. */
  public List getDatasets() {
    return createReferencedNodes(DatasetNode.class, "Dataset");
  }

  /** Gets the number of Datasets referenced by the Image. */
  public int countDatasets() {
    return getSize(getChildElements("DatasetRef"));
  }

  /** Gets Feature child nodes. */
  public List getFeatures() {
    return createChildNodes(FeatureNode.class, "Feature");
  }

  /** Gets the number of Feature child nodes. */
  public int countFeatures() { return getSize(getChildElements("Feature")); }

}
