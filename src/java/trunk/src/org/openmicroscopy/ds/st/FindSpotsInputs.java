/*
 * org.openmicroscopy.ds.st.FindSpotsInputs
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
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface FindSpotsInputs
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>TimeStart</code> */
    public int getTimeStart();
    public void setTimeStart(int value);

    /** Criteria field name: <code>TimeStop</code> */
    public int getTimeStop();
    public void setTimeStop(int value);

    /** Criteria field name: <code>Channel</code> */
    public int getChannel();
    public void setChannel(int value);

    /** Criteria field name: <code>MinimumSpotVolume</code> */
    public float getMinimumSpotVolume();
    public void setMinimumSpotVolume(float value);

    /** Criteria field name: <code>ThresholdType</code> */
    public String getThresholdType();
    public void setThresholdType(String value);

    /** Criteria field name: <code>ThresholdValue</code> */
    public float getThresholdValue();
    public void setThresholdValue(float value);

}
