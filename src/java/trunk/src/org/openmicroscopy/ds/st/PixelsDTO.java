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
 * Created by dcreager via omejava on Mon Aug 23 11:24:39 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
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

    public String getDTOTypeName() { return "@Pixels"; }
    public Class getDTOType() { return Pixels.class; }

    public Integer getSizeX()
    { return getIntegerElement("SizeX"); }
    public void setSizeX(Integer value)
    { setElement("SizeX",value); }

    public Integer getSizeY()
    { return getIntegerElement("SizeY"); }
    public void setSizeY(Integer value)
    { setElement("SizeY",value); }

    public Integer getSizeZ()
    { return getIntegerElement("SizeZ"); }
    public void setSizeZ(Integer value)
    { setElement("SizeZ",value); }

    public Integer getSizeC()
    { return getIntegerElement("SizeC"); }
    public void setSizeC(Integer value)
    { setElement("SizeC",value); }

    public Integer getSizeT()
    { return getIntegerElement("SizeT"); }
    public void setSizeT(Integer value)
    { setElement("SizeT",value); }

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

    public Long getImageServerID()
    { return getLongElement("ImageServerID"); }
    public void setImageServerID(Long value)
    { setElement("ImageServerID",value); }

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
        parseListElement("DisplayOptionses",DisplayOptionsDTO.class);
        parseListElement("PixelChannelComponents",PixelChannelComponentDTO.class);
    }

}
