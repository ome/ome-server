/*
 * org.openmicroscopy.xml2007.TimeNode
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
 * The time range the user is interested in the initial viewer display.  A range of timepoints indicates a movie
 * If they are not specified, the movie is to include all timepoints.
 * If the Time attributes point to a single time-point, that is the timepoint to be initially displayed.
 * If the entire element is missing, the first time-point  will be displayed
 * t values are index from 0 to maxT - 1
 */
public class TimeNode extends OMEXMLNode {

  // -- Constructor --

  public TimeNode(Element element) { super(element); }

  // -- TimeNode API methods --

  public Integer getTStart() {
    return getIntegerAttribute("TStart");
  }

  public void setTStart(Integer tStart) {
    setAttribute("TStart", tStart);
  }

  public Integer getTStop() {
    return getIntegerAttribute("TStop");
  }

  public void setTStop(Integer tStop) {
    setAttribute("TStop", tStop);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return false; }

}
