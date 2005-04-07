/*
 * org.openmicroscopy.ds.st.DimensionsDTO
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
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class DimensionsDTO
    extends AttributeDTO
    implements Dimensions
{
    public DimensionsDTO() { super(); }
    public DimensionsDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Dimensions"; }
    public Class getDTOType() { return Dimensions.class; }

    public Float getPixelSizeY()
    { return getFloatElement("PixelSizeY"); }
    public void setPixelSizeY(Float value)
    { setElement("PixelSizeY",value); }

    public Float getPixelSizeX()
    { return getFloatElement("PixelSizeX"); }
    public void setPixelSizeX(Float value)
    { setElement("PixelSizeX",value); }

    public Float getPixelSizeZ()
    { return getFloatElement("PixelSizeZ"); }
    public void setPixelSizeZ(Float value)
    { setElement("PixelSizeZ",value); }

    public Float getPixelSizeC()
    { return getFloatElement("PixelSizeC"); }
    public void setPixelSizeC(Float value)
    { setElement("PixelSizeC",value); }

    public Float getPixelSizeT()
    { return getFloatElement("PixelSizeT"); }
    public void setPixelSizeT(Float value)
    { setElement("PixelSizeT",value); }


}
