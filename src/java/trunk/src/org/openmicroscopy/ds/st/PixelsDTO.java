/*
 * org.openmicroscopy.ds.st.PixelsDTO
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
 * Created by dcreager via omejava on Wed Feb 11 16:08:00 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.ChannelIndex;
import org.openmicroscopy.ds.st.DisplayOptions;
import org.openmicroscopy.ds.st.PixelChannelComponent;
import org.openmicroscopy.ds.st.Repository;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class PixelsDTO
    extends AttributeDTO
    implements Pixels
{
    public PixelsDTO() { super(); }
    public PixelsDTO(Map elements) { super(elements); }

    public int getSizeX()
    { return getIntElement("SizeX"); }
    public void setSizeX(int value)
    { setElement("SizeX",new Integer(value)); }

    public int getSizeY()
    { return getIntElement("SizeY"); }
    public void setSizeY(int value)
    { setElement("SizeY",new Integer(value)); }

    public int getSizeZ()
    { return getIntElement("SizeZ"); }
    public void setSizeZ(int value)
    { setElement("SizeZ",new Integer(value)); }

    public int getSizeC()
    { return getIntElement("SizeC"); }
    public void setSizeC(int value)
    { setElement("SizeC",new Integer(value)); }

    public int getSizeT()
    { return getIntElement("SizeT"); }
    public void setSizeT(int value)
    { setElement("SizeT",new Integer(value)); }

    public int getBitsPerPixel()
    { return getIntElement("BitsPerPixel"); }
    public void setBitsPerPixel(int value)
    { setElement("BitsPerPixel",new Integer(value)); }

    public String getPixelType()
    { return getStringElement("PixelType"); }
    public void setPixelType(String value)
    { setElement("PixelType",value); }

    public String getFileSHA1()
    { return getStringElement("FileSHA1"); }
    public void setFileSHA1(String value)
    { setElement("FileSHA1",value); }

    public Repository getRepository()
    { return (Repository) getObjectElement("Repository"); }
    public void setRepository(Repository value)
    { setElement("Repository",value); }

    public String getPath()
    { return getStringElement("Path"); }
    public void setPath(String value)
    { setElement("Path",value); }

    public int getPixelsID()
    { return getIntElement("PixelsID"); }
    public void setPixelsID(int value)
    { setElement("PixelsID",new Integer(value)); }

    public List getChannelIndexes()
    { return (List) getObjectElement("ChannelIndexes"); }
    public int countChannelIndexes()
    { return countListElement("ChannelIndexes"); }

    public List getDisplayOptionses()
    { return (List) getObjectElement("DisplayOptionses"); }
    public int countDisplayOptionses()
    { return countListElement("DisplayOptionses"); }

    public List getPixelChannelComponents()
    { return (List) getObjectElement("PixelChannelComponents"); }
    public int countPixelChannelComponents()
    { return countListElement("PixelChannelComponents"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Repository",RepositoryDTO.class);
        parseListElement("ChannelIndexes",ChannelIndexDTO.class);
        parseListElement("DisplayOptionses",DisplayOptionsDTO.class);
        parseListElement("PixelChannelComponents",PixelChannelComponentDTO.class);
    }

}
