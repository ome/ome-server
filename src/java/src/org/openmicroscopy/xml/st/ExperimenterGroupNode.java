/*
 * org.openmicroscopy.xml.ExperimenterGroupNode
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
 * Created by curtis via Xmlgen on Dec 18, 2007 12:41:44 PM CST
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import ome.xml.OMEXMLNode;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ExperimenterGroupNode is the node corresponding to the
 * "ExperimenterGroup" XML element.
 *
 * Name: ExperimenterGroup
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Experimenter.ome
 * Description: Define la relacion entre investigadores y grupos.
 */
public class ExperimenterGroupNode extends AttributeNode
  implements ExperimenterGroup
{

  // -- Constructors --

  /**
   * Constructs an ExperimenterGroup node
   * with the given associated DOM element.
   */
  public ExperimenterGroupNode(Element element) { super(element); }

  /**
   * Constructs an ExperimenterGroup node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExperimenterGroupNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an ExperimenterGroup node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExperimenterGroupNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "ExperimenterGroup", attach);
  }

  /**
   * Constructs an ExperimenterGroup node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ExperimenterGroupNode(CustomAttributesNode parent,
    Experimenter experimenter, Group group)
  {
    this(parent, true);
    setExperimenter(experimenter);
    setGroup(group);
  }


  // -- ExperimenterGroup API methods --

  /**
   * Gets Experimenter referenced by Experimenter
   * attribute of the ExperimenterGroup element.
   */
  public Experimenter getExperimenter() {
    return (Experimenter)
      getAttrReferencedNode("Experimenter", "Experimenter");
  }

  /**
   * Sets Experimenter referenced by Experimenter
   * attribute of the ExperimenterGroup element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setExperimenter(Experimenter value) {
    setAttrReferencedNode((OMEXMLNode) value, "Experimenter");
  }

  /**
   * Gets Group referenced by Group
   * attribute of the ExperimenterGroup element.
   */
  public Group getGroup() {
    return (Group)
      getAttrReferencedNode("Group", "Group");
  }

  /**
   * Sets Group referenced by Group
   * attribute of the ExperimenterGroup element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of GroupNode
   */
  public void setGroup(Group value) {
    setAttrReferencedNode((OMEXMLNode) value, "Group");
  }

}
