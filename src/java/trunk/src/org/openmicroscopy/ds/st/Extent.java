/*
 * org.openmicroscopy.ds.st.Extent
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
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Extent
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>FormFactor</code> */
    public Float getFormFactor();
    public void setFormFactor(Float value);

    /** Criteria field name: <code>Perimeter</code> */
    public Float getPerimeter();
    public void setPerimeter(Float value);

    /** Criteria field name: <code>SurfaceArea</code> */
    public Float getSurfaceArea();
    public void setSurfaceArea(Float value);

    /** Criteria field name: <code>Volume</code> */
    public Integer getVolume();
    public void setVolume(Integer value);

    /** Criteria field name: <code>SigmaZ</code> */
    public Integer getSigmaZ();
    public void setSigmaZ(Integer value);

    /** Criteria field name: <code>SigmaY</code> */
    public Integer getSigmaY();
    public void setSigmaY(Integer value);

    /** Criteria field name: <code>SigmaX</code> */
    public Integer getSigmaX();
    public void setSigmaX(Integer value);

    /** Criteria field name: <code>MaxZ</code> */
    public Integer getMaxZ();
    public void setMaxZ(Integer value);

    /** Criteria field name: <code>MaxY</code> */
    public Integer getMaxY();
    public void setMaxY(Integer value);

    /** Criteria field name: <code>MaxX</code> */
    public Integer getMaxX();
    public void setMaxX(Integer value);

    /** Criteria field name: <code>MinZ</code> */
    public Integer getMinZ();
    public void setMinZ(Integer value);

    /** Criteria field name: <code>MinY</code> */
    public Integer getMinY();
    public void setMinY(Integer value);

    /** Criteria field name: <code>MinX</code> */
    public Integer getMinX();
    public void setMinX(Integer value);

}
