/*
 * org.openmicroscopy.xml2007.FilterSpecNode
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

/**
 * An element type specifying a filter specification.
 * Unlike the ManufactSpec, filters are referred to by lot number rather than serial number.
 */
public class FilterSpecNode extends OMEXMLNode {

  // -- Constructor --

  public FilterSpecNode(Element element) { super(element); }

  // -- FilterSpecNode API methods --

  public String getManufacturer() {
    return getAttribute("Manufacturer");
  }

  public void setManufacturer(String manufacturer) {
    setAttribute("Manufacturer", manufacturer);
  }

  public String getModel() {
    return getAttribute("Model");
  }

  public void setModel(String model) {
    setAttribute("Model", model);
  }

  public String getLotNumber() {
    return getAttribute("LotNumber");
  }

  public void setLotNumber(String lotNumber) {
    setAttribute("LotNumber", lotNumber);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return false; }

}
