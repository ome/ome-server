/*
 * org.openmicroscopy.ds.st.PlateDTO
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
 * Created by hochheiserha via omejava on Mon May  2 15:12:23 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.ImagePlate;
import org.openmicroscopy.ds.st.PlateScreen;
import org.openmicroscopy.ds.st.Screen;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class PlateDTO
    extends AttributeDTO
    implements Plate
{
    public PlateDTO() { super(); }
    public PlateDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Plate"; }
    public Class getDTOType() { return Plate.class; }

    public Screen getScreen()
    { return (Screen) parseChildElement("Screen",ScreenDTO.class); }
    public void setScreen(Screen value)
    { setElement("Screen",value); }

    public String getExternalReference()
    { return getStringElement("ExternalReference"); }
    public void setExternalReference(String value)
    { setElement("ExternalReference",value); }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public List getImagePlateList()
    { return (List) parseListElement("ImagePlateList",ImagePlateDTO.class); }
    public int countImagePlateList()
    { return countListElement("ImagePlateList"); }

    public List getPlateScreenList()
    { return (List) parseListElement("PlateScreenList",PlateScreenDTO.class); }
    public int countPlateScreenList()
    { return countListElement("PlateScreenList"); }


}
