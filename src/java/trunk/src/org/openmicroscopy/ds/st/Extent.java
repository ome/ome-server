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
 * Created by dcreager via omejava on Wed Feb 11 16:08:00 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import java.util.List;
import java.util.Map;

public interface Extent
    extends Attribute
{
    /** Criteria field name: <code>MinX</code> */
    public int getMinX();
    public void setMinX(int value);

    /** Criteria field name: <code>MinY</code> */
    public int getMinY();
    public void setMinY(int value);

    /** Criteria field name: <code>MinZ</code> */
    public int getMinZ();
    public void setMinZ(int value);

    /** Criteria field name: <code>MaxX</code> */
    public int getMaxX();
    public void setMaxX(int value);

    /** Criteria field name: <code>MaxY</code> */
    public int getMaxY();
    public void setMaxY(int value);

    /** Criteria field name: <code>MaxZ</code> */
    public int getMaxZ();
    public void setMaxZ(int value);

    /** Criteria field name: <code>SigmaX</code> */
    public int getSigmaX();
    public void setSigmaX(int value);

    /** Criteria field name: <code>SigmaY</code> */
    public int getSigmaY();
    public void setSigmaY(int value);

    /** Criteria field name: <code>SigmaZ</code> */
    public int getSigmaZ();
    public void setSigmaZ(int value);

    /** Criteria field name: <code>Volume</code> */
    public int getVolume();
    public void setVolume(int value);

    /** Criteria field name: <code>SurfaceArea</code> */
    public float getSurfaceArea();
    public void setSurfaceArea(float value);

    /** Criteria field name: <code>Perimeter</code> */
    public float getPerimeter();
    public void setPerimeter(float value);

    /** Criteria field name: <code>FormFactor</code> */
    public float getFormFactor();
    public void setFormFactor(float value);

}
