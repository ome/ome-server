/*
 * org.openmicroscopy.ds.st.Laser
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
import org.openmicroscopy.ds.st.LightSource;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Laser
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Pump</code> */
    public LightSource getPump();
    public void setPump(LightSource value);

    /** Criteria field name: <code>LightSource</code> */
    public LightSource getLightSource();
    public void setLightSource(LightSource value);

    /** Criteria field name: <code>Power</code> */
    public Float getPower();
    public void setPower(Float value);

    /** Criteria field name: <code>Pulse</code> */
    public String getPulse();
    public void setPulse(String value);

    /** Criteria field name: <code>Tunable</code> */
    public Boolean isTunable();
    public void setTunable(Boolean value);

    /** Criteria field name: <code>FrequencyDoubled</code> */
    public Boolean isFrequencyDoubled();
    public void setFrequencyDoubled(Boolean value);

    /** Criteria field name: <code>Wavelength</code> */
    public Integer getWavelength();
    public void setWavelength(Integer value);

    /** Criteria field name: <code>Medium</code> */
    public String getMedium();
    public void setMedium(String value);

    /** Criteria field name: <code>Type</code> */
    public String getType();
    public void setType(String value);

}
