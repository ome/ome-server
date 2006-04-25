/*
 * org.openmicroscopy.xml.CategoryNode
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
 * Created by curtis via Xmlgen on Apr 24, 2006 4:30:18 PM CDT
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
 * CategoryNode is the node corresponding to the
 * "Category" XML element.
 *
 * Name: Category
 * AppliesTo: G
 * Location: OME/src/xml/OME/Annotations/classification.ome
 * Description: A category within some set.
 */
public class CategoryNode extends AttributeNode
  implements Category
{

  // -- Constructors --

  /**
   * Constructs a Category node
   * with the given associated DOM element.
   */
  public CategoryNode(Element element) { super(element); }

  /**
   * Constructs a Category node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public CategoryNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("Category"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a Category node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public CategoryNode(OMEXMLNode parent, String name,
    CategoryGroup categoryGroup, String description)
  {
    this(parent);
    setName(name);
    setCategoryGroup(categoryGroup);
    setDescription(description);
  }


  // -- Category API methods --

  /**
   * Gets Name attribute
   * of the Category element.
   */
  public String getName() {
    return getAttribute("Name");
  }

  /**
   * Sets Name attribute
   * for the Category element.
   */
  public void setName(String value) {
    setAttribute("Name", value);
  }

  /**
   * Gets CategoryGroup referenced by CategoryGroup
   * attribute of the Category element.
   */
  public CategoryGroup getCategoryGroup() {
    return (CategoryGroup)
      createReferencedNode(CategoryGroupNode.class,
      "CategoryGroup", "CategoryGroup");
  }

  /**
   * Sets CategoryGroup referenced by CategoryGroup
   * attribute of the Category element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of CategoryGroupNode
   */
  public void setCategoryGroup(CategoryGroup value) {
    setReferencedNode((OMEXMLNode) value, "CategoryGroup", "CategoryGroup");
  }

  /**
   * Gets Description attribute
   * of the Category element.
   */
  public String getDescription() {
    return getAttribute("Description");
  }

  /**
   * Sets Description attribute
   * for the Category element.
   */
  public void setDescription(String value) {
    setAttribute("Description", value);
  }

  /**
   * Gets a list of Classification elements
   * referencing this Category node.
   */
  public List getClassificationList() {
    return createAttrReferralNodes(ClassificationNode.class,
      "Classification", "Category");
  }

  /**
   * Gets the number of Classification elements
   * referencing this Category node.
   */
  public int countClassificationList() {
    return getSize(getAttrReferrals("Classification",
      "Category"));
  }

}
