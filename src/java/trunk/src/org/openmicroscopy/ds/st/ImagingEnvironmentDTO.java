/*
 * org.openmicroscopy.ds.st.ImagingEnvironmentDTO
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
 * Created by hochheiserha via omejava on Mon May  2 15:12:24 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ImagingEnvironmentDTO
    extends AttributeDTO
    implements ImagingEnvironment
{
    public ImagingEnvironmentDTO() { super(); }
    public ImagingEnvironmentDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@ImagingEnvironment"; }
    public Class getDTOType() { return ImagingEnvironment.class; }

    public Float getCO2Percent()
    { return getFloatElement("CO2Percent"); }
    public void setCO2Percent(Float value)
    { setElement("CO2Percent",value); }

    public Float getHumidity()
    { return getFloatElement("Humidity"); }
    public void setHumidity(Float value)
    { setElement("Humidity",value); }

    public Float getAirPressure()
    { return getFloatElement("AirPressure"); }
    public void setAirPressure(Float value)
    { setElement("AirPressure",value); }

    public Float getTemperature()
    { return getFloatElement("Temperature"); }
    public void setTemperature(Float value)
    { setElement("Temperature",value); }


}
