/*
 * org.openmicroscopy.ds.st.Detector
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
 * Created by hochheiserha via omejava on Mon May  2 15:12:23 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.LogicalChannel;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Detector
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Instrument</code> */
    public Instrument getInstrument();
    public void setInstrument(Instrument value);

    /** Criteria field name: <code>Offset</code> */
    public Float getOffset();
    public void setOffset(Float value);

    /** Criteria field name: <code>Voltage</code> */
    public Float getVoltage();
    public void setVoltage(Float value);

    /** Criteria field name: <code>Gain</code> */
    public Float getGain();
    public void setGain(Float value);

    /** Criteria field name: <code>Type</code> */
    public String getType();
    public void setType(String value);

    /** Criteria field name: <code>SerialNumber</code> */
    public String getSerialNumber();
    public void setSerialNumber(String value);

    /** Criteria field name: <code>Model</code> */
    public String getModel();
    public void setModel(String value);

    /** Criteria field name: <code>Manufacturer</code> */
    public String getManufacturer();
    public void setManufacturer(String value);

    /** Criteria field name: <code>LogicalChannelList</code> */
    public List getLogicalChannelList();
    /** Criteria field name: <code>#LogicalChannelList</code> or <code>LogicalChannelListList</code> */
    public int countLogicalChannelList();

}
