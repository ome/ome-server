/*
 * org.openmicroscopy.ds.st.StackCentroidDTO
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
 * Created by callan via omejava on Fri Dec 17 12:37:15 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class StackCentroidDTO
    extends AttributeDTO
    implements StackCentroid
{
    public StackCentroidDTO() { super(); }
    public StackCentroidDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@StackCentroid"; }
    public Class getDTOType() { return StackCentroid.class; }

    public Float getZ()
    { return getFloatElement("Z"); }
    public void setZ(Float value)
    { setElement("Z",value); }

    public Float getY()
    { return getFloatElement("Y"); }
    public void setY(Float value)
    { setElement("Y",value); }

    public Float getX()
    { return getFloatElement("X"); }
    public void setX(Float value)
    { setElement("X",value); }

    public Integer getTheT()
    { return getIntegerElement("TheT"); }
    public void setTheT(Integer value)
    { setElement("TheT",value); }

    public Integer getTheC()
    { return getIntegerElement("TheC"); }
    public void setTheC(Integer value)
    { setElement("TheC",value); }


}
