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
 * Created by dcreager via omejava on Thu Feb 12 14:35:08 2004
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

    public int getTimeStart()
    { return getIntElement("TimeStart"); }
    public void setTimeStart(int value)
    { setElement("TimeStart",new Integer(value)); }

    public int getTimeStop()
    { return getIntElement("TimeStop"); }
    public void setTimeStop(int value)
    { setElement("TimeStop",new Integer(value)); }

    public int getChannel()
    { return getIntElement("Channel"); }
    public void setChannel(int value)
    { setElement("Channel",new Integer(value)); }

    public float getMinimumSpotVolume()
    { return getFloatElement("MinimumSpotVolume"); }
    public void setMinimumSpotVolume(float value)
    { setElement("MinimumSpotVolume",new Float(value)); }

    public String getThresholdType()
    { return getStringElement("ThresholdType"); }
    public void setThresholdType(String value)
    { setElement("ThresholdType",value); }

    public float getThresholdValue()
    { return getFloatElement("ThresholdValue"); }
    public void setThresholdValue(float value)
    { setElement("ThresholdValue",new Float(value)); }


}
