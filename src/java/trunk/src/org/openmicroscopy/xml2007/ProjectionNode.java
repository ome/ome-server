/*
 * org.openmicroscopy.xml2007.ProjectionNode
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
 * The presence of this element indicates the user wants to view the Image as a maximum intensity projection.
 * The ZStart and ZStop attributes are optional.  If they are not specified, then the entire Z stack will be pro
 * z values are index from 0 to maxZ - 1
 */
public class ProjectionNode extends OMEXMLNode {

  // -- Constructor --

  public ProjectionNode(Element element) { super(element); }

  // -- ProjectionNode API methods --

  public Integer getZStart() {
    return getIntegerAttribute("ZStart");
  }

  public void setZStart(Integer zStart) {
    setAttribute("ZStart", zStart);
  }

  public Integer getZStop() {
    return getIntegerAttribute("ZStop");
  }

  public void setZStop(Integer zStop) {
    setAttribute("ZStop", zStop);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return false; }

}
