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

import org.openmicroscopy.*;
import org.openmicroscopy.simple.*;

public class TestInstances
{
    // XYZ_IMAGE_INFO data table

    public static DataTable  xyzImageInfo =
    new SimpleDataTable(1,"XYZ_IMAGE_INFO",
                        "General image XYZ stack attributes.  Produced from XML.",
                        Granularity.IMAGE);

    public static DataTable.Column  xyzImageInfo_theW =
    xyzImageInfo.addColumn(1,"THE_W","Wavelength","integer");
    public static DataTable.Column  xyzImageInfo_theT =
    xyzImageInfo.addColumn(2,"THE_T","Timepoint","integer");
    public static DataTable.Column  xyzImageInfo_min =
    xyzImageInfo.addColumn(3,"MINIMUM","Minimum","integer");
    public static DataTable.Column  xyzImageInfo_max =
    xyzImageInfo.addColumn(4,"MAXIMUM","Maximum","integer");
    public static DataTable.Column  xyzImageInfo_mean =
    xyzImageInfo.addColumn(5,"MEAN","Mean","integer");
    public static DataTable.Column  xyzImageInfo_geomean =
    xyzImageInfo.addColumn(6,"GEOMEAN","Geomean","integer");
    public static DataTable.Column  xyzImageInfo_sigma =
    xyzImageInfo.addColumn(7,"SIGMA","Sigma","integer");
    public static DataTable.Column  xyzImageInfo_centroidX =
    xyzImageInfo.addColumn(8,"CENTROID_X","Centroid X","integer");
    public static DataTable.Column  xyzImageInfo_centroidY =
    xyzImageInfo.addColumn(9,"CENTROID_Y","Centroid Y","integer");
    public static DataTable.Column  xyzImageInfo_centroidZ =
    xyzImageInfo.addColumn(10,"CENTROID_Z","Centroid Z","integer");

    // XYZ_IMAGE_INFO attribute types

    public static AttributeType  stackMin =
    new SimpleAttributeType(1,"Stack minimum",
                            "Minimum pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  stackMin_theW =
    stackMin.addColumn(1,"Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackMin_theT =
    stackMin.addColumn(2,"Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackMin_min =
    stackMin.addColumn(3,"Minimum","Minimum",xyzImageInfo_min);

    public static AttributeType  stackMax =
    new SimpleAttributeType(2,"Stack maximum",
                            "Maximum pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  stackMax_theW =
    stackMax.addColumn(4,"Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackMax_theT =
    stackMax.addColumn(5,"Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackMax_max =
    stackMax.addColumn(6,"Maximum","Maximum",xyzImageInfo_max);

    public static AttributeType  stackMean =
    new SimpleAttributeType(3,"Stack mean",
                            "Mean pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  stackMean_theW =
    stackMean.addColumn(7,"Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackMean_theT =
    stackMean.addColumn(8,"Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackMean_mean =
    stackMean.addColumn(9,"Mean","Mean",xyzImageInfo_mean);

    public static AttributeType  stackGeomean =
    new SimpleAttributeType(4,"Stack geomean",
                            "Geomean pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  stackGeomean_theW =
    stackGeomean.addColumn(10,"Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackGeomean_theT =
    stackGeomean.addColumn(11,"Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackGeomean_geomean =
    stackGeomean.addColumn(12,"Geomean","Geomean",xyzImageInfo_geomean);

    public static AttributeType  stackSigma =
    new SimpleAttributeType(5,"Stack sigma",
                            "Sigma pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  stackSigma_theW =
    stackSigma.addColumn(13,"Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackSigma_theT =
    stackSigma.addColumn(14,"Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackSigma_sigma =
    stackSigma.addColumn(15,"Sigma","Sigma",xyzImageInfo_sigma);

    public static AttributeType  stackCentroid =
    new SimpleAttributeType(6,"Stack centroid",
                            "Centroid pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  stackCentroid_theW =
    stackCentroid.addColumn(16,"Wavepoint","Wavepoint",xyzImageInfo_theW);
    public static AttributeType.Column  stackCentroid_theT =
    stackCentroid.addColumn(17,"Timepoint","Timepoint",xyzImageInfo_theT);
    public static AttributeType.Column  stackCentroid_centroidX =
    stackCentroid.addColumn(18,"Centroid_X","Centroid X",xyzImageInfo_centroidX);
    public static AttributeType.Column  stackCentroid_centroidY =
    stackCentroid.addColumn(19,"Centroid_Y","Centroid Y",xyzImageInfo_centroidY);
    public static AttributeType.Column  stackCentroid_centroidZ =
    stackCentroid.addColumn(20,"Centroid_Z","Centroid Z",xyzImageInfo_centroidZ);

    // XY_IMAGE_INFO data table

    public static DataTable  xyImageInfo =
    new SimpleDataTable(2,"XY_IMAGE_INFO",
                        "General image XY plane attributes.  Produced from XML.",
                        Granularity.IMAGE);

    public static DataTable.Column  xyImageInfo_theW =
    xyImageInfo.addColumn(11,"THE_W","Wavelength","integer");
    public static DataTable.Column  xyImageInfo_theT =
    xyImageInfo.addColumn(12,"THE_T","Timepoint","integer");
    public static DataTable.Column  xyImageInfo_theZ =
    xyImageInfo.addColumn(13,"THE_Z","Z-section","integer");
    public static DataTable.Column  xyImageInfo_min =
    xyImageInfo.addColumn(14,"MINIMUM","Minimum","integer");
    public static DataTable.Column  xyImageInfo_max =
    xyImageInfo.addColumn(15,"MAXIMUM","Maximum","integer");
    public static DataTable.Column  xyImageInfo_mean =
    xyImageInfo.addColumn(16,"MEAN","Mean","integer");
    public static DataTable.Column  xyImageInfo_geomean =
    xyImageInfo.addColumn(17,"GEOMEAN","Geomean","integer");
    public static DataTable.Column  xyImageInfo_sigma =
    xyImageInfo.addColumn(18,"SIGMA","Sigma","integer");
    public static DataTable.Column  xyImageInfo_centroidX =
    xyImageInfo.addColumn(19,"CENTROID_X","Centroid X","integer");
    public static DataTable.Column  xyImageInfo_centroidY =
    xyImageInfo.addColumn(20,"CENTROID_Y","Centroid Y","integer");

    // XY_IMAGE_INFO attribute types

    public static AttributeType  planeMin =
    new SimpleAttributeType(7,"Plane minimum",
                            "Minimum pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  planeMin_theW =
    planeMin.addColumn(21,"Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeMin_theT =
    planeMin.addColumn(22,"Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeMin_theZ =
    planeMin.addColumn(23,"Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeMin_min =
    planeMin.addColumn(24,"Minimum","Minimum",xyImageInfo_min);

    public static AttributeType  planeMax =
    new SimpleAttributeType(8,"Plane maximum",
                            "Maximum pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  planeMax_theW =
    planeMax.addColumn(25,"Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeMax_theT =
    planeMax.addColumn(26,"Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeMax_theZ =
    planeMax.addColumn(27,"Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeMax_max =
    planeMax.addColumn(28,"Maximum","Maximum",xyImageInfo_max);

    public static AttributeType  planeMean =
    new SimpleAttributeType(9,"Plane mean",
                            "Mean pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  planeMean_theW =
    planeMean.addColumn(29,"Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeMean_theT =
    planeMean.addColumn(30,"Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeMean_theZ =
    planeMean.addColumn(31,"Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeMean_mean =
    planeMean.addColumn(32,"Mean","Mean",xyImageInfo_mean);

    public static AttributeType  planeGeomean =
    new SimpleAttributeType(10,"Plane geomean",
                            "Geomean pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  planeGeomean_theW =
    planeGeomean.addColumn(33,"Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeGeomean_theT =
    planeGeomean.addColumn(34,"Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeGeomean_theZ =
    planeGeomean.addColumn(35,"Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeGeomean_geomean =
    planeGeomean.addColumn(36,"Geomean","Geomean",xyImageInfo_geomean);

    public static AttributeType  planeSigma =
    new SimpleAttributeType(11,"Plane sigma",
                            "Sigma pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  planeSigma_theW =
    planeSigma.addColumn(37,"Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeSigma_theT =
    planeSigma.addColumn(38,"Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeSigma_theZ =
    planeSigma.addColumn(39,"Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeSigma_sigma =
    planeSigma.addColumn(40,"Sigma","Sigma",xyImageInfo_sigma);

    public static AttributeType  planeCentroid =
    new SimpleAttributeType(12,"Plane centroid",
                            "Centroid pixel intensity",
                            Granularity.IMAGE);
    public static AttributeType.Column  planeCentroid_theW =
    planeCentroid.addColumn(41,"Wavepoint","Wavepoint",xyImageInfo_theW);
    public static AttributeType.Column  planeCentroid_theT =
    planeCentroid.addColumn(42,"Timepoint","Timepoint",xyImageInfo_theT);
    public static AttributeType.Column  planeCentroid_theZ =
    planeCentroid.addColumn(43,"Z","Z-section",xyImageInfo_theT);
    public static AttributeType.Column  planeCentroid_centroidX =
    planeCentroid.addColumn(44,"Centroid_X","Centroid X",xyImageInfo_centroidX);
    public static AttributeType.Column  planeCentroid_centroidY =
    planeCentroid.addColumn(45,"Centroid_Y","Centroid Y",xyImageInfo_centroidY);

    // LOCATION_5 data table

    public static DataTable  location5table =
    new SimpleDataTable(3,"LOCATION_5",
                        "5D coordinate",
                        Granularity.FEATURE);

    public static DataTable.Column  location5table_X =
    location5table.addColumn(21,"X","X coordinate","float");
    public static DataTable.Column  location5table_Y =
    location5table.addColumn(22,"Y","Y coordinate","float");
    public static DataTable.Column  location5table_Z =
    location5table.addColumn(23,"Z","Z coordinate","float");
    public static DataTable.Column  location5table_W =
    location5table.addColumn(24,"W","W coordinate","float");
    public static DataTable.Column  location5table_T =
    location5table.addColumn(25,"T","T coordinate","float");

    // LOCATION_5 attributes

    public static AttributeType  location5 =
    new SimpleAttributeType(13,"5D location","5D location",Granularity.FEATURE);
    public static AttributeType.Column  location5_X =
    location5.addColumn(46,"X","X",location5table_X);
    public static AttributeType.Column  location5_Y =
    location5.addColumn(47,"Y","Y",location5table_Y);
    public static AttributeType.Column  location5_Z =
    location5.addColumn(48,"Z","Z",location5table_Z);
    public static AttributeType.Column  location5_W =
    location5.addColumn(49,"W","W",location5table_W);
    public static AttributeType.Column  location5_T =
    location5.addColumn(50,"T","T",location5table_T);

    // Stack statistics module

    public static Module  stackStats =
    new SimpleModule(1,"Stack statistics",
                     "Calculate pixel statitics per XYZ stack",
                     "/OME/bin/OME_Image_XYZ_stats",
                     "OME::Analysis::CLIHandler",
                     "Statistics",
                     null,
                     null);
    public static Module.FormalOutput stackStats_min =
    stackStats.addOutput(1,"Minima","Minima",stackMin,null);
    public static Module.FormalOutput stackStats_max =
    stackStats.addOutput(2,"Maxima","Maxima",stackMax,null);
    public static Module.FormalOutput stackStats_mean =
    stackStats.addOutput(3,"Means","Means",stackMean,null);
    public static Module.FormalOutput stackStats_geomean =
    stackStats.addOutput(4,"Geomeans","Geomeans",stackGeomean,null);
    public static Module.FormalOutput stackStats_sigma =
    stackStats.addOutput(5,"Sigmas","Sigmas",stackSigma,null);
    public static Module.FormalOutput stackStats_centroid =
    stackStats.addOutput(6,"Centroids","Centroids",stackCentroid,null);

    // Plane statistics module

    public static Module  planeStats =
    new SimpleModule(2,"Plane statistics",
                     "Calculate pixel statitics per XY plane",
                     "/OME/bin/OME_Image_XY_stats",
                     "OME::Analysis::CLIHandler",
                     "Statistics",
                     null,
                     null);
    public static Module.FormalOutput planeStats_min =
    planeStats.addOutput(7,"Minima","Minima",planeMin,null);
    public static Module.FormalOutput planeStats_max =
    planeStats.addOutput(8,"Maxima","Maxima",planeMax,null);
    public static Module.FormalOutput planeStats_mean =
    planeStats.addOutput(9,"Means","Means",planeMean,null);
    public static Module.FormalOutput planeStats_geomean =
    planeStats.addOutput(10,"Geomeans","Geomeans",planeGeomean,null);
    public static Module.FormalOutput planeStats_sigma =
    planeStats.addOutput(11,"Sigmas","Sigmas",planeSigma,null);
    public static Module.FormalOutput planeStats_centroid =
    planeStats.addOutput(12,"Centroids","Centroids",planeCentroid,null);

    // Find spots module

    public static Module  findSpots =
    new SimpleModule(3,"Find spots",
                     "Finds spots in the image",
                     "/OME/bin/findSpotsOME",
                     "OME::Analysis::FindSpotsHandler",
                     "Segmentation",
                     null,
                     "SPOT");
    public static Module.FormalInput findSpots_min =
    findSpots.addInput(1,"Stack minima","Stack minima",stackMin);
    public static Module.FormalInput findSpots_max =
    findSpots.addInput(2,"Stack maxima","Stack maxima",stackMax);
    public static Module.FormalInput findSpots_mean =
    findSpots.addInput(3,"Stack means","Stack means",stackMean);
    public static Module.FormalInput findSpots_geomean =
    findSpots.addInput(4,"Stack geomeans","Stack geomeans",stackGeomean);
    public static Module.FormalInput findSpots_sigma =
    findSpots.addInput(5,"Stack sigmas","Stack sigmas",stackSigma);
    public static Module.FormalOutput findSpots_location =
    findSpots.addOutput(13,"Locations","Locations",location5,"[Feature]");
 
    // Image import chain

    public static Chain  imageImportChain = 
    new SimpleChain(1,"Douglas Creager","Image import chain",true);
    public static Chain.Node  imageImport_stackStats =
    imageImportChain.addNode(1,stackStats,null,null);
    public static Chain.Node  imageImport_planeStats =
    imageImportChain.addNode(2,planeStats,null,null);
 
    // Find spots chain

    public static Chain  findSpotsChain = 
    new SimpleChain(2,"Douglas Creager","Image import chain",true);
    public static Chain.Node  findSpots_stackStats =
    findSpotsChain.addNode(3,stackStats,null,null);
    public static Chain.Node  findSpots_findSpots =
    findSpotsChain.addNode(4,findSpots,null,"SPOT");
    public static Chain.Link  findSpots_link1 =
    findSpotsChain.addLink(1,findSpots_stackStats, stackStats_min,
                           findSpots_findSpots,  findSpots_min);
    public static Chain.Link  findSpots_link2 =
    findSpotsChain.addLink(2,findSpots_stackStats, stackStats_max,
                           findSpots_findSpots,  findSpots_max);
    public static Chain.Link  findSpots_link3 =
    findSpotsChain.addLink(3,findSpots_stackStats, stackStats_mean,
                           findSpots_findSpots,  findSpots_mean);
    public static Chain.Link  findSpots_link4 =
    findSpotsChain.addLink(4,findSpots_stackStats, stackStats_geomean,
                           findSpots_findSpots,  findSpots_geomean);
    public static Chain.Link  findSpots_link5 =
    findSpotsChain.addLink(5,findSpots_stackStats, stackStats_sigma,
                           findSpots_findSpots,  findSpots_sigma);

    // No-links find spots chain

    public static Chain  testFindSpotsChain = 
    new SimpleChain(3,"Douglas Creager","Image import chain",true);
    public static Chain.Node  testFindSpots_stackStats =
    testFindSpotsChain.addNode(5,stackStats,null,null);
    public static Chain.Node  testFindSpots_findSpots =
    testFindSpotsChain.addNode(6,findSpots,null,"SPOT");
}
