/*
 * org.openmicroscopy.xml.ExperimentNode
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
 * ExperimentNode is the node corresponding to the
 * "Experiment" XML element.
 *
 * Name: Experiment
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/Experiment.ome
 */
public class ExperimentNode extends AttributeNode
  implements Experiment
{

  // -- Constructors --

  /**
   * Constructs an Experiment node
   * with the given associated DOM element.
   */
  public ExperimentNode(Element element) { super(element); }

  /**
   * Constructs an Experiment node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExperimentNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an Experiment node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ExperimentNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("Experiment"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an Experiment node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ExperimentNode(OMEXMLNode parent, String type, String description,
    Experimenter experimenter)
  {
    this(parent, true);
    setType(type);
    setDescription(description);
    setExperimenter(experimenter);
  }


  // -- Experiment API methods --

  /**
   * Gets Type attribute
   * of the Experiment element.
   */
  public String getType() {
    return getAttribute("Type");
  }

  /**
   * Sets Type attribute
   * for the Experiment element.
   */
  public void setType(String value) {
    setAttribute("Type", value);
  }

  /**
   * Gets Description attribute
   * of the Experiment element.
   */
  public String getDescription() {
    return getAttribute("Description");
  }

  /**
   * Sets Description attribute
   * for the Experiment element.
   */
  public void setDescription(String value) {
    setAttribute("Description", value);
  }

  /**
   * Gets Experimenter referenced by Experimenter
   * attribute of the Experiment element.
   */
  public Experimenter getExperimenter() {
    return (Experimenter)
      createReferencedNode(ExperimenterNode.class,
      "Experimenter", "Experimenter");
  }

  /**
   * Sets Experimenter referenced by Experimenter
   * attribute of the Experiment element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimenterNode
   */
  public void setExperimenter(Experimenter value) {
    setReferencedNode((OMEXMLNode) value, "Experimenter", "Experimenter");
  }

  /**
   * Gets a list of ImageExperiment elements
   * referencing this Experiment node.
   */
  public List getImageExperimentList() {
    return createAttrReferralNodes(ImageExperimentNode.class,
      "ImageExperiment", "Experiment");
  }

  /**
   * Gets the number of ImageExperiment elements
   * referencing this Experiment node.
   */
  public int countImageExperimentList() {
    return getSize(getAttrReferrals("ImageExperiment",
      "Experiment"));
  }

}