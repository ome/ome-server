/*
 * org.openmicroscopy.xml.SampleTest
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2006 Open Microscopy Environment
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
 * Written by:    Curtis Rueden <ctrueden@wisc.edu>
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml;

import java.io.*;
import java.util.List;
import org.openmicroscopy.xml.st.*;

/** Tests the org.openmicroscopy.xml package. */
public abstract class SampleTest {

  // -- Testing methods --

  /** Tests the integrity of the given node against the Sample.ome file. */
  public static void testSample(OMENode ome) throws Exception {
    // -- Depth 1 --

    // check OME node
    int projectCount = ome.countProjects();
    List projectList = ome.getProjects();
    if (projectCount != 1 || projectList.size() != 1) {
      System.out.println("Error: Incorrect number of Projects" +
        " (projectCount=" + projectCount +
        ", projectList.size()=" + projectList.size() + ")");
    }
    int datasetCount = ome.countDatasets();
    List datasetList = ome.getDatasets();
    if (datasetCount != 1 || datasetList.size() != 1) {
      System.out.println("Error: Incorrect number of Datasets" +
        " (datasetCount=" + datasetCount +
        ", datasetList.size()=" + datasetList.size() + ")");
    }
    int imageCount = ome.countImages();
    List imageList = ome.getImages();
    if (imageCount != 1 || imageList.size() != 1) {
      System.out.println("Error: Incorrect number of Images" +
        " (imageCount=" + imageCount +
        ", imageList.size()=" + imageList.size() + ")");
    }

    // -- Depth 2 --

    // check OME/Project node
    ProjectNode project = (ProjectNode) projectList.get(0);
    String projectID = project.getNodeID();
    if (!projectID.equals("urn:lsid:foo.bar.com:Project:123456")) {
      System.out.println("Error: Incorrect Project ID (" + projectID + ")");
    }
    String projectName = project.getName();
    if (!projectName.equals("Stress Response Pathway")) {
      System.out.println("Error: Incorrect Project Name (" +
        projectName + ")");
    }
    String projectDescription = project.getDescription();
    if (projectDescription != null) {
      System.out.println("Error: Project Description " +
        "is not null as expected (" + projectDescription + ")");
    }
    int projectDatasetCount = project.countDatasets();
    List projectDatasetList = project.getDatasets();
    if (projectDatasetCount != 1 || projectDatasetList.size() != 1) {
      System.out.println("Error: Incorrect number of Project Datasets" +
        " (projectDatasetCount=" + projectDatasetCount +
        ", projectDatasetList.size()=" + projectDatasetList.size() + ")");
    }

    // check OME/Dataset node
    DatasetNode dataset = (DatasetNode) datasetList.get(0);
    String datasetID = dataset.getNodeID();
    if (!datasetID.equals("urn:lsid:foo.bar.com:Dataset:123456")) {
      System.out.println("Error: Incorrect Dataset ID (" + datasetID + ")");
    }
    Boolean datasetLocked = dataset.isLocked();
    if (datasetLocked.booleanValue() != false) {
      System.out.println("Error: Incorrect Dataset Locked (" +
        datasetLocked + ")");
    }
    String datasetName = dataset.getName();
    if (!datasetName.equals("Controls")) {
      System.out.println("Error: Incorrect Dataset Name (" +
        datasetName + ")");
    }
    String datasetDescription = dataset.getDescription();
    if (datasetDescription != null) {
      System.out.println("Error: Dataset Description " +
        "is not null as expected (" + datasetDescription + ")");
    }
    int datasetProjectCount = dataset.countProjects();
    List datasetProjectList = dataset.getProjects();
    if (datasetProjectCount != 1 || datasetProjectList.size() != 1) {
      System.out.println("Error: Incorrect number of Dataset Projects" +
        " (datasetProjectCount=" + datasetProjectCount +
        ", datasetProjectList.size()=" + datasetProjectList.size() + ")");
    }
    int datasetImageCount = dataset.countImages();
    List datasetImageList = dataset.getImages();
    if (datasetImageCount != 1 || datasetImageList.size() != 1) {
      System.out.println("Error: Incorrect number of Dataset Images" +
        " (datasetImageCount=" + datasetImageCount +
        ", datasetImageList.size()=" + datasetImageList.size() + ")");
    }

    // check OME/Image node
    ImageNode image = (ImageNode) imageList.get(0);
    String imageID = image.getNodeID();
    if (!imageID.equals("urn:lsid:foo.bar.com:Image:123456")) {
      System.out.println("Error: Incorrect Image ID (" + imageID + ")");
    }
    String imageName = image.getName();
    if (!imageName.equals("P1W1S1")) {
      System.out.println("Error: Incorrect Image Name (" +
        imageName + ")");
    }
    String imageDescription = image.getDescription();
    if (!imageDescription.equals("This is an Image")) {
      System.out.println("Error: Incorrect Image Description (" +
        imageDescription + ")");
    }
    String imageCreated = image.getCreated();
    if (!imageCreated.equals("1988-04-07T18:39:09")) {
      System.out.println("Error: Incorrect Image CreationDate (" +
        imageCreated + ")");
    }
    int imageDatasetCount = image.countDatasets();
    List imageDatasetList = image.getDatasets();
    if (imageDatasetCount != 1 || imageDatasetList.size() != 1) {
      System.out.println("Error: Incorrect number of Image Datasets" +
        " (imageDatasetCount=" + imageDatasetCount +
        ", imageDatasetList.size()=" + imageDatasetList.size() + ")");
    }
    int imageFeatureCount = image.countFeatures();
    List imageFeatureList = image.getFeatures();
    if (imageFeatureCount != 0 || imageFeatureList.size() != 0) {
      System.out.println("Error: Incorrect number of Image Features" +
        " (imageFeatureCount=" + imageFeatureCount +
        ", imageFeatureList.size()=" + imageFeatureList.size() + ")");
    }

    // check OME/CA node
    CustomAttributesNode omeCA = ome.getCustomAttributes();
    int omeCACount = omeCA.countCAList();
    List omeCAList = omeCA.getCAList();
    if (omeCACount != 19 || omeCAList.size() != 19) {
      System.out.println("Error: Incorrect number of CAs" +
        " (omeCACount=" + omeCACount +
        ", omeCAList.size()=" + omeCAList.size() + ")");
    }

    // -- Depth 3 --

    // check OME/Project/Group node
    GroupNode projectGroup = (GroupNode) project.getGroup();
    String projectGroupID = projectGroup.getNodeID();
    if (!projectGroupID.equals("urn:lsid:foo.bar.com:Group:123456")) {
      System.out.println("Error: Incorrect Project Group ID (" +
        projectGroupID + ")");
    }
    String projectGroupName = projectGroup.getName();
    if (!projectGroupName.equals("IICBU")) {
      System.out.println("Error: Incorrect Project Group Name (" +
        projectGroupName + ")");
    }
    int projectGroupExperimenterCount = projectGroup.countExperimenterList();
    List projectGroupExperimenterList = projectGroup.getExperimenterList();
    if (projectGroupExperimenterCount != 1 ||
      projectGroupExperimenterList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Project Group " +
        "Experimenters (projectGroupExperimenterCount=" +
        projectGroupExperimenterCount +
        ", projectGroupExperimenterList.size()=" +
        projectGroupExperimenterList.size() + ")");
    }
    int projectGroupExperimenterGroupCount =
      projectGroup.countExperimenterGroupList();
    List projectGroupExperimenterGroupList =
      projectGroup.getExperimenterGroupList();
    if (projectGroupExperimenterGroupCount != 1 ||
      projectGroupExperimenterGroupList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Project Group " +
        "Experimenter Groups (projectGroupExperimenterGroupCount=" +
        projectGroupExperimenterGroupCount +
        ", projectGroupExperimenterGroupList.size()=" +
        projectGroupExperimenterGroupList.size() + ")");
    }
    int projectGroupImageGroupCount = projectGroup.countImageGroupList();
    List projectGroupImageGroupList = projectGroup.getImageGroupList();
    if (projectGroupImageGroupCount != 0 ||
      projectGroupImageGroupList.size() != 0)
    {
      System.out.println("Error: Incorrect number of Project Group " +
        "Image Groups (projectGroupImageGroupCount=" +
        projectGroupImageGroupCount +
        ", projectGroupImageGroupList.size()=" +
        projectGroupImageGroupList.size() + ")");
    }

    // check OME/Project/Owner node
    ExperimenterNode projectOwner = (ExperimenterNode) project.getOwner();
    String projectOwnerID = projectOwner.getNodeID();
    if (!projectOwnerID.equals("urn:lsid:foo.bar.com:Experimenter:123456")) {
      System.out.println("Error: Incorrect Project Owner ID (" +
        projectOwnerID + ")");
    }
    String projectOwnerFirstName = projectOwner.getFirstName();
    if (!projectOwnerFirstName.equals("Nicola")) {
      System.out.println("Error: Incorrect Project Owner FirstName (" +
        projectOwnerFirstName + ")");
    }
    String projectOwnerLastName = projectOwner.getLastName();
    if (!projectOwnerLastName.equals("Sacco")) {
      System.out.println("Error: Incorrect Project Owner LastName (" +
        projectOwnerLastName + ")");
    }
    String projectOwnerEmail = projectOwner.getEmail();
    if (!projectOwnerEmail.equals("Nicola.Sacco@justice.net")) {
      System.out.println("Error: Incorrect Project Owner Email (" +
        projectOwnerEmail + ")");
    }
    String projectOwnerInstitution = projectOwner.getInstitution();
    if (projectOwnerInstitution != null) {
      System.out.println("Error: Project Owner Institution " +
        "is not null as expected (" + projectOwnerInstitution + ")");
    }
    String projectOwnerDataDirectory = projectOwner.getDataDirectory();
    if (projectOwnerDataDirectory != null) {
      System.out.println("Error: Project Owner DataDirectory " +
        "is not null as expected (" + projectOwnerDataDirectory + ")");
    }
    int projectOwnerRenderingSettingsCount =
      projectOwner.countRenderingSettingsList();
    List projectOwnerRenderingSettingsList =
      projectOwner.getRenderingSettingsList();
    if (projectOwnerRenderingSettingsCount != 0 ||
      projectOwnerRenderingSettingsList.size() != 0)
    {
      System.out.println("Error: Incorrect number of Project Owner " +
        "RenderingSettings (projectOwnerRenderingSettingsCount=" +
        projectOwnerRenderingSettingsCount +
        ", projectOwnerRenderingSettingsList.size()=" +
        projectOwnerRenderingSettingsList.size() + ")");
    }
    int projectOwnerExperimentCount = projectOwner.countExperimentList();
    List projectOwnerExperimentList = projectOwner.getExperimentList();
    if (projectOwnerExperimentCount != 1 ||
      projectOwnerExperimentList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Project Owner " +
        "Experimenters (projectOwnerExperimentCount=" +
        projectOwnerExperimentCount +
        ", projectOwnerExperimentList.size()=" +
        projectOwnerExperimentList.size() + ")");
    }
    int projectOwnerGroupsByLeaderCount =
      projectOwner.countGroupListByLeader();
    List projectOwnerGroupsByLeaderList =
      projectOwner.getGroupListByLeader();
    if (projectOwnerGroupsByLeaderCount != 1 ||
      projectOwnerGroupsByLeaderList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Project Owner " +
        "Groups by Leader (projectOwnerGroupsByLeaderCount=" +
        projectOwnerGroupsByLeaderCount +
        ", projectOwnerGroupsByLeaderList.size()=" +
        projectOwnerGroupsByLeaderList.size() + ")");
    }
    int projectOwnerGroupsByContactCount =
      projectOwner.countGroupListByContact();
    List projectOwnerGroupsByContactList =
      projectOwner.getGroupListByContact();
    if (projectOwnerGroupsByContactCount != 1 ||
      projectOwnerGroupsByContactList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Project Owner " +
        "Groups by Contacts (projectOwnerGroupsByContactCount=" +
        projectOwnerGroupsByContactCount +
        ", projectOwnerGroupsByContactList.size()=" +
        projectOwnerGroupsByContactList.size() + ")");
    }
    int projectOwnerExperimenterGroupCount =
      projectOwner.countExperimenterGroupList();
    List projectOwnerExperimenterGroupList =
      projectOwner.getExperimenterGroupList();
    if (projectOwnerExperimenterGroupCount != 2 ||
      projectOwnerExperimenterGroupList.size() != 2)
    {
      System.out.println("Error: Incorrect number of Project Owner " +
        "ExperimenterGroups (projectOwnerExperimenterGroupCount=" +
        projectOwnerExperimenterGroupCount +
        ", projectOwnerExperimenterGroupList.size()=" +
        projectOwnerExperimenterGroupList.size() + ")");
    }

    // check OME/Project/Dataset node
    DatasetNode projectDataset = (DatasetNode) projectDatasetList.get(0);
    if (!projectDataset.equals(dataset)) {
      System.out.println("Error: Project Dataset does not match Dataset");
    }

    // check OME/Dataset/Group node
    GroupNode datasetGroup = (GroupNode) dataset.getGroup();
    if (!datasetGroup.equals(projectGroup)) {
      System.out.println(
        "Error: Dataset Group does not match Project Group");
    }

    // check OME/Dataset/Project node
    ProjectNode datasetProject = (ProjectNode) datasetProjectList.get(0);
    if (!datasetProject.equals(project)) {
      System.out.println("Error: Dataset Project does not match Project");
    }

    // check OME/Dataset/Image node
    ImageNode datasetImage = (ImageNode) datasetImageList.get(0);
    if (!datasetImage.equals(image)) {
      System.out.println("Error: Dataset Image does not match Image");
    }

    // check OME/Dataset/Owner node
    ExperimenterNode datasetOwner = (ExperimenterNode) dataset.getOwner();
    if (!datasetOwner.equals(projectOwner)) {
      System.out.println(
        "Error: Dataset Owner does not match Project Owner");
    }

    // check OME/Dataset/CA node
    CustomAttributesNode datasetCA = dataset.getCustomAttributes();
    if (datasetCA != null) {
      System.out.println(
        "Error: Dataset CA is not null as expected (" + datasetCA + ")");
    }

    // check OME/Image/Group node
    GroupNode imageGroup = (GroupNode) image.getGroup();
    if (!imageGroup.equals(projectGroup)) {
      System.out.println("Error: Image Group does not match Project Group");
    }

    // check OME/Image/Owner node
    ExperimenterNode imageOwner = (ExperimenterNode) image.getOwner();
    if (!imageOwner.equals(projectOwner)) {
      System.out.println(
        "Error: Image Owner does not match Project Owner");
    }

    // check OME/Image/DefaultPixels node
    PixelsNode imagePixels = (PixelsNode) image.getDefaultPixels();
    String imagePixelsID = imagePixels.getNodeID();
    if (!imagePixelsID.equals("urn:lsid:foo.bar.com:Pixels:123456")) {
      System.out.println("Error: Incorrect Image Pixels ID (" +
        imagePixelsID + ")");
    }
    Boolean imagePixelsBigEndian = imagePixels.isBigEndian();
    if (!imagePixelsBigEndian.booleanValue()) {
      System.out.println("Error: Incorrect Image DefaultPixels BigEndian (" +
        imagePixelsBigEndian + ")");
    }
    String imagePixelsDimensionOrder = imagePixels.getDimensionOrder();
    if (!imagePixelsDimensionOrder.equals("XYZCT")) {
      System.out.println("Error: Incorrect Image DefaultPixels " +
        "DimensionOrder (" + imagePixelsBigEndian + ")");
    }
    Integer imagePixelsSizeX = imagePixels.getSizeX();
    if (imagePixelsSizeX.intValue() != 20) {
      System.out.println("Error: Incorrect Image DefaultPixels SizeX (" +
        imagePixelsSizeX + ")");
    }
    Integer imagePixelsSizeY = imagePixels.getSizeY();
    if (imagePixelsSizeY.intValue() != 20) {
      System.out.println("Error: Incorrect Image DefaultPixels SizeY (" +
        imagePixelsSizeY + ")");
    }
    Integer imagePixelsSizeZ = imagePixels.getSizeZ();
    if (imagePixelsSizeZ.intValue() != 5) {
      System.out.println("Error: Incorrect Image DefaultPixels SizeZ (" +
        imagePixelsSizeZ + ")");
    }
    Integer imagePixelsSizeC = imagePixels.getSizeC();
    if (imagePixelsSizeC.intValue() != 1) {
      System.out.println("Error: Incorrect Image DefaultPixels SizeC (" +
        imagePixelsSizeC + ")");
    }
    Integer imagePixelsSizeT = imagePixels.getSizeT();
    if (imagePixelsSizeT.intValue() != 6) {
      System.out.println("Error: Incorrect Image DefaultPixels SizeT (" +
        imagePixelsSizeT + ")");
    }
    String imagePixelsPixelType = imagePixels.getPixelType();
    if (!imagePixelsPixelType.equals("int16")) {
      System.out.println("Error: Incorrect Image DefaultPixels " +
        "PixelType (" + imagePixelsPixelType + ")");
    }
    //String imagePixelsFileSHA1 = imagePixels.getFileSHA1();
    //if (!imagePixelsFileSHA1.equals("")) {
    //  System.out.println("Error: Incorrect Image DefaultPixels " +
    //    "FileSHA1 (" + imagePixelsFileSHA1 + ")");
    //}
    //Long imagePixelsImageServerID = imagePixels.getImageServerID();
    //if (!imagePixelsImageServerID.equals("")) {
    //  System.out.println("Error: Incorrect Image DefaultPixels " +
    //    "ImageServerID  (" + imagePixelsImageServerID + ")");
    //}
    int imagePixelsPixelChannelComponentCount =
      imagePixels.countPixelChannelComponentList();
    List imagePixelsPixelChannelComponentList =
      imagePixels.getPixelChannelComponentList();
    if (imagePixelsPixelChannelComponentCount != 1 ||
      imagePixelsPixelChannelComponentList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Image " +
        "DefaultPixels PixelChannelComponents " +
        "(imagePixelsPixelChannelComponentCount=" +
        imagePixelsPixelChannelComponentCount +
        ", imagePixelsPixelChannelComponentList.size()=" +
        imagePixelsPixelChannelComponentList.size() + ")");
    }
    //int imagePixelsDisplayOptionsCount =
    //  imagePixels.countDisplayOptionsList();
    //List imagePixelsDisplayOptionsList =
    //  imagePixels.getDisplayOptionsList();
    //if (imagePixelsDisplayOptionsCount != 1 ||
    //  imagePixelsDisplayOptionsList.size() != 1)
    //{
    //  System.out.println("Error: Incorrect number of Image " +
    //    "DefaultPixels DisplayOptionses " +
    //    "(imagePixelsDisplayOptionsCount=" +
    //    imagePixelsDisplayOptionsCount +
    //    ", imagePixelsDisplayOptionsList.size()=" +
    //    imagePixelsDisplayOptionsList.size() + ")");
    //}

    // check OME/Image/Dataset node
    DatasetNode imageDataset = (DatasetNode) imageDatasetList.get(0);
    if (!imageDataset.equals(dataset)) {
      System.out.println("Error: Image Dataset does not match Dataset");
    }

    // check OME/Image/CA node
    CustomAttributesNode imageCA = image.getCustomAttributes();
    int imageCACount = imageCA.countCAList();
    List imageCAList = imageCA.getCAList();
    if (imageCACount != 16 || imageCAList.size() != 16) {
      System.out.println("Error: Incorrect number of Image " +
        "CAs (imageCACount=" + imageCACount +
        ", imageCAList.size()=" + imageCAList.size() + ")");
    }

    // check OME/CA/Experimenter node
    ExperimenterNode experimenter = (ExperimenterNode) omeCAList.get(0);
    if (!experimenter.equals(projectOwner)) {
      System.out.println(
        "Error: CA Experimenter does not match Project Owner");
    }

    // check first OME/CA/ExperimenterGroup node
    ExperimenterGroupNode experimenterGroup1 =
      (ExperimenterGroupNode) omeCAList.get(1);

    // check second OME/CA/ExperimenterGroup node
    ExperimenterGroupNode experimenterGroup2 =
      (ExperimenterGroupNode) omeCAList.get(2);

    // check OME/CA/Group node
    GroupNode group = (GroupNode) omeCAList.get(3);
    if (!group.equals(projectGroup)) {
      System.out.println("Error: CA Group does not match Project Group");
    }

    // check OME/CA/Experiment node
    ExperimentNode experiment = (ExperimentNode) omeCAList.get(4);
    String experimentID = experiment.getNodeID();
    if (!experimentID.equals("urn:lsid:foo.bar.com:Experiment:123456")) {
      System.out.println("Error: Incorrect CA Experiment ID (" +
        experimentID + ")");
    }
    String experimentType = experiment.getType();
    if (!experimentType.equals("Time-lapse")) {
      System.out.println("Error: Incorrect CA Experiment " +
        "Type (" + experimentType + ")");
    }
    String experimentDescription = experiment.getDescription();
    if (!experimentDescription.equals("This was an experiment.")) {
      System.out.println("Error: Incorrect CA Experiment Description (" +
        experimentDescription + ")");
    }
    int experimentImageExperimentCount =
      experiment.countImageExperimentList();
    List experimentImageExperimentList = experiment.getImageExperimentList();
    if (experimentImageExperimentCount != 1 ||
      experimentImageExperimentList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Project Owner " +
        "Experiment ImageExperiments (experimentImageExperimentCount=" +
        experimentImageExperimentCount +
        ", experimentImageExperimentList.size()=" +
        experimentImageExperimentList.size() + ")");
    }

    // check OME/CA/Instrument node
    InstrumentNode instrument = (InstrumentNode) omeCAList.get(5);
    String instrumentID = instrument.getNodeID();
    if (!instrumentID.equals("urn:lsid:foo.bar.com:Instrument:123456")) {
      System.out.println("Error: Incorrect CA Instrument ID (" +
        instrumentID + ")");
    }
    String instrumentManufacturer = instrument.getManufacturer();
    if (!instrumentManufacturer.equals("Zeiss")) {
      System.out.println("Error: Incorrect CA Instrument Manufacturer (" +
        instrumentManufacturer + ")");
    }
    String instrumentModel = instrument.getModel();
    if (!instrumentModel.equals("foo")) {
      System.out.println("Error: Incorrect CA Instrument Model (" +
        instrumentModel + ")");
    }
    String instrumentSerialNumber = instrument.getSerialNumber();
    if (!instrumentSerialNumber.equals("bar")) {
      System.out.println("Error: Incorrect CA Instrument SerialNumber (" +
        instrumentSerialNumber + ")");
    }
    String instrumentType = instrument.getType();
    if (!instrumentType.equals("Upright")) {
      System.out.println("Error: Incorrect CA Instrument Type (" +
        instrumentType + ")");
    }
    int instrumentImageInstrumentCount =
      instrument.countImageInstrumentList();
    List instrumentImageInstrumentList = instrument.getImageInstrumentList();
    if (instrumentImageInstrumentCount != 1 ||
      instrumentImageInstrumentList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Instrument " +
        "ImageInstruments (instrumentImageInstrumentCount=" +
        instrumentImageInstrumentCount +
        ", instrumentImageInstrumentList.size()=" +
        instrumentImageInstrumentList.size() + ")");
    }
    int instrumentLightSourceCount = instrument.countLightSourceList();
    List instrumentLightSourceList = instrument.getLightSourceList();
    if (instrumentLightSourceCount != 2 ||
      instrumentLightSourceList.size() != 2)
    {
      System.out.println("Error: Incorrect number of Instrument " +
        "LightSources (instrumentLightSourceCount=" +
        instrumentLightSourceCount + ", instrumentLightSourceList.size()=" +
        instrumentLightSourceList.size() + ")");
    }
    int instrumentDetectorCount = instrument.countDetectorList();
    List instrumentDetectorList = instrument.getDetectorList();
    if (instrumentDetectorCount != 1 ||
      instrumentDetectorList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Instrument " +
        "Detectors (instrumentDetectorCount=" + instrumentDetectorCount +
        ", instrumentDetectorList.size()=" +
        instrumentDetectorList.size() + ")");
    }
    int instrumentObjectiveCount = instrument.countObjectiveList();
    List instrumentObjectiveList = instrument.getObjectiveList();
    if (instrumentObjectiveCount != 1 ||
      instrumentObjectiveList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Instrument " +
        "Objectives (instrumentObjectiveCount=" +
        instrumentObjectiveCount + ", instrumentObjectiveList.size()=" +
        instrumentObjectiveList.size() + ")");
    }
    int instrumentFilterCount = instrument.countFilterList();
    List instrumentFilterList = instrument.getFilterList();
    if (instrumentFilterCount != 1 ||
      instrumentFilterList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Instrument " +
        "Filters (instrumentFilterCount=" + instrumentFilterCount +
        ", instrumentFilterList.size()=" +
        instrumentFilterList.size() + ")");
    }
    int instrumentOTFCount = instrument.countOTFList();
    List instrumentOTFList = instrument.getOTFList();
    if (instrumentOTFCount != 1 || instrumentOTFList.size() != 1) {
      System.out.println("Error: Incorrect number of Instrument " +
        "OTFs (instrumentOTFCount=" + instrumentOTFCount +
        ", instrumentOTFList.size()=" + instrumentOTFList.size() + ")");
    }

    // check first OME/CA/LightSource node
    LightSourceNode lightSource1 = (LightSourceNode) omeCAList.get(6);
    String lightSource1ID = lightSource1.getNodeID();
    if (!lightSource1ID.equals("urn:lsid:foo.bar.com:LightSource:123456")) {
      System.out.println("Error: Incorrect first CA LightSource ID (" +
        lightSource1ID + ")");
    }
    String lightSource1Manufacturer = lightSource1.getManufacturer();
    if (!lightSource1Manufacturer.equals("Olympus")) {
      System.out.println("Error: Incorrect first CA LightSource " +
        "Manufacturer (" + lightSource1Manufacturer + ")");
    }
    String lightSource1Model = lightSource1.getModel();
    if (!lightSource1Model.equals("WMD Laser")) {
      System.out.println("Error: Incorrect first CA LightSource " +
        "Model (" + lightSource1Model + ")");
    }
    String lightSource1SerialNumber = lightSource1.getSerialNumber();
    if (!lightSource1SerialNumber.equals("123skdjhf1234")) {
      System.out.println("Error: Incorrect first CA LightSource " +
        "SerialNumber (" + lightSource1SerialNumber + ")");
    }
    int lightSource1LogicalChannelsByLightSourceCount =
      lightSource1.countLogicalChannelListByLightSource();
    List lightSource1LogicalChannelsByLightSourceList =
      lightSource1.getLogicalChannelListByLightSource();
    if (lightSource1LogicalChannelsByLightSourceCount != 0 ||
      lightSource1LogicalChannelsByLightSourceList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first CA LightSource " +
        "LogicalChannels by LightSource " +
        "(lightSource1LogicalChannelsByLightSourceCount=" +
        lightSource1LogicalChannelsByLightSourceCount +
        ", lightSource1LogicalChannelsByLightSourceList.size()=" +
        lightSource1LogicalChannelsByLightSourceList.size() + ")");
    }
    int lightSource1LogicalChannelsByAuxLightSourceCount =
      lightSource1.countLogicalChannelListByAuxLightSource();
    List lightSource1LogicalChannelsByAuxLightSourceList =
      lightSource1.getLogicalChannelListByAuxLightSource();
    if (lightSource1LogicalChannelsByAuxLightSourceCount != 1 ||
      lightSource1LogicalChannelsByAuxLightSourceList.size() != 1)
    {
      System.out.println("Error: Incorrect number of first CA LightSource " +
        "LogicalChannels by AuxLightSource " +
        "(lightSource1LogicalChannelsByAuxLightSourceCount=" +
        lightSource1LogicalChannelsByAuxLightSourceCount +
        ", lightSource1LogicalChannelsByAuxLightSourceList.size()=" +
        lightSource1LogicalChannelsByAuxLightSourceList.size() + ")");
    }
    int lightSource1LasersByLightSourceCount =
      lightSource1.countLaserListByLightSource();
    List lightSource1LasersByLightSourceList =
      lightSource1.getLaserListByLightSource();
    if (lightSource1LasersByLightSourceCount != 1 ||
      lightSource1LasersByLightSourceList.size() != 1)
    {
      System.out.println("Error: Incorrect number of first CA LightSource " +
        "Lasers by LightSource " +
        "(lightSource1LasersByLightSourceCount=" +
        lightSource1LasersByLightSourceCount +
        ", lightSource1LasersByLightSourceList.size()=" +
        lightSource1LasersByLightSourceList.size() + ")");
    }
    int lightSource1LasersByPumpCount = lightSource1.countLaserListByPump();
    List lightSource1LasersByPumpList = lightSource1.getLaserListByPump();
    if (lightSource1LasersByPumpCount != 0 ||
      lightSource1LasersByPumpList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first CA LightSource " +
        "Lasers by Pump (lightSource1LasersByPumpCount=" +
        lightSource1LasersByPumpCount +
        ", lightSource1LasersByPumpList.size()=" +
        lightSource1LasersByPumpList.size() + ")");
    }
    int lightSource1FilamentCount = lightSource1.countFilamentList();
    List lightSource1FilamentList = lightSource1.getFilamentList();
    if (lightSource1FilamentCount != 0 ||
      lightSource1FilamentList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first CA LightSource " +
        "Filaments (lightSource1FilamentCount=" + lightSource1FilamentCount +
        ", lightSource1FilamentList.size()=" +
        lightSource1FilamentList.size() + ")");
    }
    int lightSource1ArcCount = lightSource1.countArcList();
    List lightSource1ArcList = lightSource1.getArcList();
    if (lightSource1ArcCount != 0 || lightSource1ArcList.size() != 0) {
      System.out.println("Error: Incorrect number of first CA LightSource " +
        "Arcs (lightSource1ArcCount=" + lightSource1ArcCount +
        ", lightSource1ArcList.size()=" + lightSource1ArcList.size() + ")");
    }

    // check OME/CA/Laser node
    LaserNode laser = (LaserNode) omeCAList.get(7);
    String laserType = laser.getType();
    if (!laserType.equals("Semiconductor")) {
      System.out.println("Error: Incorrect CA Laser Type (" +
        laserType + ")");
    }
    String laserMedium = laser.getMedium();
    if (!laserMedium.equals("GaAs")) {
      System.out.println("Error: Incorrect CA Laser Medium (" +
        laserMedium + ")");
    }
    Integer laserWavelength = laser.getWavelength();
    if (laserWavelength != null) {
      System.out.println("Error: CA Laser Wavelength is not null " +
        "as expected (" + laserWavelength + ")");
    }
    Boolean laserFrequencyDoubled = laser.isFrequencyDoubled();
    if (laserFrequencyDoubled != null) {
      System.out.println("Error: CA Laser FrequencyDoubled " +
        "is not null as expected (" + laserFrequencyDoubled + ")");
    }
    Boolean laserTunable = laser.isTunable();
    if (laserTunable != null) {
      System.out.println("Error: CA Laser Tunable " +
        "is not null as expected (" + laserTunable + ")");
    }
    String laserPulse = laser.getPulse();
    if (laserPulse != null) {
      System.out.println("Error: CA Laser Pulse " +
        "is not null as expected (" + laserPulse + ")");
    }
    Float laserPower = laser.getPower();
    if (laserPower != null) {
      System.out.println("Error: CA Laser Power is not null " +
        "as expected (" + laserPower + ")");
    }

    // check second OME/CA/LightSource node
    LightSourceNode lightSource2 = (LightSourceNode) omeCAList.get(8);
    String lightSource2ID = lightSource2.getNodeID();
    if (!lightSource2ID.equals("urn:lsid:foo.bar.com:LightSource:123123")) {
      System.out.println("Error: Incorrect second CA LightSource ID (" +
        lightSource2ID + ")");
    }
    String lightSource2Manufacturer = lightSource2.getManufacturer();
    if (!lightSource2Manufacturer.equals("Olympus")) {
      System.out.println("Error: Incorrect second CA LightSource " +
        "Manufacturer (" + lightSource2Manufacturer + ")");
    }
    String lightSource2Model = lightSource2.getModel();
    if (!lightSource2Model.equals("Realy Bright Lite")) {
      System.out.println("Error: Incorrect second CA LightSource " +
        "Model (" + lightSource2Model + ")");
    }
    String lightSource2SerialNumber = lightSource2.getSerialNumber();
    if (!lightSource2SerialNumber.equals("123skdjhf1456")) {
      System.out.println("Error: Incorrect second CA LightSource " +
        "SerialNumber (" + lightSource2SerialNumber + ")");
    }
    int lightSource2LogicalChannelsByLightSourceCount =
      lightSource2.countLogicalChannelListByLightSource();
    List lightSource2LogicalChannelsByLightSourceList =
      lightSource2.getLogicalChannelListByLightSource();
    if (lightSource2LogicalChannelsByLightSourceCount != 1 ||
      lightSource2LogicalChannelsByLightSourceList.size() != 1)
    {
      System.out.println("Error: Incorrect number of second CA " +
        "LightSource LogicalChannels by LightSource " +
        "(lightSource2LogicalChannelsByLightSourceCount=" +
        lightSource2LogicalChannelsByLightSourceCount +
        ", lightSource2LogicalChannelsByLightSourceList.size()=" +
        lightSource2LogicalChannelsByLightSourceList.size() + ")");
    }
    int lightSource2LogicalChannelsByAuxLightSourceCount =
      lightSource2.countLogicalChannelListByAuxLightSource();
    List lightSource2LogicalChannelsByAuxLightSourceList =
      lightSource2.getLogicalChannelListByAuxLightSource();
    if (lightSource2LogicalChannelsByAuxLightSourceCount != 0 ||
      lightSource2LogicalChannelsByAuxLightSourceList.size() != 0)
    {
      System.out.println("Error: Incorrect number of second CA " +
        "LightSource LogicalChannels by AuxLightSource " +
        "(lightSource2LogicalChannelsByAuxLightSourceCount=" +
        lightSource2LogicalChannelsByAuxLightSourceCount +
        ", lightSource2LogicalChannelsByAuxLightSourceList.size()=" +
        lightSource2LogicalChannelsByAuxLightSourceList.size() + ")");
    }
    int lightSource2LasersByLightSourceCount =
      lightSource2.countLaserListByLightSource();
    List lightSource2LasersByLightSourceList =
      lightSource2.getLaserListByLightSource();
    if (lightSource2LasersByLightSourceCount != 0 ||
      lightSource2LasersByLightSourceList.size() != 0)
    {
      System.out.println("Error: Incorrect number of second CA " +
        "LightSource Lasers by LightSource " +
        "(lightSource2LasersByLightSourceCount=" +
        lightSource2LasersByLightSourceCount +
        ", lightSource2LasersByLightSourceList.size()=" +
        lightSource2LasersByLightSourceList.size() + ")");
    }
    int lightSource2LasersByPumpCount = lightSource2.countLaserListByPump();
    List lightSource2LasersByPumpList = lightSource2.getLaserListByPump();
    if (lightSource2LasersByPumpCount != 0 ||
      lightSource2LasersByPumpList.size() != 0)
    {
      System.out.println("Error: Incorrect number of second CA " +
        "LightSource Lasers by Pump (lightSource2LasersByPumpCount=" +
        lightSource2LasersByPumpCount +
        ", lightSource2LasersByPumpList.size()=" +
        lightSource2LasersByPumpList.size() + ")");
    }
    int lightSource2FilamentCount = lightSource2.countFilamentList();
    List lightSource2FilamentList = lightSource2.getFilamentList();
    if (lightSource2FilamentCount != 0 ||
      lightSource2FilamentList.size() != 0)
    {
      System.out.println("Error: Incorrect number of second CA " +
        "LightSource Filaments (lightSource2FilamentCount=" +
        lightSource2FilamentCount + ", lightSource2FilamentList.size()=" +
        lightSource2FilamentList.size() + ")");
    }
    int lightSource2ArcCount = lightSource2.countArcList();
    List lightSource2ArcList = lightSource2.getArcList();
    if (lightSource2ArcCount != 1 || lightSource2ArcList.size() != 1) {
      System.out.println("Error: Incorrect number of second CA " +
        "LightSource Arcs (lightSource2ArcCount=" + lightSource2ArcCount +
        ", lightSource2ArcList.size()=" + lightSource2ArcList.size() + ")");
    }

    // check OME/CA/Arc node
    ArcNode arc = (ArcNode) omeCAList.get(9);
    String arcType = arc.getType();
    if (!arcType.equals("Hg")) {
      System.out.println("Error: Incorrect CA Arc Type (" + arcType + ")");
    }
    Float arcPower = arc.getPower();
    if (arcPower != null) {
      System.out.println("Error: CA Arc Type is not null as expected (" +
        arcPower + ")");
    }

    // check OME/CA/Detector node
    DetectorNode detector = (DetectorNode) omeCAList.get(10);
    String detectorID = detector.getNodeID();
    if (!detectorID.equals("urn:lsid:foo.bar.com:Detector:123456")) {
      System.out.println("Error: Incorrect CA Detector ID (" +
        detectorID + ")");
    }
    String detectorManufacturer = detector.getManufacturer();
    if (!detectorManufacturer.equals("Kodak")) {
      System.out.println("Error: Incorrect CA Detector Manufacturer (" +
        detectorManufacturer + ")");
    }
    String detectorModel = detector.getModel();
    if (!detectorModel.equals("Instamatic")) {
      System.out.println("Error: Incorrect CA Detector Model (" +
        detectorModel + ")");
    }
    String detectorSerialNumber = detector.getSerialNumber();
    if (!detectorSerialNumber.equals("fnuiprf89uh123498")) {
      System.out.println("Error: Incorrect CA Detector SerialNumber (" +
        detectorSerialNumber + ")");
    }
    String detectorType = detector.getType();
    if (!detectorType.equals("CCD")) {
      System.out.println("Error: Incorrect CA Detector Type (" +
        detectorType + ")");
    }
    Float detectorGain = detector.getGain();
    if (detectorGain != null) {
      System.out.println("Error: CA Detector Gain is not null " +
        "as expected (" + detectorGain + ")");
    }
    Float detectorVoltage = detector.getVoltage();
    if (detectorVoltage != null) {
      System.out.println("Error: CA Detector Voltage is not null " +
        "as expected (" + detectorVoltage + ")");
    }
    Float detectorOffset = detector.getOffset();
    if (detectorOffset != null) {
      System.out.println("Error: CA Detector Offset is not null " +
        "as expected (" + detectorOffset + ")");
    }
    int detectorLogicalChannelCount = detector.countLogicalChannelList();
    List detectorLogicalChannelList = detector.getLogicalChannelList();
    if (detectorLogicalChannelCount != 1 ||
      detectorLogicalChannelList.size() != 1)
    {
      System.out.println("Error: Incorrect number of CA Detector " +
        "LogicalChannels (detectorLogicalChannelCount=" +
        detectorLogicalChannelCount +
        ", detectorLogicalChannelList.size()=" +
        detectorLogicalChannelList.size() + ")");
    }

    // check OME/CA/Objective node
    ObjectiveNode objective = (ObjectiveNode) omeCAList.get(11);
    String objectiveID = objective.getNodeID();
    if (!objectiveID.equals("urn:lsid:foo.bar.com:Objective:123456")) {
      System.out.println("Error: Incorrect CA Objective ID (" +
        objectiveID + ")");
    }
    String objectiveManufacturer = objective.getManufacturer();
    if (!objectiveManufacturer.equals("Olympus")) {
      System.out.println("Error: Incorrect CA Objective Manufacturer (" +
        objectiveManufacturer + ")");
    }
    String objectiveModel = objective.getModel();
    if (!objectiveModel.equals("SPlanL")) {
      System.out.println("Error: Incorrect CA Objective Model (" +
        objectiveModel + ")");
    }
    String objectiveSerialNumber = objective.getSerialNumber();
    if (!objectiveSerialNumber.equals("456anxcoas123")) {
      System.out.println("Error: Incorrect CA Objective SerialNumber (" +
        objectiveSerialNumber + ")");
    }
    Float objectiveLensNA = objective.getLensNA();
    if (objectiveLensNA.floatValue() != 2.4f) {
      System.out.println("Error: Incorrect CA Objective LensNA (" +
        objectiveLensNA + ")");
    }
    Float objectiveMagnification = objective.getMagnification();
    if (objectiveMagnification.floatValue() != 40.0f) {
      System.out.println("Error: Incorrect CA Objective Magnification (" +
        objectiveMagnification + ")");
    }
    int objectiveImageInstrumentCount = objective.countImageInstrumentList();
    List objectiveImageInstrumentList = objective.getImageInstrumentList();
    if (objectiveImageInstrumentCount != 1 ||
      objectiveImageInstrumentList.size() != 1)
    {
      System.out.println("Error: Incorrect number of CA Objective " +
        "ImageInstruments (objectiveImageInstrumentCount=" +
        objectiveImageInstrumentCount +
        ", objectiveImageInstrumentList.size()=" +
        objectiveImageInstrumentList.size() + ")");
    }
    int objectiveOTFCount = objective.countOTFList();
    List objectiveOTFList = objective.getOTFList();
    if (objectiveOTFCount != 1 ||
      objectiveOTFList.size() != 1)
    {
      System.out.println("Error: Incorrect number of CA Objective " +
        "OTFs (objectiveOTFCount=" + objectiveOTFCount +
        ", objectiveOTFList.size()=" + objectiveOTFList.size() + ")");
    }

    // check OME/CA/Filter node
    FilterNode filter = (FilterNode) omeCAList.get(12);
    String filterID = filter.getNodeID();
    if (!filterID.equals("urn:lsid:foo.bar.com:Filter:123456")) {
      System.out.println("Error: Incorrect CA Filter ID (" + filterID + ")");
    }
    int filterLogicalChannelCount = filter.countLogicalChannelList();
    List filterLogicalChannelList = filter.getLogicalChannelList();
    if (filterLogicalChannelCount != 1 ||
      filterLogicalChannelList.size() != 1)
    {
      System.out.println("Error: Incorrect number of CA Filter " +
        "LogicalChannels (filterLogicalChannelCount=" +
        filterLogicalChannelCount + ", filterLogicalChannelList.size()=" +
        filterLogicalChannelList.size() + ")");
    }
    int filterExcitationFilterCount = filter.countExcitationFilterList();
    List filterExcitationFilterList = filter.getExcitationFilterList();
    if (filterExcitationFilterCount != 0 ||
      filterExcitationFilterList.size() != 0)
    {
      System.out.println("Error: Incorrect number of CA Filter " +
        "ExcitationFilters (filterExcitationFilterCount=" +
        filterExcitationFilterCount +
        ", filterExcitationFilterList.size()=" +
        filterExcitationFilterList.size() + ")");
    }
    int filterDichroicCount = filter.countDichroicList();
    List filterDichroicList = filter.getDichroicList();
    if (filterDichroicCount != 0 || filterDichroicList.size() != 0) {
      System.out.println("Error: Incorrect number of CA Filter " +
        "Dichroics (filterDichroicCount=" + filterDichroicCount +
        ", filterDichroicList.size()=" + filterDichroicList.size() + ")");
    }
    int filterEmissionFilterCount = filter.countEmissionFilterList();
    List filterEmissionFilterList = filter.getEmissionFilterList();
    if (filterEmissionFilterCount != 0 ||
      filterEmissionFilterList.size() != 0)
    {
      System.out.println("Error: Incorrect number of CA Filter " +
        "EmissionFilters (filterEmissionFilterCount=" +
        filterEmissionFilterCount + ", filterEmissionFilterList.size()=" +
        filterEmissionFilterList.size() + ")");
    }
    int filterFilterSetCount = filter.countFilterSetList();
    List filterFilterSetList = filter.getFilterSetList();
    if (filterFilterSetCount != 1 || filterFilterSetList.size() != 1) {
      System.out.println("Error: Incorrect number of CA Filter " +
        "FilterSets (filterFilterSetCount=" + filterFilterSetCount +
        ", filterFilterSetList.size()=" + filterFilterSetList.size() + ")");
    }
    int filterOTFCount = filter.countOTFList();
    List filterOTFList = filter.getOTFList();
    if (filterOTFCount != 1 || filterOTFList.size() != 1) {
      System.out.println("Error: Incorrect number of CA Filter " +
        "OTFs (filterOTFCount=" + filterOTFCount +
        ", filterOTFList.size()=" + filterOTFList.size() + ")");
    }

    // check OME/CA/FilterSet node
    FilterSetNode filterSet = (FilterSetNode) omeCAList.get(13);
    String filterSetManufacturer = filterSet.getManufacturer();
    if (!filterSetManufacturer.equals("Omega")) {
      System.out.println("Error: Incorrect CA FilterSet Manufacturer (" +
        filterSetManufacturer + ")");
    }
    String filterSetModel = filterSet.getModel();
    if (!filterSetModel.equals("SuperGFP")) {
      System.out.println("Error: Incorrect CA FilterSet Model (" +
        filterSetModel + ")");
    }
    String filterSetLotNumber = filterSet.getLotNumber();
    if (!filterSetLotNumber.equals("123LJKHG123")) {
      System.out.println("Error: Incorrect CA FilterSet LotNumber (" +
        filterSetLotNumber + ")");
    }

    // check OME/CA/OTF node
    OTFNode otf = (OTFNode) omeCAList.get(14);
    String otfID = otf.getNodeID();
    if (!otfID.equals("urn:lsid:foo.bar.com:OTF:123456")) {
      System.out.println("Error: Incorrect CA OTF ID (" + otfID + ")");
    }
    Integer otfSizeX = otf.getSizeX();
    if (otfSizeX.intValue() != 512) {
      System.out.println("Error: Incorrect CA OTF SizeX (" + otfSizeX + ")");
    }
    Integer otfSizeY = otf.getSizeY();
    if (otfSizeY.intValue() != 512) {
      System.out.println("Error: Incorrect CA OTF SizeY (" + otfSizeY + ")");
    }
    String otfPixelType = otf.getPixelType();
    if (!otfPixelType.equals("int8")) {
      System.out.println("Error: Incorrect CA OTF PixelType (" +
        otfPixelType + ")");
    }
    String otfPath = otf.getPath();
    if (otfPath != null) {
      System.out.println("Error: CA OTF Path " +
        "is not null as expected (" + otfPath + ")");
    }
    Boolean otfOpticalAxisAverage = otf.isOpticalAxisAverage();
    if (otfOpticalAxisAverage.booleanValue() != true) {
      System.out.println("Error: Incorrect CA OpticalAxisAverage (" +
        otfOpticalAxisAverage + ")");
    }
    int otfLogicalChannelCount = otf.countLogicalChannelList();
    List otfLogicalChannelList = otf.getLogicalChannelList();
    if (otfLogicalChannelCount != 1 || otfLogicalChannelList.size() != 1) {
      System.out.println("Error: Incorrect number of CA OTF " +
        "LogicalChannels (otfLogicalChannelCount=" + otfLogicalChannelCount +
        ", otfLogicalChannelList.size()=" +
        otfLogicalChannelList.size() + ")");
    }

    // check OME/CA/Plate node
    PlateNode plate = (PlateNode) omeCAList.get(15);
    String plateID = plate.getNodeID();
    if (!plateID.equals("urn:lsid:foo.bar.com:Plate:123456")) {
      System.out.println("Error: Incorrect CA Plate ID (" + plateID + ")");
    }
    String plateName = plate.getName();
    if (!plateName.equals("SRP001")) {
      System.out.println("Error: Incorrect CA Plate Name (" +
        plateName + ")");
    }
    String plateExternalReference = plate.getExternalReference();
    if (!plateExternalReference.equals("PID.SRP001")) {
      System.out.println("Error: Incorrect CA Plate ExternalReference (" +
        plateExternalReference + ")");
    }
    int plateImagePlateCount = plate.countImagePlateList();
    List plateImagePlateList = plate.getImagePlateList();
    if (plateImagePlateCount != 1 || plateImagePlateList.size() != 1) {
      System.out.println("Error: Incorrect number of CA Plate " +
        "ImagePlates (plateImagePlateCount=" + plateImagePlateCount +
        ", plateImagePlateList.size()=" +
        plateImagePlateList.size() + ")");
    }
    int platePlateScreenCount = plate.countPlateScreenList();
    List platePlateScreenList = plate.getPlateScreenList();
    if (platePlateScreenCount != 2 || platePlateScreenList.size() != 2) {
      System.out.println("Error: Incorrect number of CA Plate " +
        "PlateScreens (platePlateScreenCount=" + platePlateScreenCount +
        ", platePlateScreenList.size()=" +
        platePlateScreenList.size() + ")");
    }

    // check first OME/CA/PlateScreen node
    PlateScreenNode plateScreen1 = (PlateScreenNode) omeCAList.get(16);

    // check second OME/CA/PlateScreen node
    PlateScreenNode plateScreen2 = (PlateScreenNode) omeCAList.get(17);

    // check OME/CA/Screen node
    ScreenNode screen = (ScreenNode) omeCAList.get(18);
    String screenID = screen.getNodeID();
    if (!screenID.equals("urn:lsid:foo.bar.com:Screen:123456")) {
      System.out.println("Error: Incorrect CA Screen ID (" + screenID + ")");
    }
    String screenName = screen.getName();
    if (!screenName.equals("Stress Response Pathway Controls")) {
      System.out.println("Error: Incorrect CA Screen Name (" +
        screenName + ")");
    }
    String screenDescription = screen.getDescription();
    if (screenDescription != null) {
      System.out.println("Error: CA Screen Description " +
        "is not null as expected (" + screenDescription + ")");
    }
    String screenExternalReference = screen.getExternalReference();
    if (!screenExternalReference.equals("SID.SRPC001")) {
      System.out.println("Error: Incorrect CA Screen ExternalReference (" +
        screenExternalReference + ")");
    }
    int screenPlateCount = screen.countPlateList();
    List screenPlateList = screen.getPlateList();
    if (screenPlateCount != 0 || screenPlateList.size() != 0) {
      System.out.println("Error: Incorrect number of CA Screen " +
        "Plates (screenPlateCount=" + screenPlateCount +
        ", screenPlateList.size()=" + screenPlateList.size() + ")");
    }
    int screenPlateScreenCount = screen.countPlateScreenList();
    List screenPlateScreenList = screen.getPlateScreenList();
    if (screenPlateScreenCount != 1 || screenPlateScreenList.size() != 1) {
      System.out.println("Error: Incorrect number of CA Screen " +
        "PlateScreens (screenPlateScreenCount=" + screenPlateScreenCount +
        ", screenPlateScreenList.size()=" +
        screenPlateScreenList.size() + ")");
    }

    // -- Depth 4 --

    // check OME/Project/Group/Leader node
    ExperimenterNode projectGroupLeader =
      (ExperimenterNode) projectGroup.getLeader();
    if (!projectGroupLeader.equals(projectOwner)) {
      System.out.println(
        "Error: Project Group Leader does not match Project Owner");
    }

    // check OME/Project/Group/Contact node
    ExperimenterNode projectGroupContact =
      (ExperimenterNode) projectGroup.getContact();
    if (!projectGroupLeader.equals(projectOwner)) {
      System.out.println(
        "Error: Project Group Contact does not match Project Owner");
    }

    // check OME/Project/Owner/Group node
    GroupNode projectOwnerGroup = (GroupNode) projectOwner.getGroup();
    if (!projectOwnerGroup.equals(projectGroup)) {
      System.out.println(
        "Error: Project Owner Group does not match Project Group");
    }

    // check OME/Project/Owner/Experiment node
    ExperimentNode projectOwnerExperiment =
      (ExperimentNode) projectOwnerExperimentList.get(0);
    if (!projectOwnerExperiment.equals(experiment)) {
      System.out.println("Error: Project Owner Experiment " +
        "does not match CA Experiment");
    }

    // check OME/Project/Owner/Group by Leader node
    GroupNode projectOwnerGroupByLeader =
      (GroupNode) projectOwnerGroupsByLeaderList.get(0);
    if (!projectOwnerGroupByLeader.equals(projectGroup)) {
      System.out.println(
        "Error: Project Owner Group by Leader does not match Project Group");
    }

    // check OME/Project/Owner/Group by Contact node
    GroupNode projectOwnerGroupByContact =
      (GroupNode) projectOwnerGroupsByContactList.get(0);
    if (!projectOwnerGroupByContact.equals(projectGroup)) {
      System.out.println("Error: Project Owner Group by Contact " +
        "does not match Project Group");
    }

    // check OME/Project/Owner/ExperimenterGroup[0] node
    ExperimenterGroupNode projectOwnerExperimenterGroup0 =
      (ExperimenterGroupNode) projectOwnerExperimenterGroupList.get(0);

    // check OME/Project/Owner/ExperimenterGroup[1] node
    ExperimenterGroupNode projectOwnerExperimenterGroup1 =
      (ExperimenterGroupNode) projectOwnerExperimenterGroupList.get(1);

    // check OME/Image/DefaultPixels/PixelChannelComponent node
    PixelChannelComponentNode imagePixelsPixelChannelComponent =
      (PixelChannelComponentNode)
      imagePixelsPixelChannelComponentList.get(0);
    Integer imagePixelsPixelChannelComponentIndex =
      imagePixelsPixelChannelComponent.getIndex();
    if (imagePixelsPixelChannelComponentIndex.intValue() != 0) {
      System.out.println("Error: Incorrect Image DefaultPixels " +
        "PixelChannelComponent Index (" +
        imagePixelsPixelChannelComponentIndex + ")");
    }
    String imagePixelsPixelChannelComponentColorDomain =
      imagePixelsPixelChannelComponent.getColorDomain();
    if (!imagePixelsPixelChannelComponentColorDomain.equals("foo")) {
      System.out.println("Error: Incorrect Image DefaultPixels " +
        "PixelChannelComponent ColorDomain (" +
        imagePixelsPixelChannelComponentColorDomain + ")");
    }

    // check OME/Image/DefaultPixels/DisplayOptions node
    //DisplayOptionsNode imagePixelsDisplayOptions =
    //  (DisplayOptionsNode) imagePixelsDisplayOptionsList.get(0);

    // check OME/Image/DefaultPixels/Repository node
    //RepositoryNode imagePixelsRepository =
    //  (RepositoryNode) imagePixels.getRepository();

    // check OME/Image/CA/Dimensions node
    DimensionsNode imageDimensions = (DimensionsNode) imageCAList.get(0);
    Float imageDimensionsPixelSizeX = imageDimensions.getPixelSizeX();
    if (imageDimensionsPixelSizeX.floatValue() != 0.2f) {
      System.out.println("Error: Incorrect Image CA Dimensions " +
        "PixelSizeX (" + imageDimensionsPixelSizeX + ")");
    }
    Float imageDimensionsPixelSizeY = imageDimensions.getPixelSizeY();
    if (imageDimensionsPixelSizeY.floatValue() != 0.2f) {
      System.out.println("Error: Incorrect Image CA Dimensions " +
        "PixelSizeY (" + imageDimensionsPixelSizeY + ")");
    }
    Float imageDimensionsPixelSizeZ = imageDimensions.getPixelSizeZ();
    if (imageDimensionsPixelSizeZ.floatValue() != 0.2f) {
      System.out.println("Error: Incorrect Image CA Dimensions " +
        "PixelSizeZ (" + imageDimensionsPixelSizeZ + ")");
    }
    Float imageDimensionsPixelSizeC = imageDimensions.getPixelSizeC();
    if (imageDimensionsPixelSizeC != null) {
      System.out.println("Error: Image CA Dimensions PixelSizeC " +
        "is not null as expected (" + imageDimensionsPixelSizeC + ")");
    }
    Float imageDimensionsPixelSizeT = imageDimensions.getPixelSizeT();
    if (imageDimensionsPixelSizeT != null) {
      System.out.println("Error: Image CA Dimensions PixelSizeT " +
        "is not null as expected (" + imageDimensionsPixelSizeT + ")");
    }

    // check OME/Image/CA/ImageExperiment node
    ImageExperimentNode imageImageExperiment =
      (ImageExperimentNode) imageCAList.get(1);

    // check OME/Image/CA/ImageInstrument node
    ImageInstrumentNode imageImageInstrument =
      (ImageInstrumentNode) imageCAList.get(2);

    // check OME/Image/CA/ImagingEnvironment node
    ImagingEnvironmentNode imageImagingEnvironment =
      (ImagingEnvironmentNode) imageCAList.get(3);
    Float imageImagingEnvironmentTemperature =
      imageImagingEnvironment.getTemperature();
    if (imageImagingEnvironmentTemperature.floatValue() != 0.1f) {
      System.out.println("Error: Incorrect Image CA ImagingEnvironment " +
        "Temperature (" + imageImagingEnvironmentTemperature);
    }
    Float imageImagingEnvironmentAirPressure =
      imageImagingEnvironment.getAirPressure();
    if (imageImagingEnvironmentAirPressure.floatValue() != 0.1f) {
      System.out.println("Error: Incorrect Image CA ImagingEnvironment " +
        "AirPressure (" + imageImagingEnvironmentAirPressure);
    }
    Float imageImagingEnvironmentHumidity =
      imageImagingEnvironment.getHumidity();
    if (imageImagingEnvironmentHumidity.floatValue() != 0.2f) {
      System.out.println("Error: Incorrect Image CA ImagingEnvironment " +
        "Humidity (" + imageImagingEnvironmentHumidity);
    }
    Float imageImagingEnvironmentCO2Percent =
      imageImagingEnvironment.getCO2Percent();
    if (imageImagingEnvironmentCO2Percent.floatValue() != 0.3f) {
      System.out.println("Error: Incorrect Image CA ImagingEnvironment " +
        "CO2Percent (" + imageImagingEnvironmentCO2Percent);
    }

    // check OME/Image/CA/Thumbnail node
    ThumbnailNode imageThumbnail = (ThumbnailNode) imageCAList.get(4);
    String imageThumbnailMimeType = imageThumbnail.getMimeType();
    if (!imageThumbnailMimeType.equals("image/jpeg")) {
      System.out.println("Error: Incorrect Image CA Thumbnail " +
        "MimeType (" + imageThumbnailMimeType + ")");
    }
    String imageThumbnailPath = imageThumbnail.getPath();
    if (!imageThumbnailPath.equals("http://ome.nia.gov/GetThumbnail?" +
      "ID=urn:lsid:foo.bar.com:Image:123456"))
    {
      System.out.println("Error: Incorrect Image CA Thumbnail " +
        "Path (" + imageThumbnailPath + ")");
    }

    // check OME/Image/CA/LogicalChannel node
    LogicalChannelNode imageLogicalChannel =
      (LogicalChannelNode) imageCAList.get(5);
    String imageLogicalChannelID = imageLogicalChannel.getNodeID();
    if (!imageLogicalChannelID.equals(
      "urn:lsid:foo.bar.com:LogicalChannel:123456"))
    {
      System.out.println("Error: Incorrect Image CA LogicalChannel ID (" +
        imageLogicalChannelID + ")");
    }
    String imageLogicalChannelName = imageLogicalChannel.getName();
    if (!imageLogicalChannelName.equals("Ch 1")) {
      System.out.println("Error: Incorrect Image CA LogicalChannel Name (" +
        imageLogicalChannelName + ")");
    }
    Integer imageLogicalChannelSamplesPerPixel =
      imageLogicalChannel.getSamplesPerPixel();
    if (imageLogicalChannelSamplesPerPixel != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "SamplesPerPixel is not null as expected (" +
        imageLogicalChannelSamplesPerPixel + ")");
    }
    Float imageLogicalChannelLightAttenuation =
      imageLogicalChannel.getLightAttenuation();
    if (imageLogicalChannelLightAttenuation != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "LightAttenuation is not null as expected (" +
        imageLogicalChannelLightAttenuation + ")");
    }
    Integer imageLogicalChannelLightWavelength =
      imageLogicalChannel.getLightWavelength();
    if (imageLogicalChannelLightWavelength != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "LightWavelength is not null as expected (" +
        imageLogicalChannelLightWavelength + ")");
    }
    Float imageLogicalChannelOffset =
      imageLogicalChannel.getDetectorOffset();
    if (imageLogicalChannelOffset != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "Offset is not null as expected (" +
        imageLogicalChannelOffset + ")");
    }
    Float imageLogicalChannelDetectorGain =
      imageLogicalChannel.getDetectorGain();
    if (imageLogicalChannelDetectorGain != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "DetectorGain is not null as expected (" +
        imageLogicalChannelDetectorGain + ")");
    }
    String imageLogicalChannelIlluminationType =
      imageLogicalChannel.getIlluminationType();
    if (!imageLogicalChannelIlluminationType.equals("Epifluorescence")) {
      System.out.println("Error: Incorrect Image CA LogicalChannel " +
        "IlluminationType (" + imageLogicalChannelIlluminationType + ")");
    }
    Integer imageLogicalChannelPinholeSize =
      imageLogicalChannel.getPinholeSize();
    if (imageLogicalChannelPinholeSize != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "PinholeSize is not null as expected (" +
        imageLogicalChannelPinholeSize + ")");
    }
    String imageLogicalChannelPhotometricInterpretation =
      imageLogicalChannel.getPhotometricInterpretation();
    if (imageLogicalChannelPhotometricInterpretation != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "PhotometricInterpretation is not null as expected (" +
        imageLogicalChannel + ")");
    }
    String imageLogicalChannelMode = imageLogicalChannel.getMode();
    if (imageLogicalChannelMode != null) {
      System.out.println("Error: Image CA LogicalChannel Mode " +
        "is not null as expected (" + imageLogicalChannelMode + ")");
    }
    String imageLogicalChannelContrastMethod =
      imageLogicalChannel.getContrastMethod();
    if (imageLogicalChannelContrastMethod != null) {
      System.out.println("Error: Image CA LogicalChannel ContrastMethod " +
        "is not null as expected (" +
        imageLogicalChannelContrastMethod + ")");
    }
    Float imageLogicalChannelAuxLightAttenuation =
      imageLogicalChannel.getAuxLightAttenuation();
    if (imageLogicalChannelAuxLightAttenuation != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "AuxLightAttenuation is not null as expected (" +
        imageLogicalChannelAuxLightAttenuation + ")");
    }
    String imageLogicalChannelAuxTechnique =
      imageLogicalChannel.getAuxTechnique();
    if (!imageLogicalChannelAuxTechnique.equals("Photobleaching")) {
      System.out.println("Error: Incorrect Image CA LogicalChannel " +
        "AuxTechnique (" + imageLogicalChannelAuxTechnique + ")");
    }
    Integer imageLogicalChannelAuxLightWavelength =
      imageLogicalChannel.getAuxLightWavelength();
    if (imageLogicalChannelAuxLightWavelength != null) {
      System.out.println("Error: Image CA LogicalChannel " +
        "AuxLightWavelength is not null as expected (" +
        imageLogicalChannelAuxLightWavelength + ")");
    }
    Integer imageLogicalChannelExcitationWavelength =
      imageLogicalChannel.getExcitationWavelength();
    if (imageLogicalChannelExcitationWavelength.intValue() != 490) {
      System.out.println("Error: Incorrect Image CA LogicalChannel " +
        "ExcitationWavelength (" +
        imageLogicalChannelExcitationWavelength + ")");
    }
    Integer imageLogicalChannelEmissionWavelength =
      imageLogicalChannel.getEmissionWavelength();
    if (imageLogicalChannelEmissionWavelength.intValue() != 528) {
      System.out.println("Error: Incorrect Image CA LogicalChannel " +
        "EmissionWavelength (" +
        imageLogicalChannelEmissionWavelength + ")");
    }
    String imageLogicalChannelFluor = imageLogicalChannel.getFluor();
    if (!imageLogicalChannelFluor.equals("GFP")) {
      System.out.println("Error: Incorrect Image CA LogicalChannel Fluor (" +
        imageLogicalChannelFluor + ")");
    }
    Float imageLogicalChannelNDFilter = imageLogicalChannel.getNDFilter();
    if (imageLogicalChannelNDFilter.floatValue() != 0.0f) {
      System.out.println("Error: Incorrect Image CA LogicalChannel " +
        "NDFilter (" + imageLogicalChannelNDFilter + ")");
    }
    int imageLogicalChannelPixelChannelComponentCount =
      imageLogicalChannel.countPixelChannelComponentList();
    List imageLogicalChannelPixelChannelComponentList =
      imageLogicalChannel.getPixelChannelComponentList();
    if (imageLogicalChannelPixelChannelComponentCount != 1 ||
      imageLogicalChannelPixelChannelComponentList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Image CA " +
        "LogicalChannel PixelChannelComponents " +
        "(imageLogicalChannelPixelChannelComponentCount=" +
        imageLogicalChannelPixelChannelComponentCount +
        ", imageLogicalChannelPixelChannelComponentList.size()=" +
        imageLogicalChannelPixelChannelComponentList.size() + ")");
    }

    // check OME/Image/CA/PixelChannelComponent node
    PixelChannelComponentNode imagePixelChannelComponent =
      (PixelChannelComponentNode) imageCAList.get(6);
    if (!imagePixelChannelComponent.equals(
      imagePixelsPixelChannelComponent))
    {
      System.out.println("Error: Image CA PixelChannelComponent " +
        "does not match Image DefaultPixels PixelChannelComponent");
    }

    // check OME/Image/CA/DisplayOptions node
    DisplayOptionsNode imageDisplayOptions =
      (DisplayOptionsNode) imageCAList.get(7);
    String imageDisplayOptionsID = imageDisplayOptions.getNodeID();
    if (!imageDisplayOptionsID.equals(
      "urn:lsid:foo.bar.com:DisplayOptions:123456"))
    {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "ID (" + imageDisplayOptionsID + ")");
    }
    Float imageDisplayOptionsZoom = imageDisplayOptions.getZoom();
    if (imageDisplayOptionsZoom.floatValue() != 1.0f) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "Zoom (" + imageDisplayOptionsZoom + ")");
    }
    Boolean imageDisplayOptionsRedChannelOn =
      imageDisplayOptions.isRedChannelOn();
    if (imageDisplayOptionsRedChannelOn.booleanValue() != true) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "RedChannelOn (" + imageDisplayOptionsRedChannelOn + ")");
    }
    Boolean imageDisplayOptionsGreenChannelOn =
      imageDisplayOptions.isGreenChannelOn();
    if (imageDisplayOptionsGreenChannelOn.booleanValue() != true) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "GreenChannelOn (" + imageDisplayOptionsGreenChannelOn + ")");
    }
    Boolean imageDisplayOptionsBlueChannelOn =
      imageDisplayOptions.isBlueChannelOn();
    if (imageDisplayOptionsBlueChannelOn.booleanValue() != true) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "BlueChannelOn (" + imageDisplayOptionsBlueChannelOn + ")");
    }
    Boolean imageDisplayOptionsDisplayRGB =
      imageDisplayOptions.isDisplayRGB();
    if (imageDisplayOptionsDisplayRGB.booleanValue() != true) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "DisplayRGB (" + imageDisplayOptionsDisplayRGB + ")");
    }
    String imageDisplayOptionsColorMap = imageDisplayOptions.getColorMap();
    if (imageDisplayOptionsColorMap != null) {
      System.out.println("Error: Image CA DisplayOptions ColorMap " +
        "is not null as expected (" + imageDisplayOptionsColorMap + ")");
    }
    Integer imageDisplayOptionsZStart = imageDisplayOptions.getZStart();
    if (imageDisplayOptionsZStart.intValue() != 3) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "ZStart (" + imageDisplayOptionsZStart + ")");
    }
    Integer imageDisplayOptionsZStop = imageDisplayOptions.getZStop();
    if (imageDisplayOptionsZStop.intValue() != 3) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "ZStop (" + imageDisplayOptionsZStop + ")");
    }
    Integer imageDisplayOptionsTStart = imageDisplayOptions.getTStart();
    if (imageDisplayOptionsTStart.intValue() != 3) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "TStart (" + imageDisplayOptionsTStart + ")");
    }
    Integer imageDisplayOptionsTStop = imageDisplayOptions.getTStop();
    if (imageDisplayOptionsTStop.intValue() != 3) {
      System.out.println("Error: Incorrect Image CA DisplayOptions " +
        "TStop (" + imageDisplayOptionsTStop + ")");
    }
    int imageDisplayOptionsDisplayROICount =
      imageDisplayOptions.countDisplayROIList();
    List imageDisplayOptionsDisplayROIList =
      imageDisplayOptions.getDisplayROIList();
    if (imageDisplayOptionsDisplayROICount != 1 ||
      imageDisplayOptionsDisplayROIList.size() != 1)
    {
      System.out.println("Error: Incorrect number of Image CA " +
        "DisplayOptions DisplayROIs (imageDisplayOptionsDisplayROICount=" +
        imageDisplayOptionsDisplayROICount +
        ", imageDisplayOptionsDisplayROIList.size()=" +
        imageDisplayOptionsDisplayROIList.size() + ")");
    }

    // check first OME/Image/CA/DisplayChannel node
    DisplayChannelNode imageDisplayChannel1 =
      (DisplayChannelNode) imageCAList.get(8);
    Integer imageDisplayChannel1ChannelNumber =
      imageDisplayChannel1.getChannelNumber();
    if (imageDisplayChannel1ChannelNumber.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "ChannelNumber (" + imageDisplayChannel1ChannelNumber + ")");
    }
    Double imageDisplayChannel1BlackLevel =
      imageDisplayChannel1.getBlackLevel();
    if (imageDisplayChannel1BlackLevel.doubleValue() != 144.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "BlackLevel (" + imageDisplayChannel1BlackLevel + ")");
    }
    Double imageDisplayChannel1WhiteLevel =
      imageDisplayChannel1.getWhiteLevel();
    if (imageDisplayChannel1WhiteLevel.doubleValue() != 338.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "WhiteLevel (" + imageDisplayChannel1WhiteLevel + ")");
    }
    Float imageDisplayChannel1Gamma = imageDisplayChannel1.getGamma();
    if (imageDisplayChannel1Gamma != null) {
      System.out.println("Error: Image CA DisplayChannel Gamma " +
        "is not null as expected (" + imageDisplayChannel1Gamma + ")");
    }
    int imageDisplayChannel1DisplayOptionsByRedChannelCount =
      imageDisplayChannel1.countDisplayOptionsListByRedChannel();
    List imageDisplayChannel1DisplayOptionsByRedChannelList =
      imageDisplayChannel1.getDisplayOptionsListByRedChannel();
    if (imageDisplayChannel1DisplayOptionsByRedChannelCount != 1 ||
      imageDisplayChannel1DisplayOptionsByRedChannelList.size() != 1)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by RedChannel " +
        "(imageDisplayChannel1DisplayOptionsByRedChannelCount=" +
        imageDisplayChannel1DisplayOptionsByRedChannelCount +
        ", imageDisplayChannel1DisplayOptionsByRedChannelList.size()=" +
        imageDisplayChannel1DisplayOptionsByRedChannelList.size() + ")");
    }
    int imageDisplayChannel1DisplayOptionsByGreenChannelCount =
      imageDisplayChannel1.countDisplayOptionsListByGreenChannel();
    List imageDisplayChannel1DisplayOptionsByGreenChannelList =
      imageDisplayChannel1.getDisplayOptionsListByGreenChannel();
    if (imageDisplayChannel1DisplayOptionsByGreenChannelCount != 0 ||
      imageDisplayChannel1DisplayOptionsByGreenChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreenChannel " +
        "(imageDisplayChannel1DisplayOptionsByGreenChannelCount=" +
        imageDisplayChannel1DisplayOptionsByGreenChannelCount +
        ", imageDisplayChannel1DisplayOptionsByGreenChannelList.size()=" +
        imageDisplayChannel1DisplayOptionsByGreenChannelList.size() + ")");
    }
    int imageDisplayChannel1DisplayOptionsByBlueChannelCount =
      imageDisplayChannel1.countDisplayOptionsListByBlueChannel();
    List imageDisplayChannel1DisplayOptionsByBlueChannelList =
      imageDisplayChannel1.getDisplayOptionsListByBlueChannel();
    if (imageDisplayChannel1DisplayOptionsByBlueChannelCount != 0 ||
      imageDisplayChannel1DisplayOptionsByBlueChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by BlueChannel " +
        "(imageDisplayChannel1DisplayOptionsByBlueChannelCount=" +
        imageDisplayChannel1DisplayOptionsByBlueChannelCount +
        ", imageDisplayChannel1DisplayOptionsByBlueChannelList.size()=" +
        imageDisplayChannel1DisplayOptionsByBlueChannelList.size() + ")");
    }
    int imageDisplayChannel1DisplayOptionsByGreyChannelCount =
      imageDisplayChannel1.countDisplayOptionsListByGreyChannel();
    List imageDisplayChannel1DisplayOptionsByGreyChannelList =
      imageDisplayChannel1.getDisplayOptionsListByGreyChannel();
    if (imageDisplayChannel1DisplayOptionsByGreyChannelCount != 0 ||
      imageDisplayChannel1DisplayOptionsByGreyChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreyChannel " +
        "(imageDisplayChannel1DisplayOptionsByGreyChannelCount=" +
        imageDisplayChannel1DisplayOptionsByGreyChannelCount +
        ", imageDisplayChannel1DisplayOptionsByGreyChannelList.size()=" +
        imageDisplayChannel1DisplayOptionsByGreyChannelList.size() + ")");
    }

    // check second OME/Image/CA/DisplayChannel node
    DisplayChannelNode imageDisplayChannel2 =
      (DisplayChannelNode) imageCAList.get(9);
    Integer imageDisplayChannel2ChannelNumber =
      imageDisplayChannel2.getChannelNumber();
    if (imageDisplayChannel2ChannelNumber.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "ChannelNumber (" + imageDisplayChannel2ChannelNumber + ")");
    }
    Double imageDisplayChannel2BlackLevel =
      imageDisplayChannel2.getBlackLevel();
    if (imageDisplayChannel2BlackLevel.doubleValue() != 144.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "BlackLevel (" + imageDisplayChannel2BlackLevel + ")");
    }
    Double imageDisplayChannel2WhiteLevel =
      imageDisplayChannel2.getWhiteLevel();
    if (imageDisplayChannel2WhiteLevel.doubleValue() != 338.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "WhiteLevel (" + imageDisplayChannel2WhiteLevel + ")");
    }
    Float imageDisplayChannel2Gamma = imageDisplayChannel2.getGamma();
    if (imageDisplayChannel2Gamma != null) {
      System.out.println("Error: Image CA DisplayChannel Gamma " +
        "is not null as expected (" + imageDisplayChannel2Gamma + ")");
    }
    int imageDisplayChannel2DisplayOptionsByRedChannelCount =
      imageDisplayChannel2.countDisplayOptionsListByRedChannel();
    List imageDisplayChannel2DisplayOptionsByRedChannelList =
      imageDisplayChannel2.getDisplayOptionsListByRedChannel();
    if (imageDisplayChannel2DisplayOptionsByRedChannelCount != 0 ||
      imageDisplayChannel2DisplayOptionsByRedChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by RedChannel " +
        "(imageDisplayChannel2DisplayOptionsByRedChannelCount=" +
        imageDisplayChannel2DisplayOptionsByRedChannelCount +
        ", imageDisplayChannel2DisplayOptionsByRedChannelList.size()=" +
        imageDisplayChannel2DisplayOptionsByRedChannelList.size() + ")");
    }
    int imageDisplayChannel2DisplayOptionsByGreenChannelCount =
      imageDisplayChannel2.countDisplayOptionsListByGreenChannel();
    List imageDisplayChannel2DisplayOptionsByGreenChannelList =
      imageDisplayChannel2.getDisplayOptionsListByGreenChannel();
    if (imageDisplayChannel2DisplayOptionsByGreenChannelCount != 1 ||
      imageDisplayChannel2DisplayOptionsByGreenChannelList.size() != 1)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreenChannel " +
        "(imageDisplayChannel2DisplayOptionsByGreenChannelCount=" +
        imageDisplayChannel2DisplayOptionsByGreenChannelCount +
        ", imageDisplayChannel2DisplayOptionsByGreenChannelList.size()=" +
        imageDisplayChannel2DisplayOptionsByGreenChannelList.size() + ")");
    }
    int imageDisplayChannel2DisplayOptionsByBlueChannelCount =
      imageDisplayChannel2.countDisplayOptionsListByBlueChannel();
    List imageDisplayChannel2DisplayOptionsByBlueChannelList =
      imageDisplayChannel2.getDisplayOptionsListByBlueChannel();
    if (imageDisplayChannel2DisplayOptionsByBlueChannelCount != 0 ||
      imageDisplayChannel2DisplayOptionsByBlueChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by BlueChannel " +
        "(imageDisplayChannel2DisplayOptionsByBlueChannelCount=" +
        imageDisplayChannel2DisplayOptionsByBlueChannelCount +
        ", imageDisplayChannel2DisplayOptionsByBlueChannelList.size()=" +
        imageDisplayChannel2DisplayOptionsByBlueChannelList.size() + ")");
    }
    int imageDisplayChannel2DisplayOptionsByGreyChannelCount =
      imageDisplayChannel2.countDisplayOptionsListByGreyChannel();
    List imageDisplayChannel2DisplayOptionsByGreyChannelList =
      imageDisplayChannel2.getDisplayOptionsListByGreyChannel();
    if (imageDisplayChannel2DisplayOptionsByGreyChannelCount != 0 ||
      imageDisplayChannel2DisplayOptionsByGreyChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreyChannel " +
        "(imageDisplayChannel2DisplayOptionsByGreyChannelCount=" +
        imageDisplayChannel2DisplayOptionsByGreyChannelCount +
        ", imageDisplayChannel2DisplayOptionsByGreyChannelList.size()=" +
        imageDisplayChannel2DisplayOptionsByGreyChannelList.size() + ")");
    }

    // check third OME/Image/CA/DisplayChannel node
    DisplayChannelNode imageDisplayChannel3 =
      (DisplayChannelNode) imageCAList.get(10);
    Integer imageDisplayChannel3ChannelNumber =
      imageDisplayChannel3.getChannelNumber();
    if (imageDisplayChannel3ChannelNumber.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "ChannelNumber (" + imageDisplayChannel3ChannelNumber + ")");
    }
    Double imageDisplayChannel3BlackLevel =
      imageDisplayChannel3.getBlackLevel();
    if (imageDisplayChannel3BlackLevel.doubleValue() != 144.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "BlackLevel (" + imageDisplayChannel3BlackLevel + ")");
    }
    Double imageDisplayChannel3WhiteLevel =
      imageDisplayChannel3.getWhiteLevel();
    if (imageDisplayChannel3WhiteLevel.doubleValue() != 338.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "WhiteLevel (" + imageDisplayChannel3WhiteLevel + ")");
    }
    Float imageDisplayChannel3Gamma = imageDisplayChannel3.getGamma();
    if (imageDisplayChannel3Gamma != null) {
      System.out.println("Error: Image CA DisplayChannel Gamma " +
        "is not null as expected (" + imageDisplayChannel3Gamma + ")");
    }
    int imageDisplayChannel3DisplayOptionsByRedChannelCount =
      imageDisplayChannel3.countDisplayOptionsListByRedChannel();
    List imageDisplayChannel3DisplayOptionsByRedChannelList =
      imageDisplayChannel3.getDisplayOptionsListByRedChannel();
    if (imageDisplayChannel3DisplayOptionsByRedChannelCount != 0 ||
      imageDisplayChannel3DisplayOptionsByRedChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by RedChannel " +
        "(imageDisplayChannel3DisplayOptionsByRedChannelCount=" +
        imageDisplayChannel3DisplayOptionsByRedChannelCount +
        ", imageDisplayChannel3DisplayOptionsByRedChannelList.size()=" +
        imageDisplayChannel3DisplayOptionsByRedChannelList.size() + ")");
    }
    int imageDisplayChannel3DisplayOptionsByGreenChannelCount =
      imageDisplayChannel3.countDisplayOptionsListByGreenChannel();
    List imageDisplayChannel3DisplayOptionsByGreenChannelList =
      imageDisplayChannel3.getDisplayOptionsListByGreenChannel();
    if (imageDisplayChannel3DisplayOptionsByGreenChannelCount != 0 ||
      imageDisplayChannel3DisplayOptionsByGreenChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreenChannel " +
        "(imageDisplayChannel3DisplayOptionsByGreenChannelCount=" +
        imageDisplayChannel3DisplayOptionsByGreenChannelCount +
        ", imageDisplayChannel3DisplayOptionsByGreenChannelList.size()=" +
        imageDisplayChannel3DisplayOptionsByGreenChannelList.size() + ")");
    }
    int imageDisplayChannel3DisplayOptionsByBlueChannelCount =
      imageDisplayChannel3.countDisplayOptionsListByBlueChannel();
    List imageDisplayChannel3DisplayOptionsByBlueChannelList =
      imageDisplayChannel3.getDisplayOptionsListByBlueChannel();
    if (imageDisplayChannel3DisplayOptionsByBlueChannelCount != 1 ||
      imageDisplayChannel3DisplayOptionsByBlueChannelList.size() != 1)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by BlueChannel " +
        "(imageDisplayChannel3DisplayOptionsByBlueChannelCount=" +
        imageDisplayChannel3DisplayOptionsByBlueChannelCount +
        ", imageDisplayChannel3DisplayOptionsByBlueChannelList.size()=" +
        imageDisplayChannel3DisplayOptionsByBlueChannelList.size() + ")");
    }
    int imageDisplayChannel3DisplayOptionsByGreyChannelCount =
      imageDisplayChannel3.countDisplayOptionsListByGreyChannel();
    List imageDisplayChannel3DisplayOptionsByGreyChannelList =
      imageDisplayChannel3.getDisplayOptionsListByGreyChannel();
    if (imageDisplayChannel3DisplayOptionsByGreyChannelCount != 0 ||
      imageDisplayChannel3DisplayOptionsByGreyChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreyChannel " +
        "(imageDisplayChannel3DisplayOptionsByGreyChannelCount=" +
        imageDisplayChannel3DisplayOptionsByGreyChannelCount +
        ", imageDisplayChannel3DisplayOptionsByGreyChannelList.size()=" +
        imageDisplayChannel3DisplayOptionsByGreyChannelList.size() + ")");
    }

    // check fourth OME/Image/CA/DisplayChannel node
    DisplayChannelNode imageDisplayChannel4 =
      (DisplayChannelNode) imageCAList.get(11);
    Integer imageDisplayChannel4ChannelNumber =
      imageDisplayChannel4.getChannelNumber();
    if (imageDisplayChannel4ChannelNumber.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "ChannelNumber (" + imageDisplayChannel4ChannelNumber + ")");
    }
    Double imageDisplayChannel4BlackLevel =
      imageDisplayChannel4.getBlackLevel();
    if (imageDisplayChannel4BlackLevel.doubleValue() != 144.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "BlackLevel (" + imageDisplayChannel4BlackLevel + ")");
    }
    Double imageDisplayChannel4WhiteLevel =
      imageDisplayChannel4.getWhiteLevel();
    if (imageDisplayChannel4WhiteLevel.doubleValue() != 338.0) {
      System.out.println("Error: Incorrect Image CA DisplayChannel " +
        "WhiteLevel (" + imageDisplayChannel4WhiteLevel + ")");
    }
    Float imageDisplayChannel4Gamma = imageDisplayChannel4.getGamma();
    if (imageDisplayChannel4Gamma != null) {
      System.out.println("Error: Image CA DisplayChannel Gamma " +
        "is not null as expected (" + imageDisplayChannel4Gamma + ")");
    }
    int imageDisplayChannel4DisplayOptionsByRedChannelCount =
      imageDisplayChannel4.countDisplayOptionsListByRedChannel();
    List imageDisplayChannel4DisplayOptionsByRedChannelList =
      imageDisplayChannel4.getDisplayOptionsListByRedChannel();
    if (imageDisplayChannel4DisplayOptionsByRedChannelCount != 0 ||
      imageDisplayChannel4DisplayOptionsByRedChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by RedChannel " +
        "(imageDisplayChannel4DisplayOptionsByRedChannelCount=" +
        imageDisplayChannel4DisplayOptionsByRedChannelCount +
        ", imageDisplayChannel4DisplayOptionsByRedChannelList.size()=" +
        imageDisplayChannel4DisplayOptionsByRedChannelList.size() + ")");
    }
    int imageDisplayChannel4DisplayOptionsByGreenChannelCount =
      imageDisplayChannel4.countDisplayOptionsListByGreenChannel();
    List imageDisplayChannel4DisplayOptionsByGreenChannelList =
      imageDisplayChannel4.getDisplayOptionsListByGreenChannel();
    if (imageDisplayChannel4DisplayOptionsByGreenChannelCount != 0 ||
      imageDisplayChannel4DisplayOptionsByGreenChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreenChannel " +
        "(imageDisplayChannel4DisplayOptionsByGreenChannelCount=" +
        imageDisplayChannel4DisplayOptionsByGreenChannelCount +
        ", imageDisplayChannel4DisplayOptionsByGreenChannelList.size()=" +
        imageDisplayChannel4DisplayOptionsByGreenChannelList.size() + ")");
    }
    int imageDisplayChannel4DisplayOptionsByBlueChannelCount =
      imageDisplayChannel4.countDisplayOptionsListByBlueChannel();
    List imageDisplayChannel4DisplayOptionsByBlueChannelList =
      imageDisplayChannel4.getDisplayOptionsListByBlueChannel();
    if (imageDisplayChannel4DisplayOptionsByBlueChannelCount != 0 ||
      imageDisplayChannel4DisplayOptionsByBlueChannelList.size() != 0)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by BlueChannel " +
        "(imageDisplayChannel4DisplayOptionsByBlueChannelCount=" +
        imageDisplayChannel4DisplayOptionsByBlueChannelCount +
        ", imageDisplayChannel4DisplayOptionsByBlueChannelList.size()=" +
        imageDisplayChannel4DisplayOptionsByBlueChannelList.size() + ")");
    }
    int imageDisplayChannel4DisplayOptionsByGreyChannelCount =
      imageDisplayChannel4.countDisplayOptionsListByGreyChannel();
    List imageDisplayChannel4DisplayOptionsByGreyChannelList =
      imageDisplayChannel4.getDisplayOptionsListByGreyChannel();
    if (imageDisplayChannel4DisplayOptionsByGreyChannelCount != 1 ||
      imageDisplayChannel4DisplayOptionsByGreyChannelList.size() != 1)
    {
      System.out.println("Error: Incorrect number of first Image CA " +
        "DisplayChannel's DisplayOptions by GreyChannel " +
        "(imageDisplayChannel4DisplayOptionsByGreyChannelCount=" +
        imageDisplayChannel4DisplayOptionsByGreyChannelCount +
        ", imageDisplayChannel4DisplayOptionsByGreyChannelList.size()=" +
        imageDisplayChannel4DisplayOptionsByGreyChannelList.size() + ")");
    }

    // check OME/Image/CA/DisplayROI node
    DisplayROINode imageDisplayROI = (DisplayROINode) imageCAList.get(12);
    Integer imageDisplayROIX0 = imageDisplayROI.getX0();
    if (imageDisplayROIX0.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayROI X0 (" +
        imageDisplayROIX0 + ")");
    }
    Integer imageDisplayROIY0 = imageDisplayROI.getY0();
    if (imageDisplayROIY0.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayROI Y0 (" +
        imageDisplayROIY0 + ")");
    }
    Integer imageDisplayROIZ0 = imageDisplayROI.getZ0();
    if (imageDisplayROIZ0.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayROI Z0 (" +
        imageDisplayROIZ0 + ")");
    }
    Integer imageDisplayROIX1 = imageDisplayROI.getX1();
    if (imageDisplayROIX1.intValue() != 512) {
      System.out.println("Error: Incorrect Image CA DisplayROI X1 (" +
        imageDisplayROIX1 + ")");
    }
    Integer imageDisplayROIY1 = imageDisplayROI.getY1();
    if (imageDisplayROIY1.intValue() != 512) {
      System.out.println("Error: Incorrect Image CA DisplayROI Y1 (" +
        imageDisplayROIY1 + ")");
    }
    Integer imageDisplayROIZ1 = imageDisplayROI.getZ1();
    if (imageDisplayROIZ1.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayROI Z1 (" +
        imageDisplayROIZ1 + ")");
    }
    Integer imageDisplayROIT0 = imageDisplayROI.getT0();
    if (imageDisplayROIT0.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayROI T0 (" +
        imageDisplayROIT0 + ")");
    }
    Integer imageDisplayROIT1 = imageDisplayROI.getT1();
    if (imageDisplayROIT1.intValue() != 0) {
      System.out.println("Error: Incorrect Image CA DisplayROI T1 (" +
        imageDisplayROIT1 + ")");
    }

    // check OME/Image/CA/StageLabel node
    StageLabelNode imageStageLabel = (StageLabelNode) imageCAList.get(13);
    String imageStageLabelName = imageStageLabel.getName();
    if (!imageStageLabelName.equals("Zulu")) {
      System.out.println("Error: Incorrect Image CA StageLabel Name (" +
        imageStageLabelName + ")");
    }
    Float imageStageLabelX = imageStageLabel.getX();
    if (imageStageLabelX.floatValue() != 123f) {
      System.out.println("Error: Incorrect Image CA StageLabel X (" +
        imageStageLabelX + ")");
    }
    Float imageStageLabelY = imageStageLabel.getY();
    if (imageStageLabelY.floatValue() != 456f) {
      System.out.println("Error: Incorrect Image CA StageLabel Y (" +
        imageStageLabelY + ")");
    }
    Float imageStageLabelZ = imageStageLabel.getZ();
    if (imageStageLabelZ.floatValue() != 789f) {
      System.out.println("Error: Incorrect Image CA StageLabel Z (" +
        imageStageLabelZ + ")");
    }

    // check OME/Image/CA/ImagePlate node
    ImagePlateNode imageImagePlate = (ImagePlateNode) imageCAList.get(14);
    Integer imageImagePlateSample = imageImagePlate.getSample();
    if (imageImagePlateSample.intValue() != 1) {
      System.out.println("Error: Incorrect Image CA ImagePlate Sample (" +
        imageImagePlateSample + ")");
    }
    String imageImagePlateWell = imageImagePlate.getWell();
    if (!imageImagePlateWell.equals("A03")) {
      System.out.println("Error: Incorrect Image CA ImagePlate Well (" +
        imageImagePlateWell + ")");
    }

    // check OME/Image/CA/Pixels node
    PixelsNode imageCAPixels = (PixelsNode) imageCAList.get(15);
    if (!imageCAPixels.equals(imagePixels)) {
      System.out.println("Error: Image CA Pixels " +
        "does not match Image Pixels");
    }

    // check first OME/CA/ExperimenterGroup's Experimenter node
    ExperimenterNode experimenterGroup1Experimenter =
      (ExperimenterNode) experimenterGroup1.getExperimenter();
    if (!experimenterGroup1Experimenter.equals(projectOwner)) {
      System.out.println("Error: first CA " +
        "ExperimenterGroup Experimenter does not match Project Owner");
    }

    // check first OME/CA/ExperimenterGroup's Group node
    GroupNode experimenterGroup1Group =
      (GroupNode) experimenterGroup1.getGroup();
    if (!experimenterGroup1Group.equals(projectGroup)) {
      System.out.println("Error: first CA " +
        "ExperimenterGroup Group does not match Project Group");
    }

    // check second OME/CA/ExperimenterGroup's Experimenter node
    ExperimenterNode experimenterGroup2Experimenter =
      (ExperimenterNode) experimenterGroup2.getExperimenter();
    if (!experimenterGroup2Experimenter.equals(projectOwner)) {
      System.out.println("Error: second CA ExperimenterGroup " +
        "Experimenter does not match Project Owner");
    }

    // check second OME/CA/ExperimenterGroup's Group node
    GroupNode experimenterGroup2Group =
      (GroupNode) experimenterGroup2.getGroup();
    if (experimenterGroup2Group != null) {
      System.out.println(
        "Error: second CA ExperimenterGroup Group is not null as expected (" +
        experimenterGroup2Group + ")");
    }

    // check OME/CA/Experiment/Experimenter node
    ExperimenterNode experimentExperimenter =
      (ExperimenterNode) experiment.getExperimenter();
    if (!experimentExperimenter.equals(projectOwner)) {
      System.out.println(
        "Error: CA Experiment Experimenter does not match Project Owner");
    }

    // check OME/CA/Experiment/ImageExperiment node
    ImageExperimentNode experimentImageExperiment =
      (ImageExperimentNode) experimentImageExperimentList.get(0);
    if (!experimentImageExperiment.equals(imageImageExperiment)) {
      System.out.println("Error: CA Experiment ImageExperiment " +
        "does not match Image CA ImageExperiment");
    }

    // check OME/CA/Instrument/ImageInstrument node
    ImageInstrumentNode instrumentImageInstrument =
      (ImageInstrumentNode) instrumentImageInstrumentList.get(0);
    if (!instrumentImageInstrument.equals(imageImageInstrument)) {
      System.out.println("Error: CA Instrument ImageInstrument " +
        "does not match Image CA ImageInstrument");
    }

    // check OME/CA/Instrument/LightSource[0] node
    LightSourceNode instrumentLightSource0 =
      (LightSourceNode) instrumentLightSourceList.get(0);
    if (!instrumentLightSource0.equals(lightSource1)) {
      System.out.println("Error: CA Instrument LightSource[0] " +
        "does not match first CA LightSource");
    }

    // check OME/CA/Instrument/LightSource[1] node
    LightSourceNode instrumentLightSource1 =
      (LightSourceNode) instrumentLightSourceList.get(1);
    if (!instrumentLightSource1.equals(lightSource2)) {
      System.out.println("Error: CA Instrument LightSource[1] " +
        "does not match second CA LightSource");
    }

    // check OME/CA/Instrument/Detector node
    DetectorNode instrumentDetector =
      (DetectorNode) instrumentDetectorList.get(0);
    if (!instrumentDetector.equals(detector)) {
      System.out.println("Error: CA Instrument Detector " +
        "does not match CA Detector");
    }

    // check OME/CA/Instrument/Objective node
    ObjectiveNode instrumentObjective =
      (ObjectiveNode) instrumentObjectiveList.get(0);
    if (!instrumentObjective.equals(objective)) {
      System.out.println("Error: CA Instrument Objective " +
        "does not match CA Objective");
    }

    // check OME/CA/Instrument/Filter node
    FilterNode instrumentFilter = (FilterNode) instrumentFilterList.get(0);
    if (!instrumentFilter.equals(filter)) {
      System.out.println("Error: CA Instrument Filter " +
        "does not match CA Filter");
    }

    // check OME/CA/Instrument/OTF node
    OTFNode instrumentOTF = (OTFNode) instrumentOTFList.get(0);
    if (!instrumentOTF.equals(otf)) {
      System.out.println("Error: CA Instrument OTF " +
        "does not match CA OTF");
    }

    // check first OME/CA/LightSource's Instrument
    InstrumentNode lightSource1Instrument =
      (InstrumentNode) lightSource1.getInstrument();
    if (!lightSource1Instrument.equals(instrument)) {
      System.out.println("Error: first CA LightSource's Instrument " +
        "does not match CA Instrument");
    }

    // check first OME/CA/LightSource's LogicalChannel by AuxLightSource
    LogicalChannelNode lightSource1LogicalChannelByAuxLightSource =
      (LogicalChannelNode)
      lightSource1LogicalChannelsByAuxLightSourceList.get(0);
    if (!lightSource1LogicalChannelByAuxLightSource.equals(
      imageLogicalChannel))
    {
      System.out.println("Error: first CA LightSource's LogicalChannel " +
        "by AuxLightSource does not match Image CA LogicalChannel");
    }

    // check first OME/CA/LightSource's Laser by LightSource
    LaserNode lightSource1LaserByLightSource =
      (LaserNode) lightSource1LasersByLightSourceList.get(0);
    if (!lightSource1LaserByLightSource.equals(laser)) {
      System.out.println("Error: first CA LightSource's " +
        "Laser by LightSource does not match CA Laser");
    }

    // check OME/CA/Laser/LightSource node
    LightSourceNode laserLightSource =
      (LightSourceNode) laser.getLightSource();
    if (!laserLightSource.equals(lightSource1)) {
      System.out.println("Error: CA Laser LightSource " +
        "does not match first CA LightSource");
    }

    // check OME/CA/Laser/Pump node
    LightSourceNode laserPump = (LightSourceNode) laser.getPump();
    if (laserPump != null) {
      System.out.println("Error: CA Laser Pump is not null as expected (" +
        laserPump + ")");
    }

    // check second OME/CA/LightSource's Instrument
    InstrumentNode lightSource2Instrument =
      (InstrumentNode) lightSource2.getInstrument();
    if (!lightSource2Instrument.equals(instrument)) {
      System.out.println("Error: second CA LightSource's Instrument " +
        "does not match CA Instrument");
    }

    // check second OME/CA/LightSource's LogicalChannel by LightSource node
    LogicalChannelNode lightSource2LogicalChannelByLightSource =
      (LogicalChannelNode)
      lightSource2LogicalChannelsByLightSourceList.get(0);
    if (!lightSource2LogicalChannelByLightSource.equals(
      imageLogicalChannel))
    {
      System.out.println("Error: second CA LightSource's LogicalChannel " +
        "by AuxLightSource does not match Image CA LogicalChannel");
    }

    // check second OME/CA/LightSource's Arc node
    ArcNode lightSource2Arc = (ArcNode) lightSource2ArcList.get(0);
    if (!lightSource2Arc.equals(arc)) {
      System.out.println("Error: second CA LightSource's Arc " +
        "does not match CA Arc");
    }

    // check OME/CA/Arc/LightSource node
    LightSourceNode arcLightSource = (LightSourceNode) arc.getLightSource();
    if (!arcLightSource.equals(lightSource2)) {
      System.out.println("Error: CA Arc LightSource " +
        "does not match second CA LightSource");
    }

    // check OME/CA/Detector/Instrument node
    InstrumentNode detectorInstrument =
      (InstrumentNode) detector.getInstrument();
    if (!detectorInstrument.equals(instrument)) {
      System.out.println("Error: CA Detector Instrument " +
        "does not match CA Instrument");
    }

    // check OME/CA/Detector/LogicalChannel node
    LogicalChannelNode detectorLogicalChannel =
      (LogicalChannelNode) detectorLogicalChannelList.get(0);
    if (!detectorLogicalChannel.equals(imageLogicalChannel)) {
      System.out.println("Error: CA Detector LogicalChannel " +
        "does not match Image CA LogicalChannel");
    }

    // check OME/CA/Objective/Instrument node
    InstrumentNode objectiveInstrument =
      (InstrumentNode) objective.getInstrument();
    if (!objectiveInstrument.equals(instrument)) {
      System.out.println("Error: CA Objective Instrument " +
        "does not match CA Instrument");
    }

    // check OME/CA/Objective/ImageInstrument node
    ImageInstrumentNode objectiveImageInstrument = (ImageInstrumentNode)
      objectiveImageInstrumentList.get(0);
    if (!instrumentImageInstrument.equals(imageImageInstrument)) {
      System.out.println("Error: CA Objective ImageInstrument " +
        "does not match Image CA ImageInstrument");
    }

    // check OME/CA/Objective/OTF node
    OTFNode objectiveOTF = (OTFNode) objectiveOTFList.get(0);
    if (!objectiveOTF.equals(otf)) {
      System.out.println("Error: CA Objective OTF does not match CA OTF");
    }

    // check OME/CA/Filter/Instrument node
    InstrumentNode filterInstrument =
      (InstrumentNode) filter.getInstrument();
    if (!filterInstrument.equals(instrument)) {
      System.out.println("Error: CA Filter Instrument " +
        "does not match CA Instrument");
    }

    // check OME/CA/Filter/LogicalChannel ndoe
    LogicalChannelNode filterLogicalChannel =
      (LogicalChannelNode) filterLogicalChannelList.get(0);
    if (!filterLogicalChannel.equals(imageLogicalChannel)) {
      System.out.println("Error: CA Filter LogicalChannel " +
        "does not match Image CA LogicalChannel");
    }

    // check OME/CA/Filter/FilterSet node
    FilterSetNode filterFilterSet =
      (FilterSetNode) filterFilterSetList.get(0);
    if (!filterFilterSet.equals(filterSet)) {
      System.out.println("Error: CA Filter FilterSet " +
        "does not match CA FilterSet");
    }

    // check OME/CA/Filter/OTF node
    OTFNode filterOTF = (OTFNode) filterOTFList.get(0);
    if (!filterOTF.equals(otf)) {
      System.out.println("Error: CA Filter OTF does not match CA OTF");
    }

    // check OME/CA/FilterSet/Filter node
    FilterNode filterSetFilter = (FilterNode) filterSet.getFilter();
    if (!filterSetFilter.equals(filter)) {
      System.out.println("Error: CA FilterSet Filter " +
        "does not match CA Filter");
    }

    // check OME/CA/OTF/Objective node
    ObjectiveNode otfObjective = (ObjectiveNode) otf.getObjective();
    if (!otfObjective.equals(objective)) {
      System.out.println("Error: CA OTF Objective " +
        "does not match CA Objective");
    }

    // check OME/CA/OTF/Filter node
    FilterNode otfFilter = (FilterNode) otf.getFilter();
    if (!otfFilter.equals(filter)) {
      System.out.println("Error: CA OTF Filter does not match CA Filter");
    }

    // check OME/CA/OTF/Repository node
    RepositoryNode otfRepository = (RepositoryNode) otf.getRepository();
    if (otfRepository != null) {
      System.out.println("Error: CA OTF Repository is not null as expected (" +
        otfRepository + ")");
    }

    // check OME/CA/OTF/Instrument node
    InstrumentNode otfInstrument = (InstrumentNode) otf.getInstrument();
    if (!otfInstrument.equals(instrument)) {
      System.out.println("Error: CA OTF Instrument " +
        "does not match CA Instrument");
    }

    // check OME/CA/OTF/LogicalChannel node
    LogicalChannelNode otfLogicalChannel =
      (LogicalChannelNode) otfLogicalChannelList.get(0);
    if (!otfLogicalChannel.equals(imageLogicalChannel)) {
      System.out.println("Error: CA OTF LogicalChannel " +
        "does not match Image CA LogicalChannel");
    }

    // check OME/CA/Plate/ImagePlate node
    ImagePlateNode plateImagePlate =
      (ImagePlateNode) plateImagePlateList.get(0);
    if (!plateImagePlate.equals(imageImagePlate)) {
      System.out.println(
        "Error: CA Plate ImagePlate does not match Image CA ImagePlate");
    }

    // check OME/CA/Plate/PlateScreen[0] node
    PlateScreenNode platePlateScreen0 =
      (PlateScreenNode) platePlateScreenList.get(0);
    if (!platePlateScreen0.equals(plateScreen1)) {
      System.out.println("Error: CA Plate PlateScreen[0] " +
        "does not match first CA PlateScreen");
    }

    // check OME/CA/Plate/PlateScreen[1] node
    PlateScreenNode platePlateScreen1 =
      (PlateScreenNode) platePlateScreenList.get(1);
    if (!platePlateScreen1.equals(plateScreen2)) {
      System.out.println("Error: CA Plate PlateScreen[1] " +
        "does not match second CA PlateScreen");
    }

    // check first OME/CA/PlateScreen's Plate node
    PlateNode plateScreen1Plate = (PlateNode) plateScreen1.getPlate();
    if (!plateScreen1Plate.equals(plate)) {
      System.out.println("Error: first CA PlateScreen's Plate " +
        "does not match CA Plate");
    }

    // check first OME/CA/PlateScreen's Screen node
    ScreenNode plateScreen1Screen = (ScreenNode) plateScreen1.getScreen();
    if (!plateScreen1Screen.equals(screen)) {
      System.out.println("Error: first CA PlateScreen's Screen " +
        "does not match CA Screen");
    }

    // check second OME/CA/PlateScreen's Plate node
    PlateNode plateScreen2Plate = (PlateNode) plateScreen2.getPlate();
    if (!plateScreen2Plate.equals(plate)) {
      System.out.println("Error: second CA PlateScreen's Plate " +
        "does not match CA Plate");
    }

    // check second OME/CA/PlateScreen's Screen node
    ScreenNode plateScreen2Screen = (ScreenNode) plateScreen2.getScreen();
    if (plateScreen2Screen != null) {
      System.out.println("Error: second CA PlateScreen's Screen " +
        "is not null as expected (" + plateScreen2Screen + ")");
    }

    // -- Depth 5 --

    // check OME/Project/Owner/ExperimenterGroup[0]/Experimenter node
    ExperimenterNode projectOwnerExperimenterGroup0Experimenter =
      (ExperimenterNode) projectOwnerExperimenterGroup0.getExperimenter();
    if (!projectOwnerExperimenterGroup0Experimenter.equals(projectOwner)) {
      System.out.println("Error: Project Owner ExperimenterGroup[0] " +
        "Experimenter does not match Project Owner");
    }

    // check OME/Project/Owner/ExperimenterGroup[0]/Group node
    GroupNode projectOwnerExperimenterGroup0Group =
      (GroupNode) projectOwnerExperimenterGroup0.getGroup();
    if (!projectOwnerExperimenterGroup0Group.equals(projectGroup)) {
      System.out.println("Error: Project Owner ExperimenterGroup[0] " +
        "Group does not match Project Group");
    }

    // check OME/Project/Owner/ExperimenterGroup[1]/Experimenter node
    ExperimenterNode projectOwnerExperimenterGroup1Experimenter =
      (ExperimenterNode) projectOwnerExperimenterGroup1.getExperimenter();
    if (!projectOwnerExperimenterGroup1Experimenter.equals(projectOwner)) {
      System.out.println("Error: Project Owner ExperimenterGroup[1] " +
        "Experimenter does not match Project Owner");
    }

    // check OME/Project/Owner/ExperimenterGroup[1]/Group node
    GroupNode projectOwnerExperimenterGroup1Group =
      (GroupNode) projectOwnerExperimenterGroup1.getGroup();
    if (projectOwnerExperimenterGroup1Group != null) {
      System.out.println("Error: Project Owner ExperimenterGroup[1] " +
        "Group is not null as expected (" +
        projectOwnerExperimenterGroup1Group + ")");
    }

    // check OME/Image/CA/ImageExperiment/Experiment node
    ExperimentNode imageImageExperimentExperiment =
      (ExperimentNode) imageImageExperiment.getExperiment();
    if (!imageImageExperimentExperiment.equals(experiment)) {
      System.out.println("Error: Image CA ImageExperiment " +
        "Experiment does not match CA Experiment");
    }

    // check OME/Image/CA/ImageInstrument/Instrument node
    InstrumentNode imageImageInstrumentInstrument =
      (InstrumentNode) imageImageInstrument.getInstrument();
    if (!imageImageInstrumentInstrument.equals(instrument)) {
      System.out.println("Error: Image CA ImageInstrument " +
        "Instrument does not match CA Instrument");
    }

    // check OME/Image/CA/ImageInstrument/Objective node
    ObjectiveNode imageImageInstrumentObjective =
      (ObjectiveNode) imageImageInstrument.getObjective();
    if (!imageImageInstrumentObjective.equals(objective)) {
      System.out.println("Error: Image CA ImageInstrument " +
        "Objective does not match CA Objective");
    }

    // check OME/Image/CA/Thumbnail/Repository node
    RepositoryNode imageThumbnailRepository =
      (RepositoryNode) imageThumbnail.getRepository();
    if (imageThumbnailRepository != null) {
      System.out.println("Error: Image CA Thumbnail Repository " +
        "is not null as expected (" + imageThumbnailRepository + ")");
    }

    // check OME/Image/CA/LogicalChannel/Filter node
    FilterNode imageLogicalChannelFilter =
      (FilterNode) imageLogicalChannel.getFilter();
    if (!imageLogicalChannelFilter.equals(filter)) {
      System.out.println("Error: Image CA LogicalChannel Filter " +
        "does not match CA Filter");
    }

    // check OME/Image/CA/LogicalChannel/LightSource node
    LightSourceNode imageLogicalChannelLightSource =
      (LightSourceNode) imageLogicalChannel.getLightSource();
    if (!imageLogicalChannelLightSource.equals(lightSource2)) {
      System.out.println("Error: Image CA LogicalChannel LightSource " +
        "does not match second CA LightSource");
    }

    // check OME/Image/CA/LogicalChannel/OTF node
    OTFNode imageLogicalChannelOTF =
      (OTFNode) imageLogicalChannel.getOTF();
    if (!imageLogicalChannelOTF.equals(otf)) {
      System.out.println("Error: Image CA LogicalChannel OTF " +
        "does not match CA OTF");
    }

    // check OME/Image/CA/LogicalChannel/Detector node
    DetectorNode imageLogicalChannelDetector =
      (DetectorNode) imageLogicalChannel.getDetector();
    if (!imageLogicalChannelDetector.equals(detector)) {
      System.out.println("Error: Image CA LogicalChannel Detector " +
        "does not match CA Detector");
    }

    // check OME/Image/CA/LogicalChannel/AuxLightSource node
    LightSourceNode imageLogicalChannelAuxLightSource =
      (LightSourceNode) imageLogicalChannel.getAuxLightSource();
    if (!imageLogicalChannelAuxLightSource.equals(lightSource1)) {
      System.out.println("Error: Image CA LogicalChannel AuxLightSource " +
        "does not match first CA LightSource");
    }

    // check OME/Image/CA/LogicalChannel/PixelChannelComponent node
    PixelChannelComponentNode imageLogicalChannelPixelChannelComponent =
      (PixelChannelComponentNode)
      imageLogicalChannelPixelChannelComponentList.get(0);
    if (!imageLogicalChannelPixelChannelComponent.equals(
      imagePixelsPixelChannelComponent))
    {
      System.out.println("Error: Image CA LogicalChannel " +
        "PixelChannelComponent does not match " +
        "Image Pixels PixelChannelComponent");
    }

    // check OME/Image/CA/PixelChannelComponent/Pixels node
    PixelsNode imagePixelChannelComponentPixels =
      (PixelsNode) imagePixelChannelComponent.getPixels();
    if (!imagePixelChannelComponentPixels.equals(imagePixels)) {
      System.out.println("Error: Image CA PixelChannelComponent Pixels " +
        "does not match Image Pixels");
    }

    // check OME/Image/CA/PixelChannelComponent/LogicalChannel node
    LogicalChannelNode imagePixelChannelComponentLogicalChannel =
      (LogicalChannelNode) imagePixelChannelComponent.getLogicalChannel();
    if (!imagePixelChannelComponentLogicalChannel.equals(
      imageLogicalChannel))
    {
      System.out.println("Error: Image CA PixelChannelComponent " +
        "LogicalChannel does not match Image CA LogicalChannel");
    }

    // check OME/Image/CA/DisplayOptions/RedChannel node
    DisplayChannelNode imageDisplayOptionsRedChannel =
      (DisplayChannelNode) imageDisplayOptions.getRedChannel();
    if (!imageDisplayOptionsRedChannel.equals(imageDisplayChannel1)) {
      System.out.println("Error: Image CA DisplayOptions RedChannel " +
        "does not match first Image CA DisplayChannel");
    }

    // check OME/Image/CA/DisplayOptions/GreenChannel node
    DisplayChannelNode imageDisplayOptionsGreenChannel =
      (DisplayChannelNode) imageDisplayOptions.getGreenChannel();
    if (!imageDisplayOptionsGreenChannel.equals(imageDisplayChannel2)) {
      System.out.println("Error: Image CA DisplayOptions GreenChannel " +
        "does not match second Image CA DisplayChannel");
    }

    // check OME/Image/CA/DisplayOptions/BlueChannel node
    DisplayChannelNode imageDisplayOptionsBlueChannel =
      (DisplayChannelNode) imageDisplayOptions.getBlueChannel();
    if (!imageDisplayOptionsBlueChannel.equals(imageDisplayChannel3)) {
      System.out.println("Error: Image CA DisplayOptions BlueChannel " +
        "does not match third Image CA DisplayChannel");
    }

    // check OME/Image/CA/DisplayOptions/GreyChannel node
    DisplayChannelNode imageDisplayOptionsGreyChannel =
      (DisplayChannelNode) imageDisplayOptions.getGreyChannel();
    if (!imageDisplayOptionsGreyChannel.equals(imageDisplayChannel4)) {
      System.out.println("Error: Image CA DisplayOptions GreyChannel " +
        "does not match fourth Image CA DisplayChannel");
    }

    // check OME/Image/CA/DisplayOptions/DisplayROI node
    DisplayROINode imageDisplayOptionsDisplayROI =
      (DisplayROINode) imageDisplayOptionsDisplayROIList.get(0);
    if (!imageDisplayOptionsDisplayROI.equals(imageDisplayROI)) {
      System.out.println("Error: Image CA DisplayOptions DisplayROI " +
        "does not match Image CA DisplayROI");
    }

    // check first OME/Image/CA/DisplayChannel's
    // DisplayOptions by RedChannel node
    DisplayOptionsNode imageDisplayChannel1DisplayOptionsByRedChannel =
      (DisplayOptionsNode)
      imageDisplayChannel1DisplayOptionsByRedChannelList.get(0);
    if (!imageDisplayChannel1DisplayOptionsByRedChannel.equals(
      imageDisplayOptions))
    {
      System.out.println("Error: first Image CA DisplayChannel's " +
        "DisplayOptions by RedChannel does not match " +
        "Image CA DisplayOptions");
    }

    // check second OME/Image/CA/DisplayChannel's
    // DisplayOptions by GreenChannel node
    DisplayOptionsNode imageDisplayChannel2DisplayOptionsByGreenChannel =
      (DisplayOptionsNode)
      imageDisplayChannel2DisplayOptionsByGreenChannelList.get(0);
    if (!imageDisplayChannel2DisplayOptionsByGreenChannel.equals(
      imageDisplayOptions))
    {
      System.out.println("Error: second Image CA DisplayChannel's " +
        "DisplayOptions by GreenChannel does not match " +
        "Image CA DisplayOptions");
    }

    // check third OME/Image/CA/DisplayChannel's
    // DisplayOptions by BlueChannel node
    DisplayOptionsNode imageDisplayChannel3DisplayOptionsByBlueChannel =
      (DisplayOptionsNode)
      imageDisplayChannel3DisplayOptionsByBlueChannelList.get(0);
    if (!imageDisplayChannel3DisplayOptionsByBlueChannel.equals(
      imageDisplayOptions))
    {
      System.out.println("Error: third Image CA DisplayChannel's " +
        "DisplayOptions by BlueChannel does not match " +
        "Image CA DisplayOptions");
    }

    // check fourth OME/Image/CA/DisplayChannel's
    // DisplayOptions by GreyChannel node
    DisplayOptionsNode imageDisplayChannel4DisplayOptionsByGreyChannel =
      (DisplayOptionsNode)
      imageDisplayChannel4DisplayOptionsByGreyChannelList.get(0);
    if (!imageDisplayChannel4DisplayOptionsByGreyChannel.equals(
      imageDisplayOptions))
    {
      System.out.println("Error: fourth Image CA DisplayChannel's " +
        "DisplayOptions by GreyChannel does not match " +
        "Image CA DisplayOptions");
    }

    // check OME/Image/CA/DisplayROI/DisplayOptions node
    DisplayOptionsNode imageDisplayROIDisplayOptions =
      (DisplayOptionsNode) imageDisplayROI.getDisplayOptions();
    if (!imageDisplayROIDisplayOptions.equals(imageDisplayOptions)) {
      System.out.println("Error: Image CA DisplayROI DisplayOptions " +
        "does not match Image CA DisplayOptions");
    }

    // check OME/Image/CA/ImagePlate/Plate node
    PlateNode imageImagePlatePlate = (PlateNode) imageImagePlate.getPlate();
    if (!imageImagePlatePlate.equals(plate)) {
      System.out.println("Error: Image CA ImagePlate Plate " +
        "does not match CA Plate");
    }
  }

  /** Builds a node from scratch (to match the Sample.ome file). */
  public static OMENode createNode() throws Exception {
    OMENode ome = new OMENode();

    // -- Depth 1 --

    // create OME/Project
    ProjectNode project = new ProjectNode(ome, "Stress Response Pathway",
      null, null, null);
    project.setNodeID("urn:lsid:foo.bar.com:Project:123456");

    // create OME/Dataset
    DatasetNode dataset = new DatasetNode(ome, "Controls",
      null, Boolean.FALSE, null, null);
    dataset.setNodeID("urn:lsid:foo.bar.com:Dataset:123456");

    // create OME/Image
    ImageNode image = new ImageNode(ome,
      "P1W1S1", "1988-04-07T18:39:09", "This is an Image");
    image.setNodeID("urn:lsid:foo.bar.com:Image:123456");

    // create OME/CA
    CustomAttributesNode ca = new CustomAttributesNode(ome);

    // -- Depth 2 --

    // create OME/Dataset/ProjectRef
    dataset.addToProject(project);

    // create OME/Image/DatasetRef
    image.addToDataset(dataset);

    // create OME/Image/CA
    CustomAttributesNode imageCA = new CustomAttributesNode(image);

    // create OME/CA/Experimenter
    ExperimenterNode experimenter = new ExperimenterNode(ca,
      "Nicola", "Sacco", "Nicola.Sacco@justice.net", null, null, null);
    experimenter.setNodeID("urn:lsid:foo.bar.com:Experimenter:123456");
    project.setOwner(experimenter);
    dataset.setOwner(experimenter);
    image.setOwner(experimenter);

    // create first OME/CA/ExperimenterGroup
    ExperimenterGroupNode experimenterGroup1 = new ExperimenterGroupNode(ca,
      experimenter, null);

    // create second OME/CA/ExperimenterGroup
    GroupNode dummyGroup = new GroupNode(ca, false);
    dummyGroup.setNodeID("urn:lsid:foo.bar.com:Group:123789");
    ExperimenterGroupNode experimenterGroup2 = new ExperimenterGroupNode(ca,
      experimenter, dummyGroup);

    // create OME/CA/Group
    GroupNode group = new GroupNode(ca, "IICBU", experimenter, experimenter);
    group.setNodeID("urn:lsid:foo.bar.com:Group:123456");
    project.setGroup(group);
    dataset.setGroup(group);
    image.setGroup(group);
    experimenter.setGroup(group);
    experimenterGroup1.setGroup(group);

    // create OME/CA/Experiment
    ExperimentNode experiment = new ExperimentNode(ca,
      "Time-lapse", "This was an experiment.", experimenter);
    experiment.setNodeID("urn:lsid:foo.bar.com:Experiment:123456");

    // create OME/CA/Instrument
    InstrumentNode instrument = new InstrumentNode(ca,
      "Zeiss", "foo", "bar", "Upright");
    instrument.setNodeID("urn:lsid:foo.bar.com:Instrument:123456");

    // create first OME/CA/LightSource
    LightSourceNode lightSource1 = new LightSourceNode(ca,
      "Olympus", "WMD Laser", "123skdjhf1234", instrument);
    lightSource1.setNodeID("urn:lsid:foo.bar.com:LightSource:123456");

    // create OME/CA/Laser
    LightSourceNode dummyLightSource = new LightSourceNode(ca, false);
    dummyLightSource.setNodeID("urn:lsid:foo.bar.com:LightSource:123789");
    LaserNode laser = new LaserNode(ca, "Semiconductor", "GaAs",
      null, null, null, null, null, lightSource1, dummyLightSource);

    // create second OME/CA/LightSource
    LightSourceNode lightSource2 = new LightSourceNode(ca,
      "Olympus", "Realy Bright Lite", "123skdjhf1456", instrument);
    lightSource2.setNodeID("urn:lsid:foo.bar.com:LightSource:123123");

    // create OME/CA/Arc
    ArcNode arc = new ArcNode(ca, "Hg", null, lightSource2);

    // create OME/CA/Detector
    DetectorNode detector = new DetectorNode(ca, "Kodak", "Instamatic",
      "fnuiprf89uh123498", "CCD", null, null, null, instrument);
    detector.setNodeID("urn:lsid:foo.bar.com:Detector:123456");

    // create OME/CA/Objective
    ObjectiveNode objective = new ObjectiveNode(ca, "Olympus", "SPlanL",
      "456anxcoas123", new Float(2.4f), new Float(40), instrument);
    objective.setNodeID("urn:lsid:foo.bar.com:Objective:123456");

    // create OME/CA/Filter
    FilterNode filter = new FilterNode(ca, instrument);
    filter.setNodeID("urn:lsid:foo.bar.com:Filter:123456");

    // create OME/CA/FilterSet
    FilterSetNode filterSet = new FilterSetNode(ca,
      "Omega", "SuperGFP", "123LJKHG123", filter);

    // create OME/CA/OTF
    OTFNode otf = new OTFNode(ca, objective, filter, new Integer(512),
      new Integer(512), "int8", null, null, Boolean.TRUE, instrument);
    otf.setNodeID("urn:lsid:foo.bar.com:OTF:123456");

    // create OME/CA/Plate
    PlateNode plate = new PlateNode(ca, "SRP001", "PID.SRP001", null);
    plate.setNodeID("urn:lsid:foo.bar.com:Plate:123456");

    // create first OME/CA/PlateScreen
    PlateScreenNode plateScreen1 = new PlateScreenNode(ca, plate, null);

    // create second OME/CA/PlateScreen
    ScreenNode dummyScreen = new ScreenNode(ca, false);
    dummyScreen.setNodeID("urn:lsid:foo.bar.com:Screen:123789");
    PlateScreenNode plateScreen2 = new PlateScreenNode(ca, plate, dummyScreen);

    // create OME/CA/Screen
    ScreenNode screen = new ScreenNode(ca,
      "Stress Response Pathway Controls", null, "SID.SRPC001");
    screen.setNodeID("urn:lsid:foo.bar.com:Screen:123456");
    plateScreen1.setScreen(screen);

    // -- Depth 3 --

    // create OME/Image/CA/Dimensions
    DimensionsNode dimensions = new DimensionsNode(imageCA,
      new Float(0.2f), new Float(0.2f), new Float(0.2f), null, null);

    // create OME/Image/CA/ImageExperiment
    ImageExperimentNode imageExperiment = new ImageExperimentNode(imageCA,
      experiment);

    // create OME/Image/CA/ImageInstrument
    ImageInstrumentNode imageInstrument = new ImageInstrumentNode(imageCA,
      instrument, objective);

    // create OME/Image/CA/ImagingEnvironment
    ImagingEnvironmentNode imagingEnvironment =
      new ImagingEnvironmentNode(imageCA, new Float(.1f),
      new Float(.1f), new Float(.2f), new Float(.3f));

    // create OME/Image/CA/Thumbnail
    ThumbnailNode thumbnail = new ThumbnailNode(imageCA, "image/jpeg", null,
      "http://ome.nia.gov/GetThumbnail?ID=urn:lsid:foo.bar.com:Image:123456");

    // create OME/Image/CA/LogicalChannel
    LogicalChannelNode logicalChannel = new LogicalChannelNode(imageCA,
      "Ch 1", null, filter, lightSource2, null, null, otf, detector, null,
      null, "Epifluorescence", null, null, null, null, lightSource1, null,
      "Photobleaching", null, new Integer(490), new Integer(528), "GFP",
      new Float(0));
    logicalChannel.setNodeID("urn:lsid:foo.bar.com:LogicalChannel:123456");

    // create OME/Image/CA/PixelChannelComponent
    PixelChannelComponentNode pixelChannelComponent =
      new PixelChannelComponentNode(imageCA, null,
      new Integer(0), "foo", logicalChannel);

    // create OME/Image/CA/DisplayOptions
    DisplayOptionsNode displayOptions = new DisplayOptionsNode(imageCA,
      null, new Float(1), null, Boolean.TRUE, null, Boolean.TRUE, null,
      Boolean.TRUE, Boolean.TRUE, null, null, new Integer(3), new Integer(3),
      new Integer(3), new Integer(3));
    displayOptions.setNodeID("urn:lsid:foo.bar.com:DisplayOptions:123456");

    // create first OME/Image/CA/DisplayChannel
    DisplayChannelNode displayChannelRed = new DisplayChannelNode(imageCA,
      new Integer(0), new Double(144), new Double(338), null);
    displayOptions.setRedChannel(displayChannelRed);

    // create second OME/Image/CA/DisplayChannel
    DisplayChannelNode displayChannelGreen = new DisplayChannelNode(imageCA,
      new Integer(0), new Double(144), new Double(338), null);
    displayOptions.setGreenChannel(displayChannelGreen);

    // create third OME/Image/CA/DisplayChannel
    DisplayChannelNode displayChannelBlue = new DisplayChannelNode(imageCA,
      new Integer(0), new Double(144), new Double(338), null);
    displayOptions.setBlueChannel(displayChannelBlue);

    // create fourth OME/Image/CA/DisplayChannel
    DisplayChannelNode displayChannelGrey = new DisplayChannelNode(imageCA,
      new Integer(0), new Double(144), new Double(338), null);
    displayOptions.setGreyChannel(displayChannelGrey);

    // create OME/Image/CA/DisplayROI
    DisplayROINode displayROI = new DisplayROINode(imageCA,
      new Integer(0), new Integer(0), new Integer(0), new Integer(512),
      new Integer(512), new Integer(0), new Integer(0), new Integer(0),
      displayOptions);

    // create OME/Image/CA/StageLabel
    StageLabelNode stageLabel = new StageLabelNode(imageCA,
      "Zulu", new Float(123), new Float(456), new Float(789));

    // create OME/Image/CA/ImagePlate
    ImagePlateNode imagePlate = new ImagePlateNode(imageCA,
      plate, new Integer(1), "A03");

    // create OME/Image/CA/Pixels
    PixelsNode pixels = new PixelsNode(imageCA, new Integer(20),
      new Integer(20), new Integer(5), new Integer(1), new Integer(6),
      "int16", null, null, null);
    pixels.setNodeID("urn:lsid:foo.bar.com:Pixels:123456");
    pixels.setBigEndian(Boolean.TRUE);
    pixels.setDimensionOrder("XYZCT");
    pixelChannelComponent.setPixels(pixels);
    image.setDefaultPixels(pixels);

    return ome;
  }

  // --  Main method --

  /**
   * Tests the org.openmicroscopy.xml package.
   *
   * <li>Specify path to Sample.ome to parse it and check it for errors.
   * <li>Specify -build flag to duplicate the structure in Sample.ome from
   *     scratch, then check it for errors.
   */
  public static void main(String[] args) throws Exception {
    String path = null;
    boolean build = false;
    for (int i=0; i<args.length; i++) {
      if (args[i] == null) continue;
      if (args[i].equalsIgnoreCase("-build")) build = true;
      else path = args[i];
    }

    if (path == null && !build) {
      System.out.println("Usage: java org.openmicroscopy.xml.SampleTest " +
        "[-build || /path/to/Sample.ome]");
      return;
    }

    System.out.println("Creating OME node...");
    System.out.println();
    OMENode ome = null;
    if (build) ome = createNode();
    else ome = new OMENode(new File(path));

    // perform some tests on Sample.ome structure
    System.out.println("Performing API tests...");
    testSample(ome);
    System.out.println();

    System.out.println("Writing OME-XML to String...");
    String s = ome.writeOME(false);
    System.out.println(s);
    System.out.println();

    String filename = "omexml.tmp";
    System.out.println("Writing OME-XML to file " + filename + "...");
    ome.writeOME(new File(filename), false);
  }

}
