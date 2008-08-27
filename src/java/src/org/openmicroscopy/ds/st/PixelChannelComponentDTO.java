/*
 * org.openmicroscopy.ds.st.PixelChannelComponentDTO
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
 * Created by hochheiserha via omejava on Mon May  2 15:12:24 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.LogicalChannel;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class PixelChannelComponentDTO
    extends AttributeDTO
    implements PixelChannelComponent
{
    public PixelChannelComponentDTO() { super(); }
    public PixelChannelComponentDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@PixelChannelComponent"; }
    public Class getDTOType() { return PixelChannelComponent.class; }

    public LogicalChannel getLogicalChannel()
    { return (LogicalChannel) parseChildElement("LogicalChannel",LogicalChannelDTO.class); }
    public void setLogicalChannel(LogicalChannel value)
    { setElement("LogicalChannel",value); }

    public String getColorDomain()
    { return getStringElement("ColorDomain"); }
    public void setColorDomain(String value)
    { setElement("ColorDomain",value); }

    public Integer getIndex()
    { return getIntegerElement("Index"); }
    public void setIndex(Integer value)
    { setElement("Index",value); }

    public Pixels getPixels()
    { return (Pixels) parseChildElement("Pixels",PixelsDTO.class); }
    public void setPixels(Pixels value)
    { setElement("Pixels",value); }


}
