/*
 * org.openmicroscopy.ds.st.ExtentDTO
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
 * Created by hochheiserha via omejava on Mon May  2 15:12:25 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ExtentDTO
    extends AttributeDTO
    implements Extent
{
    public ExtentDTO() { super(); }
    public ExtentDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Extent"; }
    public Class getDTOType() { return Extent.class; }

    public Float getFormFactor()
    { return getFloatElement("FormFactor"); }
    public void setFormFactor(Float value)
    { setElement("FormFactor",value); }

    public Float getPerimeter()
    { return getFloatElement("Perimeter"); }
    public void setPerimeter(Float value)
    { setElement("Perimeter",value); }

    public Float getSurfaceArea()
    { return getFloatElement("SurfaceArea"); }
    public void setSurfaceArea(Float value)
    { setElement("SurfaceArea",value); }

    public Integer getVolume()
    { return getIntegerElement("Volume"); }
    public void setVolume(Integer value)
    { setElement("Volume",value); }

    public Integer getSigmaZ()
    { return getIntegerElement("SigmaZ"); }
    public void setSigmaZ(Integer value)
    { setElement("SigmaZ",value); }

    public Integer getSigmaY()
    { return getIntegerElement("SigmaY"); }
    public void setSigmaY(Integer value)
    { setElement("SigmaY",value); }

    public Integer getSigmaX()
    { return getIntegerElement("SigmaX"); }
    public void setSigmaX(Integer value)
    { setElement("SigmaX",value); }

    public Integer getMaxZ()
    { return getIntegerElement("MaxZ"); }
    public void setMaxZ(Integer value)
    { setElement("MaxZ",value); }

    public Integer getMaxY()
    { return getIntegerElement("MaxY"); }
    public void setMaxY(Integer value)
    { setElement("MaxY",value); }

    public Integer getMaxX()
    { return getIntegerElement("MaxX"); }
    public void setMaxX(Integer value)
    { setElement("MaxX",value); }

    public Integer getMinZ()
    { return getIntegerElement("MinZ"); }
    public void setMinZ(Integer value)
    { setElement("MinZ",value); }

    public Integer getMinY()
    { return getIntegerElement("MinY"); }
    public void setMinY(Integer value)
    { setElement("MinY",value); }

    public Integer getMinX()
    { return getIntegerElement("MinX"); }
    public void setMinX(Integer value)
    { setElement("MinX",value); }


}
