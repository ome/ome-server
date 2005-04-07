/*
 * org.openmicroscopy.ds.st.TrajectoryEntry
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:06 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Trajectory;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface TrajectoryEntry
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Order</code> */
    public Integer getOrder();
    public void setOrder(Integer value);

    /** Criteria field name: <code>DeltaX</code> */
    public Float getDeltaX();
    public void setDeltaX(Float value);

    /** Criteria field name: <code>DeltaY</code> */
    public Float getDeltaY();
    public void setDeltaY(Float value);

    /** Criteria field name: <code>DeltaZ</code> */
    public Float getDeltaZ();
    public void setDeltaZ(Float value);

    /** Criteria field name: <code>Distance</code> */
    public Float getDistance();
    public void setDistance(Float value);

    /** Criteria field name: <code>Velocity</code> */
    public Float getVelocity();
    public void setVelocity(Float value);

    /** Criteria field name: <code>Trajectory</code> */
    public Trajectory getTrajectory();
    public void setTrajectory(Trajectory value);

}
