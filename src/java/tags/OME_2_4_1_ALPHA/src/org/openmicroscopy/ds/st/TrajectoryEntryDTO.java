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
 * Created by callan via omejava on Fri Dec 17 12:37:16 2004
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

    public String getDTOTypeName() { return "@TrajectoryEntry"; }
    public Class getDTOType() { return TrajectoryEntry.class; }

    public Float getVelocity()
    { return getFloatElement("Velocity"); }
    public void setVelocity(Float value)
    { setElement("Velocity",value); }

    public Float getDistance()
    { return getFloatElement("Distance"); }
    public void setDistance(Float value)
    { setElement("Distance",value); }

    public Float getDeltaZ()
    { return getFloatElement("DeltaZ"); }
    public void setDeltaZ(Float value)
    { setElement("DeltaZ",value); }

    public Float getDeltaY()
    { return getFloatElement("DeltaY"); }
    public void setDeltaY(Float value)
    { setElement("DeltaY",value); }

    public Float getDeltaX()
    { return getFloatElement("DeltaX"); }
    public void setDeltaX(Float value)
    { setElement("DeltaX",value); }

    public Integer getOrder()
    { return getIntegerElement("Order"); }
    public void setOrder(Integer value)
    { setElement("Order",value); }

    public Trajectory getTrajectory()
    { return (Trajectory) getObjectElement("Trajectory"); }
    public void setTrajectory(Trajectory value)
    { setElement("Trajectory",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Trajectory",TrajectoryDTO.class);
    }

}
