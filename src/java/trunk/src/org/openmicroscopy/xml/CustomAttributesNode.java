/*
 * org.openmicroscopy.xml.CustomAttributesNode
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
import java.util.Vector;
import org.w3c.dom.*;

/**
 * CustomAttributesNode is the node corresponding to the
 * "CustomAttributes" XML element.
 */
public class CustomAttributesNode extends OMEXMLNode {

  // -- Constructor --

  /**
   * Constructs a CustomAttributes node with the given associated DOM element.
   */
  public CustomAttributesNode(Element element) { super(element); }

  /**
   * Constructs a CustomAttributes node,
   * creating its associated DOM element beneath the given parent.
   */
  public CustomAttributesNode(DatasetNode parent) {
    this((OMEXMLNode) parent);
  }

  /**
   * Constructs a CustomAttributes node,
   * creating its associated DOM element beneath the given parent.
   */
  public CustomAttributesNode(FeatureNode parent) {
    this((OMEXMLNode) parent);
  }

  /**
   * Constructs a CustomAttributes node,
   * creating its associated DOM element beneath the given parent.
   */
  public CustomAttributesNode(ImageNode parent) { this((OMEXMLNode) parent); }

  /**
   * Constructs a CustomAttributes node,
   * creating its associated DOM element beneath the given parent.
   */
  public CustomAttributesNode(OMENode parent) { this((OMEXMLNode) parent); }

  /**
   * Constructs a CustomAttributes node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  protected CustomAttributesNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("CustomAttributes"));
    parent.getDOMElement().appendChild(element);
  }


  // -- CustomAttributesNode API methods --

  /**
   * Gets a list of DOM elements (custom attributes) beneath the
   * CustomAttributes element. This list can include both recognized STs
   * (nodes from the org.openmicroscopy.xml.st package) and unknown ones
   * (generic AttributeNodes).
   */
  public List getCAList() {
    NodeList list = element.getChildNodes();
    int len = list.getLength();
    Vector v = new Vector();
    for (int i=0; i<len; i++) {
      Node node = list.item(i);
      if (!(node instanceof Element)) continue;
      Element el = (Element) node;
      v.add(createNode(el));
    }
    return v;
  }

  /**
   * Gets the number of DOM elements (custom attributes)
   * beneath the CustomAttributes element.
   */
  public int countCAList() {
    NodeList list = element.getChildNodes();
    int len = list.getLength();
    int count = 0;
    for (int i=0; i<len; i++) {
      Node node = list.item(i);
      if (node instanceof Element) count++;
    }
    return count;
  }


  // -- OMEXMLNode API methods --

  /** Gets whether this type of node should have an LSID. */
  public boolean hasLSID() { return false; }

}
