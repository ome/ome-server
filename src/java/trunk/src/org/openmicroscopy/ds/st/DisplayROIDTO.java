/*
 * org.openmicroscopy.ds.st.DisplayROIDTO
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
import org.openmicroscopy.ds.st.DisplayOptions;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class DisplayROIDTO
    extends AttributeDTO
    implements DisplayROI
{
    public DisplayROIDTO() { super(); }
    public DisplayROIDTO(Map elements) { super(elements); }

    public int getX0()
    { return getIntElement("X0"); }
    public void setX0(int value)
    { setElement("X0",new Integer(value)); }

    public int getY0()
    { return getIntElement("Y0"); }
    public void setY0(int value)
    { setElement("Y0",new Integer(value)); }

    public int getZ0()
    { return getIntElement("Z0"); }
    public void setZ0(int value)
    { setElement("Z0",new Integer(value)); }

    public int getX1()
    { return getIntElement("X1"); }
    public void setX1(int value)
    { setElement("X1",new Integer(value)); }

    public int getY1()
    { return getIntElement("Y1"); }
    public void setY1(int value)
    { setElement("Y1",new Integer(value)); }

    public int getZ1()
    { return getIntElement("Z1"); }
    public void setZ1(int value)
    { setElement("Z1",new Integer(value)); }

    public int getT0()
    { return getIntElement("T0"); }
    public void setT0(int value)
    { setElement("T0",new Integer(value)); }

    public int getT1()
    { return getIntElement("T1"); }
    public void setT1(int value)
    { setElement("T1",new Integer(value)); }

    public DisplayOptions getDisplayOptions()
    { return (DisplayOptions) getObjectElement("DisplayOptions"); }
    public void setDisplayOptions(DisplayOptions value)
    { setElement("DisplayOptions",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("DisplayOptions",DisplayOptionsDTO.class);
    }

}
