/*
 * org.openmicroscopy.xml.GroupNode
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
 * GroupNode is the node corresponding to the
 * "Group" XML element.
 *
 * Name: Group
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Experimenter.ome
 * Description: Define grupos de investigadores. Esto puede ser un laboratorio
 *   o un proyecto grupal. No esta pensado para representar una institucion o
 *   compania
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
  public GroupNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Group node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public GroupNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Group", attach);
  }

  /**
   * Constructs a Group node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public GroupNode(CustomAttributesNode parent, String name,
    Experimenter leader, Experimenter contact)
  {
    this(parent, true);
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
    setAttribute("Name", value);  }

  /**
   * Gets Leader referenced by Experimenter
   * attribute of the Group element.
   */
  public Experimenter getLeader() {
    return (Experimenter)
      getAttrReferencedNode("Experimenter", "Leader");
  }

  /**
   * Sets Leader referenced by Experimenter
   * attribute of the Group element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setLeader(Experimenter value) {
    setAttrReferencedNode((OMEXMLNode) value, "Leader");
  }

  /**
   * Gets Contact referenced by Experimenter
   * attribute of the Group element.
   */
  public Experimenter getContact() {
    return (Experimenter)
      getAttrReferencedNode("Experimenter", "Contact");
  }

  /**
   * Sets Contact referenced by Experimenter
   * attribute of the Group element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setContact(Experimenter value) {
    setAttrReferencedNode((OMEXMLNode) value, "Contact");
  }

  /**
   * Gets a list of Experimenter elements
   * referencing this Group node.
   */
  public List getExperimenterList() {
    return getAttrReferringNodes("Experimenter", "Group");
  }

  /**
   * Gets the number of Experimenter elements
   * referencing this Group node.
   */
  public int countExperimenterList() {
    return getAttrReferringCount("Experimenter", "Group");
  }

  /**
   * Gets a list of ExperimenterGroup elements
   * referencing this Group node.
   */
  public List getExperimenterGroupList() {
    return getAttrReferringNodes("ExperimenterGroup", "Group");
  }

  /**
   * Gets the number of ExperimenterGroup elements
   * referencing this Group node.
   */
  public int countExperimenterGroupList() {
    return getAttrReferringCount("ExperimenterGroup", "Group");
  }

  /**
   * Gets a list of ImageGroup elements
   * referencing this Group node.
   */
  public List getImageGroupList() {
    return getAttrReferringNodes("ImageGroup", "Group");
  }

  /**
   * Gets the number of ImageGroup elements
   * referencing this Group node.
   */
  public int countImageGroupList() {
    return getAttrReferringCount("ImageGroup", "Group");
  }

}
