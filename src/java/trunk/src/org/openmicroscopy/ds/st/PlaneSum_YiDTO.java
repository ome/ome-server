/*
 * org.openmicroscopy.ds.st.PlaneSum_YiDTO
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
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class PlaneSum_YiDTO
    extends AttributeDTO
    implements PlaneSum_Yi
{
    public PlaneSum_YiDTO() { super(); }
    public PlaneSum_YiDTO(Map elements) { super(elements); }

    public int getTheZ()
    { return getIntElement("TheZ"); }
    public void setTheZ(int value)
    { setElement("TheZ",new Integer(value)); }

    public int getTheC()
    { return getIntElement("TheC"); }
    public void setTheC(int value)
    { setElement("TheC",new Integer(value)); }

    public int getTheT()
    { return getIntElement("TheT"); }
    public void setTheT(int value)
    { setElement("TheT",new Integer(value)); }

    public float getSum_Yi()
    { return getFloatElement("Sum_Yi"); }
    public void setSum_Yi(float value)
    { setElement("Sum_Yi",new Float(value)); }


}
