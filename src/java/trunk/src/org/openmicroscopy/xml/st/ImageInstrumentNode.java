/*
 * org.openmicroscopy.xml.ImageInstrumentNode
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

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ImageInstrumentNode is the node corresponding to the
 * "ImageInstrument" XML element.
 *
 * Name: ImageInstrument
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: This specifies the Instrument associated with an Image
 */
public class ImageInstrumentNode extends AttributeNode
  implements ImageInstrument
{

  // -- Constructors --

  /**
   * Constructs an ImageInstrument node
   * with the given associated DOM element.
   */
  public ImageInstrumentNode(Element element) { super(element); }

  /**
   * Constructs an ImageInstrument node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ImageInstrumentNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("ImageInstrument"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs an ImageInstrument node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ImageInstrumentNode(OMEXMLNode parent, Instrument instrument,
    Objective objective)
  {
    this(parent);
    setInstrument(instrument);
    setObjective(objective);
  }


  // -- ImageInstrument API methods --

  /**
   * Gets Instrument referenced by Instrument
   * attribute of the ImageInstrument element.
   */
  public Instrument getInstrument() {
    return (Instrument)
      createReferencedNode(InstrumentNode.class,
      "Instrument", "Instrument");
  }

  /**
   * Sets Instrument referenced by Instrument
   * attribute of the ImageInstrument element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of InstrumentNode
   */
  public void setInstrument(Instrument value) {
    setReferencedNode((OMEXMLNode) value, "Instrument", "Instrument");
  }

  /**
   * Gets Objective referenced by Objective
   * attribute of the ImageInstrument element.
   */
  public Objective getObjective() {
    return (Objective)
      createReferencedNode(ObjectiveNode.class,
      "Objective", "Objective");
  }

  /**
   * Sets Objective referenced by Objective
   * attribute of the ImageInstrument element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ObjectiveNode
   */
  public void setObjective(Objective value) {
    setReferencedNode((OMEXMLNode) value, "Objective", "Objective");
  }

}
