/*
 * org.openmicroscopy.analysis.TestInstances
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy.analysis;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class TestInstances
{
    // XYZ_IMAGE_INFO data table

    public static DataTable  xyzImageInfo =
    new DataTable("XYZ_IMAGE_INFO",
                  "General image XYZ stack attributes.  Produced from XML.",
                  Granularity.IMAGE);

    public static DataTable.Column  xyzImageInfo_theW =
    xyzImageInfo.addColumn("THE_W","Wavelength","integer");
    public static DataTable.Column  xyzImageInfo_theT =
    xyzImageInfo.addColumn("THE_T","Timepoint","integer");
    public static DataTable.Column  xyzImageInfo_min =
    xyzImageInfo.addColumn("MINIMUM","Minimum","integer");
    public static DataTable.Column  xyzImageInfo_max =
    xyzImageInfo.addColumn("MAXIMUM","Maximum","integer");
    public static DataTable.Column  xyzImageInfo_mean =
    xyzImageInfo.addColumn("MEAN","Mean","integer");
    public static DataTable.Column  xyzImageInfo_geomean =
    xyzImageInfo.addColumn("GEOMEAN","Geomean","integer");
    public static DataTable.Column  xyzImageInfo_sigma =
    xyzImageInfo.addColumn("SIGMA","Sigma","integer");
    public static DataTable.Column  xyzImageInfo_centroidX =
    xyzImageInfo.addColumn("CENTROID_X","Centroid X","integer");
    public static DataTable.Column  xyzImageInfo_centroidY =
    xyzImageInfo.addColumn("CENTROID_Y","Centroid Y","integer");
    public static DataTable.Column  xyzImageInfo_centroidZ =
    xyzImageInfo.addColumn("CENTROID_Z","Centroid Z","integer");

    // XYZ_IMAGE_INFO attribute types

    public static AttributeType  stackMin =
    new AttributeType("Stack minimum",
                      "Minimum pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  stackMin_theW =
    stackMin.addColumn("Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackMin_theT =
    stackMin.addColumn("Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackMin_min =
    stackMin.addColumn("Minimum","Minimum",xyzImageInfo_min);

    public static AttributeType  stackMax =
    new AttributeType("Stack maximum",
                      "Maximum pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  stackMax_theW =
    stackMax.addColumn("Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackMax_theT =
    stackMax.addColumn("Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackMax_max =
    stackMax.addColumn("Maximum","Maximum",xyzImageInfo_max);

    public static AttributeType  stackMean =
    new AttributeType("Stack mean",
                      "Mean pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  stackMean_theW =
    stackMean.addColumn("Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackMean_theT =
    stackMean.addColumn("Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackMean_mean =
    stackMean.addColumn("Mean","Mean",xyzImageInfo_mean);

    public static AttributeType  stackGeomean =
    new AttributeType("Stack geomean",
                      "Geomean pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  stackGeomean_theW =
    stackGeomean.addColumn("Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackGeomean_theT =
    stackGeomean.addColumn("Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackGeomean_geomean =
    stackGeomean.addColumn("Geomean","Geomean",xyzImageInfo_geomean);

    public static AttributeType  stackSigma =
    new AttributeType("Stack sigma",
                      "Sigma pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  stackSigma_theW =
    stackSigma.addColumn("Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackSigma_theT =
    stackSigma.addColumn("Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackSigma_sigma =
    stackSigma.addColumn("Sigma","Sigma",xyzImageInfo_sigma);

    public static AttributeType  stackCentroid =
    new AttributeType("Stack centroid",
                      "Centroid pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  stackCentroid_theW =
    stackCentroid.addColumn("Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackCentroid_theT =
    stackCentroid.addColumn("Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackCentroid_centroidX =
    stackCentroid.addColumn("Centroid_X","Centroid X",xyzImageInfo_centroidX);
    public static AttributeType.Column  stackCentroid_centroidY =
    stackCentroid.addColumn("Centroid_Y","Centroid Y",xyzImageInfo_centroidY);
    public static AttributeType.Column  stackCentroid_centroidZ =
    stackCentroid.addColumn("Centroid_Z","Centroid Z",xyzImageInfo_centroidZ);

    // XY_IMAGE_INFO data table

    public static DataTable  xyImageInfo =
    new DataTable("XY_IMAGE_INFO",
                  "General image XY plane attributes.  Produced from XML.",
                  Granularity.IMAGE);

    public static DataTable.Column  xyImageInfo_theW =
    xyImageInfo.addColumn("THE_W","Wavelength","integer");
    public static DataTable.Column  xyImageInfo_theT =
    xyImageInfo.addColumn("THE_T","Timepoint","integer");
    public static DataTable.Column  xyImageInfo_theZ =
    xyImageInfo.addColumn("THE_Z","Z-section","integer");
    public static DataTable.Column  xyImageInfo_min =
    xyImageInfo.addColumn("MINIMUM","Minimum","integer");
    public static DataTable.Column  xyImageInfo_max =
    xyImageInfo.addColumn("MAXIMUM","Maximum","integer");
    public static DataTable.Column  xyImageInfo_mean =
    xyImageInfo.addColumn("MEAN","Mean","integer");
    public static DataTable.Column  xyImageInfo_geomean =
    xyImageInfo.addColumn("GEOMEAN","Geomean","integer");
    public static DataTable.Column  xyImageInfo_sigma =
    xyImageInfo.addColumn("SIGMA","Sigma","integer");
    public static DataTable.Column  xyImageInfo_centroidX =
    xyImageInfo.addColumn("CENTROID_X","Centroid X","integer");
    public static DataTable.Column  xyImageInfo_centroidY =
    xyImageInfo.addColumn("CENTROID_Y","Centroid Y","integer");

    // XY_IMAGE_INFO attribute types

    public static AttributeType  planeMin =
    new AttributeType("Plane minimum",
                      "Minimum pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  planeMin_theW =
    planeMin.addColumn("Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeMin_theT =
    planeMin.addColumn("Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeMin_theZ =
    planeMin.addColumn("Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeMin_min =
    planeMin.addColumn("Minimum","Minimum",xyImageInfo_min);

    public static AttributeType  planeMax =
    new AttributeType("Plane maximum",
                      "Maximum pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  planeMax_theW =
    planeMax.addColumn("Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeMax_theT =
    planeMax.addColumn("Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeMax_theZ =
    planeMax.addColumn("Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeMax_max =
    planeMax.addColumn("Maximum","Maximum",xyImageInfo_max);

    public static AttributeType  planeMean =
    new AttributeType("Plane mean",
                      "Mean pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  planeMean_theW =
    planeMean.addColumn("Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeMean_theT =
    planeMean.addColumn("Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeMean_theZ =
    planeMean.addColumn("Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeMean_mean =
    planeMean.addColumn("Mean","Mean",xyImageInfo_mean);

    public static AttributeType  planeGeomean =
    new AttributeType("Plane geomean",
                      "Geomean pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  planeGeomean_theW =
    planeGeomean.addColumn("Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeGeomean_theT =
    planeGeomean.addColumn("Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeGeomean_theZ =
    planeGeomean.addColumn("Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeGeomean_geomean =
    planeGeomean.addColumn("Geomean","Geomean",xyImageInfo_geomean);

    public static AttributeType  planeSigma =
    new AttributeType("Plane sigma",
                      "Sigma pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  planeSigma_theW =
    planeSigma.addColumn("Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeSigma_theT =
    planeSigma.addColumn("Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeSigma_theZ =
    planeSigma.addColumn("Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeSigma_sigma =
    planeSigma.addColumn("Sigma","Sigma",xyImageInfo_sigma);

    public static AttributeType  planeCentroid =
    new AttributeType("Plane centroid",
                      "Centroid pixel intensity",
                      Granularity.IMAGE);
    public static AttributeType.Column  planeCentroid_theW =
    planeCentroid.addColumn("Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeCentroid_theT =
    planeCentroid.addColumn("Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeCentroid_theZ =
    planeCentroid.addColumn("Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeCentroid_centroidX =
    planeCentroid.addColumn("Centroid_X","Centroid X",xyImageInfo_centroidX);
    public static AttributeType.Column  planeCentroid_centroidY =
    planeCentroid.addColumn("Centroid_Y","Centroid Y",xyImageInfo_centroidY);

    // LOCATION_5 data table

    public static DataTable  location5table =
    new DataTable("LOCATION_5",
                  "5D coordinate",
                  Granularity.FEATURE);

    public static DataTable.Column  location5table_X =
    location5table.addColumn("X","X coordinate","float");
    public static DataTable.Column  location5table_Y =
    location5table.addColumn("Y","Y coordinate","float");
    public static DataTable.Column  location5table_Z =
    location5table.addColumn("Z","Z coordinate","float");
    public static DataTable.Column  location5table_W =
    location5table.addColumn("W","W coordinate","float");
    public static DataTable.Column  location5table_T =
    location5table.addColumn("T","T coordinate","float");

    // LOCATION_5 attributes

    public static AttributeType  location5 =
    new AttributeType("5D location","5D location",Granularity.FEATURE);
    public static AttributeType.Column  location5_X =
    location5.addColumn("X","X",location5table_X);
    public static AttributeType.Column  location5_Y =
    location5.addColumn("Y","Y",location5table_Y);
    public static AttributeType.Column  location5_Z =
    location5.addColumn("Z","Z",location5table_Z);
    public static AttributeType.Column  location5_W =
    location5.addColumn("W","W",location5table_W);
    public static AttributeType.Column  location5_T =
    location5.addColumn("T","T",location5table_T);

    // Stack statistics module

    public static Module  stackStats =
    new Module("Stack statistics",
               "Calculate pixel statitics per XYZ stack",
               "/OME/bin/OME_Image_XYZ_stats",
               "OME::Analysis::CLIHandler",
               "Statistics",
               null,
               null);
    public static Module.FormalOutput stackStats_min =
    stackStats.addOutput("Minima","Minima",stackMin,null);
    public static Module.FormalOutput stackStats_max =
    stackStats.addOutput("Maxima","Maxima",stackMax,null);
    public static Module.FormalOutput stackStats_mean =
    stackStats.addOutput("Means","Means",stackMean,null);
    public static Module.FormalOutput stackStats_geomean =
    stackStats.addOutput("Geomeans","Geomeans",stackGeomean,null);
    public static Module.FormalOutput stackStats_sigma =
    stackStats.addOutput("Sigmas","Sigmas",stackSigma,null);
    public static Module.FormalOutput stackStats_centroid =
    stackStats.addOutput("Centroids","Centroids",stackCentroid,null);

    // Plane statistics module

    public static Module  planeStats =
    new Module("Plane statistics",
               "Calculate pixel statitics per XY plane",
               "/OME/bin/OME_Image_XY_stats",
               "OME::Analysis::CLIHandler",
               "Statistics",
               null,
               null);
    public static Module.FormalOutput planeStats_min =
    planeStats.addOutput("Minima","Minima",planeMin,null);
    public static Module.FormalOutput planeStats_max =
    planeStats.addOutput("Maxima","Maxima",planeMax,null);
    public static Module.FormalOutput planeStats_mean =
    planeStats.addOutput("Means","Means",planeMean,null);
    public static Module.FormalOutput planeStats_geomean =
    planeStats.addOutput("Geomeans","Geomeans",planeGeomean,null);
    public static Module.FormalOutput planeStats_sigma =
    planeStats.addOutput("Sigmas","Sigmas",planeSigma,null);
    public static Module.FormalOutput planeStats_centroid =
    planeStats.addOutput("Centroids","Centroids",planeCentroid,null);

    // Find spots module

    public static Module  findSpots =
    new Module("Find spots",
               "Finds spots in the image",
               "/OME/bin/findSpotsOME",
               "OME::Analysis::FindSpotsHandler",
               "Segmentation",
               null,
               "SPOT");
    public static Module.FormalInput findSpots_min =
    findSpots.addInput("Stack minima","Stack minima",stackMin);
    public static Module.FormalInput findSpots_max =
    findSpots.addInput("Stack maxima","Stack maxima",stackMax);
    public static Module.FormalInput findSpots_mean =
    findSpots.addInput("Stack means","Stack means",stackMean);
    public static Module.FormalInput findSpots_geomean =
    findSpots.addInput("Stack geomeans","Stack geomeans",stackGeomean);
    public static Module.FormalInput findSpots_sigma =
    findSpots.addInput("Stack sigmas","Stack sigmas",stackSigma);
    public static Module.FormalOutput findSpots_location =
    findSpots.addOutput("Locations","Locations",location5,"[Feature]");
 
    // Image import chain

    public static Chain  imageImportChain = 
    new Chain("Douglas Creager","Image import chain",true);
    public static Chain.Node  imageImport_stackStats =
    imageImportChain.addNode(stackStats,null,null);
    public static Chain.Node  imageImport_planeStats =
    imageImportChain.addNode(planeStats,null,null);
 
    // Find spots chain

    public static Chain  findSpotsChain = 
    new Chain("Douglas Creager","Image import chain",true);
    public static Chain.Node  findSpots_stackStats =
    findSpotsChain.addNode(stackStats,null,null);
    public static Chain.Node  findSpots_findSpots =
    findSpotsChain.addNode(findSpots,null,"SPOT");
    public static Chain.Link  findSpots_link1 =
    findSpotsChain.addLink(findSpots_stackStats, stackStats_min,
                           findSpots_findSpots,  findSpots_min);
    public static Chain.Link  findSpots_link2 =
    findSpotsChain.addLink(findSpots_stackStats, stackStats_max,
                           findSpots_findSpots,  findSpots_max);
    public static Chain.Link  findSpots_link3 =
    findSpotsChain.addLink(findSpots_stackStats, stackStats_mean,
                           findSpots_findSpots,  findSpots_mean);
    public static Chain.Link  findSpots_link4 =
    findSpotsChain.addLink(findSpots_stackStats, stackStats_geomean,
                           findSpots_findSpots,  findSpots_geomean);
    public static Chain.Link  findSpots_link5 =
    findSpotsChain.addLink(findSpots_stackStats, stackStats_sigma,
                           findSpots_findSpots,  findSpots_sigma);

    // No-links find spots chain

    public static Chain  testFindSpotsChain = 
    new Chain("Douglas Creager","Image import chain",true);
    public static Chain.Node  testFindSpots_stackStats =
    testFindSpotsChain.addNode(stackStats,null,null);
    public static Chain.Node  testFindSpots_findSpots =
    testFindSpotsChain.addNode(findSpots,null,"SPOT");
}
