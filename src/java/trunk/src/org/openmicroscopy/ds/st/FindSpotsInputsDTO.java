/*
 * org.openmicroscopy.ds.st.FindSpotsInputsDTO
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
 * Created by curtis via omejava on Tue Apr 25 13:29:24 2006
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class FindSpotsInputsDTO
    extends AttributeDTO
    implements FindSpotsInputs
{
    public FindSpotsInputsDTO() { super(); }
    public FindSpotsInputsDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@FindSpotsInputs"; }
    public Class getDTOType() { return FindSpotsInputs.class; }

    public Integer getFadeSpotsTheT()
    { return getIntegerElement("FadeSpotsTheT"); }
    public void setFadeSpotsTheT(Integer value)
    { setElement("FadeSpotsTheT",value); }

    public Float getThresholdValue()
    { return getFloatElement("ThresholdValue"); }
    public void setThresholdValue(Float value)
    { setElement("ThresholdValue",value); }

    public String getThresholdType()
    { return getStringElement("ThresholdType"); }
    public void setThresholdType(String value)
    { setElement("ThresholdType",value); }

    public Float getMinimumSpotVolume()
    { return getFloatElement("MinimumSpotVolume"); }
    public void setMinimumSpotVolume(Float value)
    { setElement("MinimumSpotVolume",value); }

    public String getChannel()
    { return getStringElement("Channel"); }
    public void setChannel(String value)
    { setElement("Channel",value); }

    public Integer getTimeStop()
    { return getIntegerElement("TimeStop"); }
    public void setTimeStop(Integer value)
    { setElement("TimeStop",value); }

    public Integer getTimeStart()
    { return getIntegerElement("TimeStart"); }
    public void setTimeStart(Integer value)
    { setElement("TimeStart",value); }


}
