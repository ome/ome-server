/*
 * org.openmicroscopy.xml2007.TiffDataNode
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

public class TiffDataNode extends OMEXMLNode {

  // -- Constructor --

  public TiffDataNode(Element element) { super(element); }

  // -- TiffDataNode API methods --

  /**
   * Gives the IFD(s) for which this element is applicable. Indexed from 0.
   * Default is 0 (the first IFD).
   */
  public Integer getIFD() {
    return getIntegerAttribute("IFD");
  }

  public void setIFD(Integer ifd) {
    setAttribute("IFD", ifd);
  }

  /**
   * Gives the Z position of the image plane at the specified IFD. Indexed from 0.
   * Default is 0 (the first Z position).
   */
  public Integer getFirstZ() {
    return getIntegerAttribute("FirstZ");
  }

  public void setFirstZ(Integer firstZ) {
    setAttribute("FirstZ", firstZ);
  }

  /**
   * Gives the T position of the image plane at the specified IFD. Indexed from 0.
   * Default is 0 (the first T position).
   */
  public Integer getFirstT() {
    return getIntegerAttribute("FirstT");
  }

  public void setFirstT(Integer firstT) {
    setAttribute("FirstT", firstT);
  }

  /**
   * Gives the C position of the image plane at the specified IFD. Indexed from 0.
   * Default is 0 (the first C position).
   */
  public Integer getFirstC() {
    return getIntegerAttribute("FirstC");
  }

  public void setFirstC(Integer firstC) {
    setAttribute("FirstC", firstC);
  }

  /**
   * Gives the number of IFDs affected. Dimension order of IFDs is given by the enclosing
   * Pixels element's DimensionOrder attribute. Default is the number of IFDs in the TIFF
   * file, unless an IFD is specified, in which case the default is 1.
   */
  public Integer getNumPlanes() {
    return getIntegerAttribute("NumPlanes");
  }

  public void setNumPlanes(Integer numPlanes) {
    setAttribute("NumPlanes", numPlanes);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return false; }

}
