/*
 * org.openmicroscopy.xml.ExperimenterNode
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
 * ExperimenterNode is the node corresponding to the
 * "Experimenter" XML element.
 *
 * Name: Experimenter
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Experimenter.ome
 * Description: Define a la persona que realiza experimentos con imagenes. Cada
 *   investigador puede pertenecer a uno o mas grupos.
 */
public class ExperimenterNode extends AttributeNode
  implements Experimenter
{

  // -- Constructors --

  /**
   * Constructs an Experimenter node
   * with the given associated DOM element.
   */
  public ExperimenterNode(Element element) { super(element); }

  /**
   * Constructs an Experimenter node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExperimenterNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an Experimenter node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExperimenterNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Experimenter", attach);
  }

  /**
   * Constructs an Experimenter node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ExperimenterNode(CustomAttributesNode parent, String firstName,
    String lastName, String email, String institution, String dataDirectory,
    Group group)
  {
    this(parent, true);
    setFirstName(firstName);
    setLastName(lastName);
    setEmail(email);
    setInstitution(institution);
    setDataDirectory(dataDirectory);
    setGroup(group);
  }


  // -- Experimenter API methods --

  /**
   * Gets FirstName attribute
   * of the Experimenter element.
   */
  public String getFirstName() {
    return getAttribute("FirstName");
  }

  /**
   * Sets FirstName attribute
   * for the Experimenter element.
   */
  public void setFirstName(String value) {
    setAttribute("FirstName", value);  }

  /**
   * Gets LastName attribute
   * of the Experimenter element.
   */
  public String getLastName() {
    return getAttribute("LastName");
  }

  /**
   * Sets LastName attribute
   * for the Experimenter element.
   */
  public void setLastName(String value) {
    setAttribute("LastName", value);  }

  /**
   * Gets Email attribute
   * of the Experimenter element.
   */
  public String getEmail() {
    return getAttribute("Email");
  }

  /**
   * Sets Email attribute
   * for the Experimenter element.
   */
  public void setEmail(String value) {
    setAttribute("Email", value);  }

  /**
   * Gets Institution attribute
   * of the Experimenter element.
   */
  public String getInstitution() {
    return getAttribute("Institution");
  }

  /**
   * Sets Institution attribute
   * for the Experimenter element.
   */
  public void setInstitution(String value) {
    setAttribute("Institution", value);  }

  /**
   * Gets DataDirectory attribute
   * of the Experimenter element.
   */
  public String getDataDirectory() {
    return getAttribute("DataDirectory");
  }

  /**
   * Sets DataDirectory attribute
   * for the Experimenter element.
   */
  public void setDataDirectory(String value) {
    setAttribute("DataDirectory", value);  }

  /**
   * Gets Group referenced by Group
   * attribute of the Experimenter element.
   */
  public Group getGroup() {
    return (Group)
      getAttrReferencedNode("Group", "Group");
  }

  /**
   * Sets Group referenced by Group
   * attribute of the Experimenter element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of GroupNode
   */
  public void setGroup(Group value) {
    setAttrReferencedNode((OMEXMLNode) value, "Group");
  }

  /**
   * Gets a list of RenderingSettings elements
   * referencing this Experimenter node.
   */
  public List getRenderingSettingsList() {
    return getAttrReferringNodes("RenderingSettings", "Experimenter");
  }

  /**
   * Gets the number of RenderingSettings elements
   * referencing this Experimenter node.
   */
  public int countRenderingSettingsList() {
    return getAttrReferringCount("RenderingSettings", "Experimenter");
  }

  /**
   * Gets a list of Experiment elements
   * referencing this Experimenter node.
   */
  public List getExperimentList() {
    return getAttrReferringNodes("Experiment", "Experimenter");
  }

  /**
   * Gets the number of Experiment elements
   * referencing this Experimenter node.
   */
  public int countExperimentList() {
    return getAttrReferringCount("Experiment", "Experimenter");
  }

  /**
   * Gets a list of Group elements
   * referencing this Experimenter node
   * via a Leader attribute.
   */
  public List getGroupListByLeader() {
    return getAttrReferringNodes("Group", "Leader");
  }

  /**
   * Gets the number of Group elements
   * referencing this Experimenter node
   * via a Leader attribute.
   */
  public int countGroupListByLeader() {
    return getAttrReferringCount("Group", "Leader");
  }

  /**
   * Gets a list of Group elements
   * referencing this Experimenter node
   * via a Contact attribute.
   */
  public List getGroupListByContact() {
    return getAttrReferringNodes("Group", "Contact");
  }

  /**
   * Gets the number of Group elements
   * referencing this Experimenter node
   * via a Contact attribute.
   */
  public int countGroupListByContact() {
    return getAttrReferringCount("Group", "Contact");
  }

  /**
   * Gets a list of ExperimenterGroup elements
   * referencing this Experimenter node.
   */
  public List getExperimenterGroupList() {
    return getAttrReferringNodes("ExperimenterGroup", "Experimenter");
  }

  /**
   * Gets the number of ExperimenterGroup elements
   * referencing this Experimenter node.
   */
  public int countExperimenterGroupList() {
    return getAttrReferringCount("ExperimenterGroup", "Experimenter");
  }

}
