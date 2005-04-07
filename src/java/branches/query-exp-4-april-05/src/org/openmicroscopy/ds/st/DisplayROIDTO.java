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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:04 2005
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

    public String getDTOTypeName() { return "@DisplayROI"; }
    public Class getDTOType() { return DisplayROI.class; }

    public Integer getY0()
    { return getIntegerElement("Y0"); }
    public void setY0(Integer value)
    { setElement("Y0",value); }

    public Integer getX0()
    { return getIntegerElement("X0"); }
    public void setX0(Integer value)
    { setElement("X0",value); }

    public Integer getZ0()
    { return getIntegerElement("Z0"); }
    public void setZ0(Integer value)
    { setElement("Z0",value); }

    public Integer getX1()
    { return getIntegerElement("X1"); }
    public void setX1(Integer value)
    { setElement("X1",value); }

    public Integer getY1()
    { return getIntegerElement("Y1"); }
    public void setY1(Integer value)
    { setElement("Y1",value); }

    public Integer getZ1()
    { return getIntegerElement("Z1"); }
    public void setZ1(Integer value)
    { setElement("Z1",value); }

    public Integer getT0()
    { return getIntegerElement("T0"); }
    public void setT0(Integer value)
    { setElement("T0",value); }

    public Integer getT1()
    { return getIntegerElement("T1"); }
    public void setT1(Integer value)
    { setElement("T1",value); }

    public DisplayOptions getDisplayOptions()
    { return (DisplayOptions) parseChildElement("DisplayOptions",DisplayOptionsDTO.class); }
    public void setDisplayOptions(DisplayOptions value)
    { setElement("DisplayOptions",value); }


}
