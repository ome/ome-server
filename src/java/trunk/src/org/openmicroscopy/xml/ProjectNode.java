/*
 * org.openmicroscopy.xml.ProjectNode
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
import org.openmicroscopy.ds.dto.Project;
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.Group;
import org.openmicroscopy.xml.st.ExperimenterNode;
import org.openmicroscopy.xml.st.GroupNode;
import org.w3c.dom.Element;

/** ProjectNode is the node corresponding to the "Project" XML element. */
public class ProjectNode extends OMEXMLNode implements Project {

  // -- Constructors --

  /** Constructs a Project node with the given associated DOM element. */
  public ProjectNode(Element element) { super(element); }

  /**
   * Constructs a Project node,
   * creating its associated DOM element beneath the given parent.
   */
  public ProjectNode(OMENode parent) { this(parent, true); }

  /**
   * Constructs a Project node,
   * creating its associated DOM element beneath the given parent.
   */
  public ProjectNode(OMENode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().createElement("Project"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a Project node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ProjectNode(OMENode parent, String name, String description,
    ExperimenterNode experimenter, GroupNode group)
  {
    this(parent, true);
    setName(name);
    setDescription(description);
    setOwner(experimenter);
    setGroup(group);
  }


  // -- ProjectNode API methods --

  /** Gets Group referenced by Group attribute of the Project element. */
  public Group getGroup() {
    return (Group) createReferencedNode(GroupNode.class, "Group", "Group");
  }

  /**
   * Sets Group referenced by Group attribute of the Project element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of GroupNode
   */
  public void setGroup(Group value) {
    setReferencedNode((OMEXMLNode) value, "Group", "Group");
  }


  // -- Project API methods --

  /** Returns -1. Primary key IDs are not applicable for external OME-XML. */
  public int getID() { return -1; }

  /** Does nothing. Primary key IDs are not applicable for external OME-XML. */
  public void setID(int value) { }

  /** Gets Name attribute of the Project element. */
  public String getName() { return getAttribute("Name"); }

  /** Sets Name attribute for the Project element. */
  public void setName(String value) { setAttribute("Name", value); }

  /** Gets Description attribute of the Project element. */
  public String getDescription() { return getAttribute("Description"); }

  /** Sets Description attribute for the Project element. */
  public void setDescription(String value) {
    setAttribute("Description", value);
  }

  /**
   * Gets Experimenter referenced by Experimenter
   * attribute of the Project element.
   */
  public Experimenter getOwner() {
    return (Experimenter) createReferencedNode(ExperimenterNode.class,
      "Experimenter", "Experimenter");
  }

  /**
   * Sets Experimenter referenced by Experimenter
   * attribute of the Project element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setOwner(Experimenter value) {
    setReferencedNode((OMEXMLNode) value, "Experimenter", "Experimenter");
  }

  /** Gets a list of Datasets referencing this Project. */
  public List getDatasets() {
    return createReferralNodes(DatasetNode.class, "Dataset");
  }

  /** Gets the number of Datasets referencing this Project. */
  public int countDatasets() { return getSize(getReferrals("Dataset")); }

}
