/*
 * org.openmicroscopy.ds.st.TrajectoryEntryDTO
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
import org.openmicroscopy.ds.st.Trajectory;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class TrajectoryEntryDTO
    extends AttributeDTO
    implements TrajectoryEntry
{
    public TrajectoryEntryDTO() { super(); }
    public TrajectoryEntryDTO(Map elements) { super(elements); }

    public Trajectory getTrajectory()
    { return (Trajectory) getObjectElement("Trajectory"); }
    public void setTrajectory(Trajectory value)
    { setElement("Trajectory",value); }

    public int getOrder()
    { return getIntElement("Order"); }
    public void setOrder(int value)
    { setElement("Order",new Integer(value)); }

    public float getDeltaX()
    { return getFloatElement("DeltaX"); }
    public void setDeltaX(float value)
    { setElement("DeltaX",new Float(value)); }

    public float getDeltaY()
    { return getFloatElement("DeltaY"); }
    public void setDeltaY(float value)
    { setElement("DeltaY",new Float(value)); }

    public float getDeltaZ()
    { return getFloatElement("DeltaZ"); }
    public void setDeltaZ(float value)
    { setElement("DeltaZ",new Float(value)); }

    public float getDistance()
    { return getFloatElement("Distance"); }
    public void setDistance(float value)
    { setElement("Distance",new Float(value)); }

    public float getVelocity()
    { return getFloatElement("Velocity"); }
    public void setVelocity(float value)
    { setElement("Velocity",new Float(value)); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Trajectory",TrajectoryDTO.class);
    }

}
