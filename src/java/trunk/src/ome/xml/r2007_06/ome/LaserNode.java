/*
 * ome.xml.r2007_06.ome.LaserNode
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

public class LaserNode extends OMEXMLNode
{
	// -- Constructor --
	
	public LaserNode(Element element)
	{
		super(element);
	}
	
	// -- Laser API methods --
          
	// Attribute
	public Boolean getPockelCell()
	{
		return getBooleanAttribute("PockelCell");
	}

	public void setPockelCell(Boolean pockelCell)
	{
		setAttribute("PockelCell", pockelCell);
	}
                                        
	// Attribute
	public Boolean getTuneable()
	{
		return getBooleanAttribute("Tuneable");
	}

	public void setTuneable(Boolean tuneable)
	{
		setAttribute("Tuneable", tuneable);
	}
                                        
	// Attribute
	public String getLaserMedium()
	{
		return getStringAttribute("LaserMedium");
	}

	public void setLaserMedium(String laserMedium)
	{
		setAttribute("LaserMedium", laserMedium);
	}
                                                            
	// Element which is complex (has sub-elements)
	public PumpNode getPump()
	{
		return (PumpNode) 
			getChildNode("Pump","Pump");
	}
                    
	// Attribute
	public String getPulse()
	{
		return getStringAttribute("Pulse");
	}

	public void setPulse(String pulse)
	{
		setAttribute("Pulse", pulse);
	}
                                        
	// Attribute
	public Integer getWavelength()
	{
		return getIntegerAttribute("Wavelength");
	}

	public void setWavelength(Integer wavelength)
	{
		setAttribute("Wavelength", wavelength);
	}
                                        
	// Attribute
	public Integer getFrequencyMultiplication()
	{
		return getIntegerAttribute("FrequencyMultiplication");
	}

	public void setFrequencyMultiplication(Integer frequencyMultiplication)
	{
		setAttribute("FrequencyMultiplication", frequencyMultiplication);
	}
                                        
	// Attribute
	public String getType()
	{
		return getStringAttribute("Type");
	}

	public void setType(String type)
	{
		setAttribute("Type", type);
	}
                                        
	// Attribute
	public Boolean getRepetitionRate()
	{
		return getBooleanAttribute("RepetitionRate");
	}

	public void setRepetitionRate(Boolean repetitionRate)
	{
		setAttribute("RepetitionRate", repetitionRate);
	}
                              
	// -- OMEXMLNode API methods --
	
	public boolean hasID()
	{
		return false;
	}
}
