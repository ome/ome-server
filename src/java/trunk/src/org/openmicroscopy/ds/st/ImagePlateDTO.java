/*
 * org.openmicroscopy.ds.st.ImagePlateDTO
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
import org.openmicroscopy.ds.st.Plate;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ImagePlateDTO
    extends AttributeDTO
    implements ImagePlate
{
    public ImagePlateDTO() { super(); }
    public ImagePlateDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@ImagePlate"; }
    public Class getDTOType() { return ImagePlate.class; }

    public String getWell()
    { return getStringElement("Well"); }
    public void setWell(String value)
    { setElement("Well",value); }

    public Integer getSample()
    { return getIntegerElement("Sample"); }
    public void setSample(Integer value)
    { setElement("Sample",value); }

    public Plate getPlate()
    { return (Plate) getObjectElement("Plate"); }
    public void setPlate(Plate value)
    { setElement("Plate",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Plate",PlateDTO.class);
    }

}
