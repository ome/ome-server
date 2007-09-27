/*
 * org.openmicroscopy.xml2007.ExperimenterNode
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

import java.util.Vector;
import org.w3c.dom.Element;

/**
 * An element type to specify an Experimenter under OME.
 * It consists of a Person element group and a login name specified under OMEName.
 */
public class ExperimenterNode extends OMEXMLNode {

  // -- Constructor --

  public ExperimenterNode(Element element) { super(element); }

  // -- ExperimenterNode API methods --

  public String getFirstName() {
    return getCData("FirstName");
  }

  public void setFirstName(String firstName) {
    setCData("FirstName", firstName);
  }

  public String getLastName() {
    return getCData("LastName");
  }

  public void setLastName(String lastName) {
    setCData("LastName", lastName);
  }

  public String getEmail() {
    return getCData("Email");
  }

  public void setEmail(String email) {
    setCData("Email", email);
  }

  public String getInstitution() {
    return getCData("Institution");
  }

  public void setInstitution(String institution) {
    setCData("Institution", institution);
  }

  public String getOMEName() {
    return getCData("OMEName");
  }

  public void setOMEName(String omeName) {
    setCData("OMEName", omeName);
  }

  public int getGroupCount() {
    return getChildCount("GroupRef");
  }

  public Vector getGroupList() {
    return getReferencedNodes("Group", "GroupRef");
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return true; }

}
