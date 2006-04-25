/*
 * org.openmicroscopy.xml.GroupNode
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
 * GroupNode is the node corresponding to the
 * "Group" XML element.
 *
 * Name: Group
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Experimenter.ome
 * Description: Defines groups of experimenters. This can be a lab or a project
 *   group. It is not meant to represent an institution or a company.
 */
public class GroupNode extends AttributeNode
  implements Group
{

  // -- Constructors --

  /**
   * Constructs a Group node
   * with the given associated DOM element.
   */
  public GroupNode(Element element) { super(element); }

  /**
   * Constructs a Group node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public GroupNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("Group"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a Group node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public GroupNode(OMEXMLNode parent, String name, Experimenter leader,
    Experimenter contact)
  {
    this(parent);
    setName(name);
    setLeader(leader);
    setContact(contact);
  }


  // -- Group API methods --

  /**
   * Gets Name attribute
   * of the Group element.
   */
  public String getName() {
    return getAttribute("Name");
  }

  /**
   * Sets Name attribute
   * for the Group element.
   */
  public void setName(String value) {
    setAttribute("Name", value);
  }

  /**
   * Gets Leader referenced by Experimenter
   * attribute of the Group element.
   */
  public Experimenter getLeader() {
    return (Experimenter)
      createReferencedNode(ExperimenterNode.class,
      "Experimenter", "Leader");
  }

  /**
   * Sets Leader referenced by Experimenter
   * attribute of the Group element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setLeader(Experimenter value) {
    setReferencedNode((OMEXMLNode) value, "Experimenter", "Leader");
  }

  /**
   * Gets Contact referenced by Experimenter
   * attribute of the Group element.
   */
  public Experimenter getContact() {
    return (Experimenter)
      createReferencedNode(ExperimenterNode.class,
      "Experimenter", "Contact");
  }

  /**
   * Sets Contact referenced by Experimenter
   * attribute of the Group element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setContact(Experimenter value) {
    setReferencedNode((OMEXMLNode) value, "Experimenter", "Contact");
  }

  /**
   * Gets a list of Experimenter elements
   * referencing this Group node.
   */
  public List getExperimenterList() {
    return createAttrReferralNodes(ExperimenterNode.class,
      "Experimenter", "Group");
  }

  /**
   * Gets the number of Experimenter elements
   * referencing this Group node.
   */
  public int countExperimenterList() {
    return getSize(getAttrReferrals("Experimenter",
      "Group"));
  }

  /**
   * Gets a list of ExperimenterGroup elements
   * referencing this Group node.
   */
  public List getExperimenterGroupList() {
    return createAttrReferralNodes(ExperimenterGroupNode.class,
      "ExperimenterGroup", "Group");
  }

  /**
   * Gets the number of ExperimenterGroup elements
   * referencing this Group node.
   */
  public int countExperimenterGroupList() {
    return getSize(getAttrReferrals("ExperimenterGroup",
      "Group"));
  }

  /**
   * Gets a list of ImageGroup elements
   * referencing this Group node.
   */
  public List getImageGroupList() {
    return createAttrReferralNodes(ImageGroupNode.class,
      "ImageGroup", "Group");
  }

  /**
   * Gets the number of ImageGroup elements
   * referencing this Group node.
   */
  public int countImageGroupList() {
    return getSize(getAttrReferrals("ImageGroup",
      "Group"));
  }

}
