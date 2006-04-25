/*
 * org.openmicroscopy.xml.FeatureNode
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

import java.util.List;
import org.openmicroscopy.ds.dto.Feature;
import org.openmicroscopy.ds.dto.Image;
import org.w3c.dom.Element;

/** FeatureNode is the node corresponding to the "Feature" XML element. */
public class FeatureNode extends OMEXMLNode implements Feature {

  // -- Constructor --

  /** Constructs a Feature node with the given associated DOM element. */
  public FeatureNode(Element element) { super(element); }


  // -- FeatureNode API methods --

  /** Gets node corresponding to CustomAttributes child element. */
  public CustomAttributesNode getCustomAttributes() {
    return (CustomAttributesNode)
      createChildNode(CustomAttributesNode.class, "CustomAttributes");
  }


  // -- Feature API methods --

  /** Returns -1. Primary key IDs are not applicable for external OME-XML. */
  public int getID() { return -1; }

  /** Does nothing. Primary key IDs are not applicable for external OME-XML. */
  public void setID(int value) { }

  /** Gets the Image element ancestor to this Feature element. */
  public Image getImage() {
    return (Image) createAncestorNode(ImageNode.class, "Image");
  }

  /**
   * Sets the Image element ancestor for this Feature element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ImageNode
   */
  public void setImage(Image value) {
    ((OMEXMLNode) value).getDOMElement().appendChild(element);
  }

  /** Gets the Feature element ancestor to this Feature element. */
  public Feature getParentFeature() {
    return (Feature) createAncestorNode(FeatureNode.class, "Feature");
  }

  /**
   * Sets the Feature element ancestor for this Feature element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of FeatureNode
   */
  public void setParentFeature(Feature value) {
    ((OMEXMLNode) value).getDOMElement().appendChild(element);
  }

  /** Gets Tag attribute of the Feature element. */
  public String getTag() { return getAttribute("Tag"); }

  /** Sets Tag attribute for the Feature element. */
  public void setTag(String value) { setAttribute("Tag", value); }

  /** Gets Name attribute of the Feature element. */
  public String getName() { return getAttribute("Name"); }

  /** Sets Name attribute for the Feature element. */
  public void setName(String value) { setAttribute("Name", value); }

  /** Gets nodes corresponding to Feature child elements. */
  public List getChildren() {
    return createChildNodes(FeatureNode.class, "Feature");
  }

  /** Gets the number of Feature child elements. */
  public int countChildren() { return getSize(getChildElements("Feature")); }

}
