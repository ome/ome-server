/*
 * org.openmicroscopy.ds.st.PlaneCentroid
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
 * Created by dcreager via omejava on Tue Feb 24 17:23:15 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface PlaneCentroid
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>TheZ</code> */
    public Integer getTheZ();
    public void setTheZ(Integer value);

    /** Criteria field name: <code>TheC</code> */
    public Integer getTheC();
    public void setTheC(Integer value);

    /** Criteria field name: <code>TheT</code> */
    public Integer getTheT();
    public void setTheT(Integer value);

    /** Criteria field name: <code>X</code> */
    public Float getX();
    public void setX(Float value);

    /** Criteria field name: <code>Y</code> */
    public Float getY();
    public void setY(Float value);

}
