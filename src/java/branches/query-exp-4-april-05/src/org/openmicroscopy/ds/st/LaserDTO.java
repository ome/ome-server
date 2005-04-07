/*
 * org.openmicroscopy.ds.st.LaserDTO
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:03 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.LightSource;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class LaserDTO
    extends AttributeDTO
    implements Laser
{
    public LaserDTO() { super(); }
    public LaserDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Laser"; }
    public Class getDTOType() { return Laser.class; }

    public Integer getWavelength()
    { return getIntegerElement("Wavelength"); }
    public void setWavelength(Integer value)
    { setElement("Wavelength",value); }

    public String getType()
    { return getStringElement("Type"); }
    public void setType(String value)
    { setElement("Type",value); }

    public String getMedium()
    { return getStringElement("Medium"); }
    public void setMedium(String value)
    { setElement("Medium",value); }

    public Boolean isFrequencyDoubled()
    { return getBooleanElement("FrequencyDoubled"); }
    public void setFrequencyDoubled(Boolean value)
    { setElement("FrequencyDoubled",value); }

    public Boolean isTunable()
    { return getBooleanElement("Tunable"); }
    public void setTunable(Boolean value)
    { setElement("Tunable",value); }

    public String getPulse()
    { return getStringElement("Pulse"); }
    public void setPulse(String value)
    { setElement("Pulse",value); }

    public Float getPower()
    { return getFloatElement("Power"); }
    public void setPower(Float value)
    { setElement("Power",value); }

    public LightSource getLightSource()
    { return (LightSource) parseChildElement("LightSource",LightSourceDTO.class); }
    public void setLightSource(LightSource value)
    { setElement("LightSource",value); }

    public LightSource getPump()
    { return (LightSource) parseChildElement("Pump",LightSourceDTO.class); }
    public void setPump(LightSource value)
    { setElement("Pump",value); }


}
