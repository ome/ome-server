/*
 * org.openmicroscopy.ds.st.DisplayOptions
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
import org.openmicroscopy.ds.st.DisplayChannel;
import org.openmicroscopy.ds.st.DisplayROI;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface DisplayOptions
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Pixels</code> */
    public Pixels getPixels();
    public void setPixels(Pixels value);

    /** Criteria field name: <code>Zoom</code> */
    public Float getZoom();
    public void setZoom(Float value);

    /** Criteria field name: <code>RedChannel</code> */
    public DisplayChannel getRedChannel();
    public void setRedChannel(DisplayChannel value);

    /** Criteria field name: <code>RedChannelOn</code> */
    public Boolean isRedChannelOn();
    public void setRedChannelOn(Boolean value);

    /** Criteria field name: <code>GreenChannel</code> */
    public DisplayChannel getGreenChannel();
    public void setGreenChannel(DisplayChannel value);

    /** Criteria field name: <code>GreenChannelOn</code> */
    public Boolean isGreenChannelOn();
    public void setGreenChannelOn(Boolean value);

    /** Criteria field name: <code>BlueChannel</code> */
    public DisplayChannel getBlueChannel();
    public void setBlueChannel(DisplayChannel value);

    /** Criteria field name: <code>BlueChannelOn</code> */
    public Boolean isBlueChannelOn();
    public void setBlueChannelOn(Boolean value);

    /** Criteria field name: <code>DisplayRGB</code> */
    public Boolean isDisplayRGB();
    public void setDisplayRGB(Boolean value);

    /** Criteria field name: <code>GreyChannel</code> */
    public DisplayChannel getGreyChannel();
    public void setGreyChannel(DisplayChannel value);

    /** Criteria field name: <code>ColorMap</code> */
    public String getColorMap();
    public void setColorMap(String value);

    /** Criteria field name: <code>ZStart</code> */
    public Integer getZStart();
    public void setZStart(Integer value);

    /** Criteria field name: <code>ZStop</code> */
    public Integer getZStop();
    public void setZStop(Integer value);

    /** Criteria field name: <code>TStart</code> */
    public Integer getTStart();
    public void setTStart(Integer value);

    /** Criteria field name: <code>TStop</code> */
    public Integer getTStop();
    public void setTStop(Integer value);

    /** Criteria field name: <code>DisplayROIs</code> */
    public List getDisplayROIs();
    /** Criteria field name: <code>#DisplayROIs</code> or <code>DisplayROIs</code> */
    public int countDisplayROIs();

}
