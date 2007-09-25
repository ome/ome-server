/*
 * org.openmicroscopy.xml2007.ImageNode
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
 * This element describes the actual image and its meta-data.
 * The elements that are references (ending in Ref) refer to elements defined outside of the Image element.
 * If any of the required Image attributes are missing, its guaranteed to be an invalid document.
 * The required elements are CreationDate and Pixels.
 * ExperimenterRef is required for all Images with well formed LSIDs.
 * ImageType is a vendor-specific designation of the type of image this is.
 * Examples of ImageType include 'STK', 'SoftWorx', etc.
 * The Name attributes are in all cases the name of the element instance. In this case, the name of the image,
 * not necessarily the filename.
 * PixelSize* is in microns.
 * TimeIncrement is used for time series that have a global timing specification instead of per-timepoint timing info.
 * For example in a video stream.  The unit is seconds.
 * Similarly, WaveStart and WaveIncrement are used in spectral images like FTIR.  These are both positive integers.
 */
public class ImageNode extends OMEXMLNode {

  // -- Constructor --

  public ImageNode(Element element) { super(element); }

  // -- ImageNode API methods --

  /**
   * The creation date of the Image - when the Image was acquired.
   * The element contains a string in the ISO 8601 dateTime format (i.e. 1988-04-07T18:39:09)
   */
  public String getCreationDate() {
    return getCData("CreationDate");
  }

  public void setCreationDate(String creationDate) {
    setCData("CreationDate", creationDate);
  }

  public ExperimenterNode getExperimenter() {
    return (ExperimenterNode) getReferencedNode("Experimenter", "ExperimenterRef");
  }

  public String getDescription() {
    return getCData("Description");
  }

  public void setDescription(String description) {
    setCData("Description", description);
  }

  public ExperimentNode getExperiment() {
    return (ExperimentNode) getReferencedNode("Experiment", "ExperimentRef");
  }

  public GroupNode getGroup() {
    return (GroupNode) getReferencedNode("Group", "GroupRef");
  }

  public int getDatasetCount() {
    return getChildCount("DatasetRef");
  }

  public Vector getDatasetList() {
    return getReferencedNodes("Dataset", "DatasetRef");
  }

  public InstrumentNode getInstrument() {
    return (InstrumentNode) getReferencedNode("Instrument", "InstrumentRef");
  }

  public ObjectiveSettingsNode getObjectiveSettings() {
    return (ObjectiveSettingsNode) getReferencedNode("ObjectiveSettings", "ObjectiveSettingsRef");
  }

  public ImagingEnvironmentNode getImagingEnvironment() {
    return (ImagingEnvironmentNode) getChildNode("ImagingEnvironment");
  }

  public ThumbnailNode getThumbnail() {
    return (ThumbnailNode) getChildNode("Thumbnail");
  }

  public int getLogicalChannelCount() {
    return getChildCount("LogicalChannel");
  }

  public Vector getLogicalChannelList() {
    return getChildNodes("LogicalChannel");
  }

  public DisplayOptionsNode getDisplayOptions() {
    return (DisplayOptionsNode) getChildNode("DisplayOptions");
  }

  public StageLabelNode getStageLabel() {
    return (StageLabelNode) getChildNode("StageLabel");
  }

  public int getPixelsCount() {
    return getChildCount("Pixels");
  }

  public Vector getPixelsList() {
    return getChildNodes("Pixels");
  }

  public PixelsNode getAcquiredPixels() {
    return (PixelsNode) getReferencedNode("Pixels", "AcquiredPixelsRef");
  }

  public int getRegionCount() {
    return getChildCount("Region");
  }

  public Vector getRegionList() {
    return getChildNodes("Region");
  }

  public CustomAttributesNode getCustomAttributes() {
    return (CustomAttributesNode) getChildNode("CustomAttributes");
  }

  public int getROICount() {
    return getChildCount("ROI");
  }

  public Vector getROIList() {
    return getChildNodes("ROI");
  }

  public int getMicrobeamManipulationCount() {
    return getChildCount("MicrobeamManipulation");
  }

  public Vector getMicrobeamManipulationList() {
    return getChildNodes("MicrobeamManipulation");
  }

  public String getName() {
    return getAttribute("Name");
  }

  public void setName(String name) {
    setAttribute("Name", name);
  }

  /**
   * More than one Pixels attribute may be associated with an Image. An Image will however have one "primary" set of Pixels. If a PixelsID is specified with this attribute, then that will be the "primary" pixels for this image. If this attribute
   * is not specified, then the FIRST &lt;Pixels> element under &lt;Image> will be assumed to be the "primary" set.
   */
  public PixelsNode getDefaultPixels() {
    return (PixelsNode) getAttrReferencedNode("Pixels", "DefaultPixels");
  }

}
