/*
 * org.openmicroscopy.ds.st.DisplayROI
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
import org.openmicroscopy.ds.st.DisplayOptions;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface DisplayROI
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>X0</code> */
    public Integer getX0();
    public void setX0(Integer value);

    /** Criteria field name: <code>Y0</code> */
    public Integer getY0();
    public void setY0(Integer value);

    /** Criteria field name: <code>Z0</code> */
    public Integer getZ0();
    public void setZ0(Integer value);

    /** Criteria field name: <code>X1</code> */
    public Integer getX1();
    public void setX1(Integer value);

    /** Criteria field name: <code>Y1</code> */
    public Integer getY1();
    public void setY1(Integer value);

    /** Criteria field name: <code>Z1</code> */
    public Integer getZ1();
    public void setZ1(Integer value);

    /** Criteria field name: <code>T0</code> */
    public Integer getT0();
    public void setT0(Integer value);

    /** Criteria field name: <code>T1</code> */
    public Integer getT1();
    public void setT1(Integer value);

    /** Criteria field name: <code>DisplayOptions</code> */
    public DisplayOptions getDisplayOptions();
    public void setDisplayOptions(DisplayOptions value);

}