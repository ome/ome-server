/*
 * org.openmicroscopy.ds.st.DisplayChannel
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

public interface DisplayChannel
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>ChannelNumber</code> */
    public Integer getChannelNumber();
    public void setChannelNumber(Integer value);

    /** Criteria field name: <code>BlackLevel</code> */
    public Double getBlackLevel();
    public void setBlackLevel(Double value);

    /** Criteria field name: <code>WhiteLevel</code> */
    public Double getWhiteLevel();
    public void setWhiteLevel(Double value);

    /** Criteria field name: <code>Gamma</code> */
    public Float getGamma();
    public void setGamma(Float value);

    /** Criteria field name: <code>DisplayOptionsesByBlueChannel</code> */
    public List getDisplayOptionsesByBlueChannel();
    /** Criteria field name: <code>#DisplayOptionsesByBlueChannel</code> or <code>DisplayOptionsesByBlueChannel</code> */
    public int countDisplayOptionsesByBlueChannel();

    /** Criteria field name: <code>DisplayOptionsesByGreenChannel</code> */
    public List getDisplayOptionsesByGreenChannel();
    /** Criteria field name: <code>#DisplayOptionsesByGreenChannel</code> or <code>DisplayOptionsesByGreenChannel</code> */
    public int countDisplayOptionsesByGreenChannel();

    /** Criteria field name: <code>DisplayOptionsesByGreyChannel</code> */
    public List getDisplayOptionsesByGreyChannel();
    /** Criteria field name: <code>#DisplayOptionsesByGreyChannel</code> or <code>DisplayOptionsesByGreyChannel</code> */
    public int countDisplayOptionsesByGreyChannel();

    /** Criteria field name: <code>DisplayOptionsesByRedChannel</code> */
    public List getDisplayOptionsesByRedChannel();
    /** Criteria field name: <code>#DisplayOptionsesByRedChannel</code> or <code>DisplayOptionsesByRedChannel</code> */
    public int countDisplayOptionsesByRedChannel();

}
