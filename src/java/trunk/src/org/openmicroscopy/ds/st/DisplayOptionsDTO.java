/*
 * org.openmicroscopy.ds.st.DisplayOptionsDTO
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
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
 *------------------------------------------------------------------------------
 */

/*------------------------------------------------------------------------------
 *
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by dcreager via omejava on Wed Feb 18 17:57:29 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.DisplayChannel;
import org.openmicroscopy.ds.st.DisplayROI;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class DisplayOptionsDTO
    extends AttributeDTO
    implements DisplayOptions
{
    public DisplayOptionsDTO() { super(); }
    public DisplayOptionsDTO(Map elements) { super(elements); }

    public Pixels getPixels()
    { return (Pixels) getObjectElement("Pixels"); }
    public void setPixels(Pixels value)
    { setElement("Pixels",value); }

    public Float getZoom()
    { return getFloatElement("Zoom"); }
    public void setZoom(Float value)
    { setElement("Zoom",value); }

    public DisplayChannel getRedChannel()
    { return (DisplayChannel) getObjectElement("RedChannel"); }
    public void setRedChannel(DisplayChannel value)
    { setElement("RedChannel",value); }

    public Boolean isRedChannelOn()
    { return getBooleanElement("RedChannelOn"); }
    public void setRedChannelOn(Boolean value)
    { setElement("RedChannelOn",value); }

    public DisplayChannel getGreenChannel()
    { return (DisplayChannel) getObjectElement("GreenChannel"); }
    public void setGreenChannel(DisplayChannel value)
    { setElement("GreenChannel",value); }

    public Boolean isGreenChannelOn()
    { return getBooleanElement("GreenChannelOn"); }
    public void setGreenChannelOn(Boolean value)
    { setElement("GreenChannelOn",value); }

    public DisplayChannel getBlueChannel()
    { return (DisplayChannel) getObjectElement("BlueChannel"); }
    public void setBlueChannel(DisplayChannel value)
    { setElement("BlueChannel",value); }

    public Boolean isBlueChannelOn()
    { return getBooleanElement("BlueChannelOn"); }
    public void setBlueChannelOn(Boolean value)
    { setElement("BlueChannelOn",value); }

    public Boolean isDisplayRGB()
    { return getBooleanElement("DisplayRGB"); }
    public void setDisplayRGB(Boolean value)
    { setElement("DisplayRGB",value); }

    public DisplayChannel getGreyChannel()
    { return (DisplayChannel) getObjectElement("GreyChannel"); }
    public void setGreyChannel(DisplayChannel value)
    { setElement("GreyChannel",value); }

    public String getColorMap()
    { return getStringElement("ColorMap"); }
    public void setColorMap(String value)
    { setElement("ColorMap",value); }

    public Integer getZStart()
    { return getIntegerElement("ZStart"); }
    public void setZStart(Integer value)
    { setElement("ZStart",value); }

    public Integer getZStop()
    { return getIntegerElement("ZStop"); }
    public void setZStop(Integer value)
    { setElement("ZStop",value); }

    public Integer getTStart()
    { return getIntegerElement("TStart"); }
    public void setTStart(Integer value)
    { setElement("TStart",value); }

    public Integer getTStop()
    { return getIntegerElement("TStop"); }
    public void setTStop(Integer value)
    { setElement("TStop",value); }

    public List getDisplayROIs()
    { return (List) getObjectElement("DisplayROIs"); }
    public int countDisplayROIs()
    { return countListElement("DisplayROIs"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Pixels",PixelsDTO.class);
        parseChildElement("RedChannel",DisplayChannelDTO.class);
        parseChildElement("GreenChannel",DisplayChannelDTO.class);
        parseChildElement("BlueChannel",DisplayChannelDTO.class);
        parseChildElement("GreyChannel",DisplayChannelDTO.class);
        parseListElement("DisplayROIs",DisplayROIDTO.class);
    }

}
