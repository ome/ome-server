/*
 * org.openmicroscopy.xml.DatasetNode
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
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.Group;
import org.openmicroscopy.xml.st.ExperimenterNode;
import org.openmicroscopy.xml.st.GroupNode;
import org.w3c.dom.Element;

/** DatasetNode is the node corresponding to the "Dataset" XML element. */
public class DatasetNode extends OMEXMLNode implements Dataset {

  // -- Constructors --

  /** Constructs a Dataset node with the given associated DOM element. */
  public DatasetNode(Element element) { super(element); }

  /**
   * Constructs a Dataset node,
   * creating its associated DOM element beneath the given parent.
   */
  public DatasetNode(OMENode parent) {
    this(parent, null, null, null, null, null);
  }

  /**
   * Constructs a Dataset node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public DatasetNode(OMENode parent, String name, String description,
    Boolean locked, ExperimenterNode experimenter, GroupNode group)
  {
    super(parent.getDOMElement().getOwnerDocument().createElement("Dataset"));
    parent.getDOMElement().appendChild(element);
    setName(name);
    setDescription(description);
    setLocked(locked);
    setOwner(experimenter);
    setGroup(group);
  }


  // -- DatasetNode API methods --

  /** Gets Group referenced by Group attribute of the Dataset element. */
  public Group getGroup() {
    return (Group) getAttrReferencedNode("Group", "Group");
  }

  /**
   * Sets Group referenced by Group attribute of the Dataset element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of GroupNode
   */
  public void setGroup(Group value) {
    setAttrReferencedNode((OMEXMLNode) value, "Group");
  }

  /** Gets Locked attribute of the Dataset element. */
  public Boolean isLocked() { return getBooleanAttribute("Locked"); }

  /** Sets Locked attribute for the Dataset element. */
  public void setLocked(Boolean locked) { setAttribute("Locked", locked); }

  /** Gets node corresponding to CustomAttributes child element. */
  public CustomAttributesNode getCustomAttributes() {
    return (CustomAttributesNode) getChildNode("CustomAttributes");
  }

  /** Adds this Dataset to a Project. */
  public void addToProject(ProjectNode project) { createReference(project); }

  /** Adds the given Image to this Dataset. */
  public void addImage(ImageNode image) { image.addToDataset(this); }


  // -- Dataset API methods --

  /** Returns -1. Primary key IDs are not applicable for external OME-XML. */
  public int getID() { return -1; }

  /** Does nothing. Primary key IDs are not applicable for external OME-XML. */
  public void setID(int value) { }

  /** Gets Name attribute of the Dataset element. */
  public String getName() { return getAttribute("Name"); }

  /** Sets Name attribute for the Dataset element. */
  public void setName(String value) { setAttribute("Name", value); }

  /** Gets Description attribute of the Dataset element. */
  public String getDescription() { return getAttribute("Description"); }

  /** Sets Description attribute for the Dataset element. */
  public void setDescription(String value) {
    setAttribute("Description", value);
  }

  /**
   * Gets Experimenter referenced by Experimenter
   * attribute of the Dataset element.
   */
  public Experimenter getOwner() {
    return (Experimenter) getAttrReferencedNode("Experimenter", "Experimenter");
  }

  /**
   * Sets Experimenter referenced by Experimenter
   * attribute of the Dataset element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setOwner(Experimenter value) {
    setAttrReferencedNode((OMEXMLNode) value, "Experimenter");
  }

  /** Gets a list of Projects referenced by the Dataset. */
  public List getProjects() {
    return getReferencedNodes("Project", "ProjectRef");
  }

  /** Gets the number of Projects referenced by the Dataset. */
  public int countProjects() { return getChildCount("ProjectRef"); }

  /** Gets a list of Images referencing this Dataset. */
  public List getImages() { return getReferringNodes("Image"); }

  /** Gets the number of Images referencing this Dataset. */
  public int countImages() { return getReferringCount("Image"); }

}
