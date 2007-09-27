/*
 * org.openmicroscopy.xml2007.FilterNode
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
 * A filter is either an excitation or emission filters.
 * There should be one filter element specified per wavelength in the image. 
 * The channel number associated with a filter set is specified in LogicalChannel's required ChannelComponent element and its Index attribute.
 * It is based on the FilterSpec type, so has the required attributes Manufacturer, Model, and LotNumber.
 * It may also contain a Type attribute which may be set to
 * 'LongPass', 'ShortPass', 'BandPass', or 'MultiPass'.
 * It can be associated with an optional FilterWheel - Note: this is not the same as a FilterSet
 */
public class FilterNode extends FilterSpecNode {

  // -- Constructor --

  public FilterNode(Element element) { super(element); }

  // -- FilterNode API methods --

  public TransmittanceRangeNode getTransmittanceRange() {
    return (TransmittanceRangeNode) getChildNode("TransmittanceRange");
  }

  public String getType() {
    return getAttribute("Type");
  }

  public void setType(String type) {
    setAttribute("Type", type);
  }

  /** A filter 'wheel' in OME can refer to any arrangement of filters in a filter holder of any shape. It could, for example, be a filter slider. */
  public String getFilterWheel() {
    return getAttribute("FilterWheel");
  }

  public void setFilterWheel(String filterWheel) {
    setAttribute("FilterWheel", filterWheel);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return true; }

}
