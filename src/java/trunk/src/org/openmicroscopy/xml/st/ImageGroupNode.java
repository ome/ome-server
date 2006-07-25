/*
 * org.openmicroscopy.xml.ImageGroupNode
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
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by curtis via Xmlgen on Jul 25, 2006 12:37:00 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ImageGroupNode is the node corresponding to the
 * "ImageGroup" XML element.
 *
 * Name: ImageGroup
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: This specifies the Group that the Image belongs to (these are
 *   Groups of Experimenters)
 */
public class ImageGroupNode extends AttributeNode
  implements ImageGroup
{

  // -- Constructors --

  /**
   * Constructs an ImageGroup node
   * with the given associated DOM element.
   */
  public ImageGroupNode(Element element) { super(element); }

  /**
   * Constructs an ImageGroup node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageGroupNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an ImageGroup node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageGroupNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("ImageGroup"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an ImageGroup node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ImageGroupNode(CustomAttributesNode parent, Group group)
  {
    this(parent, true);
    setGroup(group);
  }


  // -- ImageGroup API methods --

  /**
   * Gets Group referenced by Group
   * attribute of the ImageGroup element.
   */
  public Group getGroup() {
    return (Group)
      createReferencedNode(GroupNode.class,
      "Group", "Group");
  }

  /**
   * Sets Group referenced by Group
   * attribute of the ImageGroup element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of GroupNode
   */
  public void setGroup(Group value) {
    setReferencedNode((OMEXMLNode) value, "Group", "Group");
  }

}
