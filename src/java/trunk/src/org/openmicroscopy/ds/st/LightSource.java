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
 * Created by dcreager via omejava on Wed Feb 18 17:57:29 2004
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

    /** Criteria field name: <code>Arcs</code> */
    public List getArcs();
    /** Criteria field name: <code>#Arcs</code> */
    public int countArcs();

    /** Criteria field name: <code>Filaments</code> */
    public List getFilaments();
    /** Criteria field name: <code>#Filaments</code> */
    public int countFilaments();

    /** Criteria field name: <code>LasersByLightSource</code> */
    public List getLasersByLightSource();
    /** Criteria field name: <code>#LasersByLightSource</code> */
    public int countLasersByLightSource();

    /** Criteria field name: <code>LasersByPump</code> */
    public List getLasersByPump();
    /** Criteria field name: <code>#LasersByPump</code> */
    public int countLasersByPump();

    /** Criteria field name: <code>LogicalChannelsByAuxLightSource</code> */
    public List getLogicalChannelsByAuxLightSource();
    /** Criteria field name: <code>#LogicalChannelsByAuxLightSource</code> */
    public int countLogicalChannelsByAuxLightSource();

    /** Criteria field name: <code>LogicalChannelsByLightSource</code> */
    public List getLogicalChannelsByLightSource();
    /** Criteria field name: <code>#LogicalChannelsByLightSource</code> */
    public int countLogicalChannelsByLightSource();

}
