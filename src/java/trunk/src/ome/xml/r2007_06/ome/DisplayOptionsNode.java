/*
 * ome.xml.r2007_06.ome.DisplayOptionsNode
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

public class DisplayOptionsNode extends OMEXMLNode
{
	// -- Constructor --
	
	public DisplayOptionsNode(Element element)
	{
		super(element);
	}
	
	// -- DisplayOptions API methods --
                  
	// Element which occurs more than once
	public int getROICount()
	{
		return getChildCount("ROI");
	}

	public Vector getROIList()
	{
		return getChildNodes("ROI");
	}
                                                    
	// Element which is complex (has sub-elements)
	public ChannelSpecTypeNode getGreenChannel()
	{
		return (ChannelSpecTypeNode) 
			getChildNode("ChannelSpecType","GreenChannel");
	}
                                        
	// Element which is complex (has sub-elements)
	public ProjectionNode getProjection()
	{
		return (ProjectionNode) 
			getChildNode("Projection","Projection");
	}
                    
	// Attribute
	public Float getZoom()
	{
		return getFloatAttribute("Zoom");
	}

	public void setZoom(Float zoom)
	{
		setAttribute("Zoom", zoom);
	}
                                                            
	// Element which is complex (has sub-elements)
	public ChannelSpecTypeNode getBlueChannel()
	{
		return (ChannelSpecTypeNode) 
			getChildNode("ChannelSpecType","BlueChannel");
	}
                    
	// Attribute
	public String getDisplay()
	{
		return getStringAttribute("Display");
	}

	public void setDisplay(String display)
	{
		setAttribute("Display", display);
	}
                                                            
	// Element which is complex (has sub-elements)
	public TimeNode getTime()
	{
		return (TimeNode) 
			getChildNode("Time","Time");
	}
                                        
	// Element which is complex (has sub-elements)
	public ChannelSpecTypeNode getRedChannel()
	{
		return (ChannelSpecTypeNode) 
			getChildNode("ChannelSpecType","RedChannel");
	}
                                        
	// Element which is complex (has sub-elements)
	public GreyChannelNode getGreyChannel()
	{
		return (GreyChannelNode) 
			getChildNode("GreyChannel","GreyChannel");
	}
                                            
	// *** WARNING *** Unhandled or skipped property ID
      
	// -- OMEXMLNode API methods --
	
	public boolean hasID()
	{
		return true;
	}
}
