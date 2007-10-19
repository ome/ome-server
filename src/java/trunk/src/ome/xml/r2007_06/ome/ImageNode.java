/*
 * ome.xml.r2007_06.ome.ImageNode
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
 * Created by callan via xsd-fu on 2007-10-08 14:37:54+0100
 *
 *-----------------------------------------------------------------------------
 */

package ome.xml.r2007_06.ome;

import java.util.Vector;
import ome.xml.OMEXMLNode;
import org.w3c.dom.Element;

public class ImageNode extends OMEXMLNode
{
	// -- Constructor --
	
	public ImageNode(Element element)
	{
		super(element);
	}
	
	// -- Image API methods --
                              
	// Element which is complex (has sub-elements)
	public ImagingEnvironmentNode getImagingEnvironment()
	{
		return (ImagingEnvironmentNode) 
			getChildNode("ImagingEnvironment","ImagingEnvironment");
	}
                                    
	// Element which is complex and is an OME XML "Ref"
	public ExperimenterNode getExperimenter()
	{
		return (ExperimenterNode) 
			getReferencedNode("Experimenter", "ExperimenterRef");
	}
                                        
	// Element which is complex and is an OME XML "Ref"
	public ObjectiveSettingsNode getObjectiveSettings()
	{
		return (ObjectiveSettingsNode) 
			getReferencedNode("ObjectiveSettings", "ObjectiveSettingsRef");
	}
                                    
	// Element which is not complex (has only a text node)
	public String getCustomAttributes()
	{
		return getStringCData("CustomAttributes");
	}
                                    
	// Element which occurs more than once
	public int getLogicalChannelCount()
	{
		return getChildCount("LogicalChannel");
	}

	public Vector getLogicalChannelList()
	{
		return getChildNodes("LogicalChannel");
	}
                                                    
	// Element which is complex (has sub-elements)
	public ThumbnailNode getThumbnail()
	{
		return (ThumbnailNode) 
			getChildNode("Thumbnail","Thumbnail");
	}
                            
	// Element which occurs more than once
	public int getROICount()
	{
		return getChildCount("ROI");
	}

	public Vector getROIList()
	{
		return getChildNodes("ROI");
	}
                                            
	// Element which is not complex (has only a text node)
	public String getDescription()
	{
		return getStringCData("Description");
	}
                                                
	// Element which is complex (has sub-elements)
	public StageLabelNode getStageLabel()
	{
		return (StageLabelNode) 
			getChildNode("StageLabel","StageLabel");
	}
                                    
	// Element which is complex and is an OME XML "Ref"
	public GroupNode getGroup()
	{
		return (GroupNode) 
			getReferencedNode("Group", "GroupRef");
	}
                                        
	// Element which is complex and is an OME XML "Ref"
	public InstrumentNode getInstrument()
	{
		return (InstrumentNode) 
			getReferencedNode("Instrument", "InstrumentRef");
	}
                                
	// Element which occurs more than once
	public int getPixelsCount()
	{
		return getChildCount("Pixels");
	}

	public Vector getPixelsList()
	{
		return getChildNodes("Pixels");
	}
                                
	// Attribute
	public String getName()
	{
		return getStringAttribute("Name");
	}

	public void setName(String name)
	{
		setAttribute("Name", name);
	}
                                                
	// Element which occurs more than once
	public int getRegionCount()
	{
		return getChildCount("Region");
	}

	public Vector getRegionList()
	{
		return getChildNodes("Region");
	}
                                                        
	// *** WARNING *** Unhandled or skipped property ID
                        
	// Element which occurs more than once
	public int getMicrobeamManipulationCount()
	{
		return getChildCount("MicrobeamManipulation");
	}

	public Vector getMicrobeamManipulationList()
	{
		return getChildNodes("MicrobeamManipulation");
	}
                                                
	// Element which is complex and is an OME XML "Ref"
	public ExperimentNode getExperiment()
	{
		return (ExperimentNode) 
			getReferencedNode("Experiment", "ExperimentRef");
	}
                    
	// Attribute which is an OME XML "ID"
	public PixelsNode getDefaultPixels()
	{
		return (PixelsNode) 
			getAttrReferencedNode("Pixels", "DefaultPixels");
	}
                                                
	// Element which occurs more than once and is an OME XML "Ref"
	public int getDatasetCount()
	{
		return getChildCount("DatasetRef");
	}

	public Vector getDatasetList()
	{
		return getReferencedNodes("Dataset", "DatasetRef");
	}
                                                    
	// Element which is complex and is an OME XML "Ref"
	public PixelsNode getAcquiredPixels()
	{
		return (PixelsNode) 
			getReferencedNode("AcquiredPixels", "AcquiredPixelsRef");
	}
                                    
	// Element which is not complex (has only a text node)
	public String getCreationDate()
	{
		return getStringCData("CreationDate");
	}
                                                
	// Element which is complex (has sub-elements)
	public DisplayOptionsNode getDisplayOptions()
	{
		return (DisplayOptionsNode) 
			getChildNode("DisplayOptions","DisplayOptions");
	}
          
	// -- OMEXMLNode API methods --
	
	public boolean hasID()
	{
		return true;
	}
}
