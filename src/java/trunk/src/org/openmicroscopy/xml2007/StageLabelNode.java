/*
 * org.openmicroscopy.xml2007.StageLabelNode
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
 * Created by user via NameOfAutogenerator on Sep 22, 2007 12:00:00 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml2007;

import org.w3c.dom.Element;

/** The StageLabel is used to specify a name and position for a stage position in the microscope's reference frame. */
public class StageLabelNode extends OMEXMLNode {

  // -- Constructor --

  public StageLabelNode(Element element) { super(element); }

  // -- StageLabelNode API methods --

  public String getName() {
    return getAttribute("Name");
  }

  public void setName(String name) {
    setAttribute("Name", name);
  }

  public Float getX() {
    return getFloatAttribute("X");
  }

  public void setX(Float x) {
    setFloatAttribute("X", x);
  }

  public Float getY() {
    return getFloatAttribute("Y");
  }

  public void setY(Float y) {
    setFloatAttribute("Y", y);
  }

  public Float getZ() {
    return getFloatAttribute("Z");
  }

  public void setZ(Float z) {
    setFloatAttribute("Z", z);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return false; }

}
