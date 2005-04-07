/*
 * org.openmicroscopy.ds.st.LightSource
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:03 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Arc;
import org.openmicroscopy.ds.st.Filament;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.Laser;
import org.openmicroscopy.ds.st.LogicalChannel;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface LightSource
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Manufacturer</code> */
    public String getManufacturer();
    public void setManufacturer(String value);

    /** Criteria field name: <code>Model</code> */
    public String getModel();
    public void setModel(String value);

    /** Criteria field name: <code>SerialNumber</code> */
    public String getSerialNumber();
    public void setSerialNumber(String value);

    /** Criteria field name: <code>Instrument</code> */
    public Instrument getInstrument();
    public void setInstrument(Instrument value);

    /** Criteria field name: <code>ArcList</code> */
    public List getArcList();
    /** Criteria field name: <code>#ArcList</code> or <code>ArcListList</code> */
    public int countArcList();

    /** Criteria field name: <code>FilamentList</code> */
    public List getFilamentList();
    /** Criteria field name: <code>#FilamentList</code> or <code>FilamentListList</code> */
    public int countFilamentList();

    /** Criteria field name: <code>LaserListByLightSource</code> */
    public List getLaserListByLightSource();
    /** Criteria field name: <code>#LaserListByLightSource</code> or <code>LaserListByLightSourceList</code> */
    public int countLaserListByLightSource();

    /** Criteria field name: <code>LaserListByPump</code> */
    public List getLaserListByPump();
    /** Criteria field name: <code>#LaserListByPump</code> or <code>LaserListByPumpList</code> */
    public int countLaserListByPump();

    /** Criteria field name: <code>LogicalChannelListByAuxLightSource</code> */
    public List getLogicalChannelListByAuxLightSource();
    /** Criteria field name: <code>#LogicalChannelListByAuxLightSource</code> or <code>LogicalChannelListByAuxLightSourceList</code> */
    public int countLogicalChannelListByAuxLightSource();

    /** Criteria field name: <code>LogicalChannelListByLightSource</code> */
    public List getLogicalChannelListByLightSource();
    /** Criteria field name: <code>#LogicalChannelListByLightSource</code> or <code>LogicalChannelListByLightSourceList</code> */
    public int countLogicalChannelListByLightSource();

}
