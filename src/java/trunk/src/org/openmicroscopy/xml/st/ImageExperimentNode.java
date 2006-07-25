/*
 * org.openmicroscopy.xml.ImageExperimentNode
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
 * ImageExperimentNode is the node corresponding to the
 * "ImageExperiment" XML element.
 *
 * Name: ImageExperiment
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: This specifies the Experiment an Image belongs to
 */
public class ImageExperimentNode extends AttributeNode
  implements ImageExperiment
{

  // -- Constructors --

  /**
   * Constructs an ImageExperiment node
   * with the given associated DOM element.
   */
  public ImageExperimentNode(Element element) { super(element); }

  /**
   * Constructs an ImageExperiment node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageExperimentNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an ImageExperiment node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageExperimentNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("ImageExperiment"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an ImageExperiment node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ImageExperimentNode(CustomAttributesNode parent,
    Experiment experiment)
  {
    this(parent, true);
    setExperiment(experiment);
  }


  // -- ImageExperiment API methods --

  /**
   * Gets Experiment referenced by Experiment
   * attribute of the ImageExperiment element.
   */
  public Experiment getExperiment() {
    return (Experiment)
      createReferencedNode(ExperimentNode.class,
      "Experiment", "Experiment");
  }

  /**
   * Sets Experiment referenced by Experiment
   * attribute of the ImageExperiment element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ExperimentNode
   */
  public void setExperiment(Experiment value) {
    setReferencedNode((OMEXMLNode) value, "Experiment", "Experiment");
  }

}
