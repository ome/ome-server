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
 * Created by dcreager via omejava on Thu Feb 12 14:35:08 2004
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

    public int getMinX()
    { return getIntElement("MinX"); }
    public void setMinX(int value)
    { setElement("MinX",new Integer(value)); }

    public int getMinY()
    { return getIntElement("MinY"); }
    public void setMinY(int value)
    { setElement("MinY",new Integer(value)); }

    public int getMinZ()
    { return getIntElement("MinZ"); }
    public void setMinZ(int value)
    { setElement("MinZ",new Integer(value)); }

    public int getMaxX()
    { return getIntElement("MaxX"); }
    public void setMaxX(int value)
    { setElement("MaxX",new Integer(value)); }

    public int getMaxY()
    { return getIntElement("MaxY"); }
    public void setMaxY(int value)
    { setElement("MaxY",new Integer(value)); }

    public int getMaxZ()
    { return getIntElement("MaxZ"); }
    public void setMaxZ(int value)
    { setElement("MaxZ",new Integer(value)); }

    public int getSigmaX()
    { return getIntElement("SigmaX"); }
    public void setSigmaX(int value)
    { setElement("SigmaX",new Integer(value)); }

    public int getSigmaY()
    { return getIntElement("SigmaY"); }
    public void setSigmaY(int value)
    { setElement("SigmaY",new Integer(value)); }

    public int getSigmaZ()
    { return getIntElement("SigmaZ"); }
    public void setSigmaZ(int value)
    { setElement("SigmaZ",new Integer(value)); }

    public int getVolume()
    { return getIntElement("Volume"); }
    public void setVolume(int value)
    { setElement("Volume",new Integer(value)); }

    public float getSurfaceArea()
    { return getFloatElement("SurfaceArea"); }
    public void setSurfaceArea(float value)
    { setElement("SurfaceArea",new Float(value)); }

    public float getPerimeter()
    { return getFloatElement("Perimeter"); }
    public void setPerimeter(float value)
    { setElement("Perimeter",new Float(value)); }

    public float getFormFactor()
    { return getFloatElement("FormFactor"); }
    public void setFormFactor(float value)
    { setElement("FormFactor",new Float(value)); }


}
