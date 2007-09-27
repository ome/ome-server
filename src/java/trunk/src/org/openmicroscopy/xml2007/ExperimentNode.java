/*
 * org.openmicroscopy.xml2007.ExperimentNode
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
 * This element describes the type of experiment.  The required Type attribute must contain one or more entries from the following list:
 * FP FRET Time-lapse 4-D+ Screen Immunocytochemistry FISH Electrophysiology  Ion-Imaging Colocalization PGI/Documentation
 * FRAP Photoablation Optical-Trapping Photoactivation Fluorescence-Lifetime Spectral-Imaging Other
 * FP refers to fluorescent proteins, PGI/Docuemntation is not a 'data' image.
 * The optional Description element may contain free text to further describe the experiment.
 * Added Type Photobleaching - ajp
 */
public class ExperimentNode extends OMEXMLNode {

  // -- Constructor --

  public ExperimentNode(Element element) { super(element); }

  // -- ExperimentNode API methods --

  public String getDescription() {
    return getCData("Description");
  }

  public void setDescription(String description) {
    setCData("Description", description);
  }

  /** This is a link to the Experimenter who conducted the experiment - ajp */
  public ExperimenterNode getExperimenter() {
    return (ExperimenterNode) getReferencedNode("Experimenter", "ExperimenterRef");
  }

  public int getMicrobeamManipulationCount() {
    return getChildCount("MicrobeamManipulationRef");
  }

  public Vector getMicrobeamManipulationList() {
    return getReferencedNodes("MicrobeamManipulation", "MicrobeamManipulationRef");
  }

  public String getType() {
    return getAttribute("Type");
  }

  public void setType(String type) {
    setAttribute("Type", type);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return true; }

}
