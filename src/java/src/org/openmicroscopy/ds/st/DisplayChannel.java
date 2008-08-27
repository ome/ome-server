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
 * Created by hochheiserha via omejava on Mon May  2 15:12:24 2005
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
    /** Criteria field name: <code>Gamma</code> */
    public Float getGamma();
    public void setGamma(Float value);

    /** Criteria field name: <code>WhiteLevel</code> */
    public Double getWhiteLevel();
    public void setWhiteLevel(Double value);

    /** Criteria field name: <code>BlackLevel</code> */
    public Double getBlackLevel();
    public void setBlackLevel(Double value);

    /** Criteria field name: <code>ChannelNumber</code> */
    public Integer getChannelNumber();
    public void setChannelNumber(Integer value);

    /** Criteria field name: <code>DisplayOptionsListByBlueChannel</code> */
    public List getDisplayOptionsListByBlueChannel();
    /** Criteria field name: <code>#DisplayOptionsListByBlueChannel</code> or <code>DisplayOptionsListByBlueChannelList</code> */
    public int countDisplayOptionsListByBlueChannel();

    /** Criteria field name: <code>DisplayOptionsListByGreenChannel</code> */
    public List getDisplayOptionsListByGreenChannel();
    /** Criteria field name: <code>#DisplayOptionsListByGreenChannel</code> or <code>DisplayOptionsListByGreenChannelList</code> */
    public int countDisplayOptionsListByGreenChannel();

    /** Criteria field name: <code>DisplayOptionsListByGreyChannel</code> */
    public List getDisplayOptionsListByGreyChannel();
    /** Criteria field name: <code>#DisplayOptionsListByGreyChannel</code> or <code>DisplayOptionsListByGreyChannelList</code> */
    public int countDisplayOptionsListByGreyChannel();

    /** Criteria field name: <code>DisplayOptionsListByRedChannel</code> */
    public List getDisplayOptionsListByRedChannel();
    /** Criteria field name: <code>#DisplayOptionsListByRedChannel</code> or <code>DisplayOptionsListByRedChannelList</code> */
    public int countDisplayOptionsListByRedChannel();

}
