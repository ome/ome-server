/*
 * org.openmicroscopy.xml2007.OMENode
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
 * The OME element is a container for all information objects acessible by OME.  These information objects include descriptions of the imaging experiments
 * and the people who perform them, descriptions of the microscope, the resulting images and how they were acquired, the analyses performed on those images,
 * and the analysis results themselves.
 * An OME file may contain any or all of this information.
 */
public class OMENode extends OMEXMLNode {

  // -- Constructor --

  public OMENode(Element element) { super(element); }

  // -- OMENode API methods --

  public int getProjectCount() {
    return getChildCount("Project");
  }

  public Vector getProjectList() {
    return getChildNodes("Project");
  }

  public int getDatasetCount() {
    return getChildCount("Dataset");
  }

  public Vector getDatasetList() {
    return getChildNodes("Dataset");
  }

  public int getExperimentCount() {
    return getChildCount("Experiment");
  }

  public Vector getExperimentList() {
    return getChildNodes("Experiment");
  }

  public int getPlateCount() {
    return getChildCount("Plate");
  }

  public Vector getPlateList() {
    return getChildNodes("Plate");
  }

  public int getScreenCount() {
    return getChildCount("Screen");
  }

  public Vector getScreenList() {
    return getChildNodes("Screen");
  }

  public int getExperimenterCount() {
    return getChildCount("Experimenter");
  }

  public Vector getExperimenterList() {
    return getChildNodes("Experimenter");
  }

  public int getGroupCount() {
    return getChildCount("Group");
  }

  public Vector getGroupList() {
    return getChildNodes("Group");
  }

  public int getInstrumentCount() {
    return getChildCount("Instrument");
  }

  public Vector getInstrumentList() {
    return getChildNodes("Instrument");
  }

  public int getImageCount() {
    return getChildCount("Image");
  }

  public Vector getImageList() {
    return getChildNodes("Image");
  }

  public SemanticTypeDefinitionsNode getSemanticTypeDefinitions() {
    return (SemanticTypeDefinitionsNode) getChildNode("SemanticTypeDefinitions");
  }

  public AnalysisModuleLibraryNode getAnalysisModuleLibrary() {
    return (AnalysisModuleLibraryNode) getChildNode("AnalysisModuleLibrary");
  }

  public CustomAttributesNode getCustomAttributes() {
    return (CustomAttributesNode) getChildNode("CustomAttributes");
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return false; }

}
