/*
 * org.openmicroscopy.xml.CategoryGroupNode
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
 * Created by curtis via Xmlgen on Apr 26, 2006 2:22:48 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import java.util.List;
import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * CategoryGroupNode is the node corresponding to the
 * "CategoryGroup" XML element.
 *
 * Name: CategoryGroup
 * AppliesTo: G
 * Location: OME/src/xml/OME/Annotations/classification.ome
 * Description: A set of mutually exclusive categories.
 */
public class CategoryGroupNode extends AttributeNode
  implements CategoryGroup
{

  // -- Constructors --

  /**
   * Constructs a CategoryGroup node
   * with the given associated DOM element.
   */
  public CategoryGroupNode(Element element) { super(element); }

  /**
   * Constructs a CategoryGroup node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public CategoryGroupNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a CategoryGroup node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public CategoryGroupNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("CategoryGroup"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a CategoryGroup node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public CategoryGroupNode(OMEXMLNode parent, String name, String description)
  {
    this(parent, true);
    setName(name);
    setDescription(description);
  }


  // -- CategoryGroup API methods --

  /**
   * Gets Name attribute
   * of the CategoryGroup element.
   */
  public String getName() {
    return getAttribute("Name");
  }

  /**
   * Sets Name attribute
   * for the CategoryGroup element.
   */
  public void setName(String value) {
    setAttribute("Name", value);
  }

  /**
   * Gets Description attribute
   * of the CategoryGroup element.
   */
  public String getDescription() {
    return getAttribute("Description");
  }

  /**
   * Sets Description attribute
   * for the CategoryGroup element.
   */
  public void setDescription(String value) {
    setAttribute("Description", value);
  }

  /**
   * Gets a list of Category elements
   * referencing this CategoryGroup node.
   */
  public List getCategoryList() {
    return createAttrReferralNodes(CategoryNode.class,
      "Category", "CategoryGroup");
  }

  /**
   * Gets the number of Category elements
   * referencing this CategoryGroup node.
   */
  public int countCategoryList() {
    return getSize(getAttrReferrals("Category",
      "CategoryGroup"));
  }

}