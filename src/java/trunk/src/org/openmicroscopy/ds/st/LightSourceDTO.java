/*
 * org.openmicroscopy.ds.st.LightSourceDTO
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
import org.openmicroscopy.ds.st.Arc;
import org.openmicroscopy.ds.st.Filament;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.Laser;
import org.openmicroscopy.ds.st.LogicalChannel;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class LightSourceDTO
    extends AttributeDTO
    implements LightSource
{
    public LightSourceDTO() { super(); }
    public LightSourceDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@LightSource"; }
    public Class getDTOType() { return LightSource.class; }

    public Instrument getInstrument()
    { return (Instrument) parseChildElement("Instrument",InstrumentDTO.class); }
    public void setInstrument(Instrument value)
    { setElement("Instrument",value); }

    public String getSerialNumber()
    { return getStringElement("SerialNumber"); }
    public void setSerialNumber(String value)
    { setElement("SerialNumber",value); }

    public String getModel()
    { return getStringElement("Model"); }
    public void setModel(String value)
    { setElement("Model",value); }

    public String getManufacturer()
    { return getStringElement("Manufacturer"); }
    public void setManufacturer(String value)
    { setElement("Manufacturer",value); }

    public List getArcList()
    { return (List) parseListElement("ArcList",ArcDTO.class); }
    public int countArcList()
    { return countListElement("ArcList"); }

    public List getFilamentList()
    { return (List) parseListElement("FilamentList",FilamentDTO.class); }
    public int countFilamentList()
    { return countListElement("FilamentList"); }

    public List getLaserListByLightSource()
    { return (List) parseListElement("LaserListByLightSource",LaserDTO.class); }
    public int countLaserListByLightSource()
    { return countListElement("LaserListByLightSource"); }

    public List getLaserListByPump()
    { return (List) parseListElement("LaserListByPump",LaserDTO.class); }
    public int countLaserListByPump()
    { return countListElement("LaserListByPump"); }

    public List getLogicalChannelListByAuxLightSource()
    { return (List) parseListElement("LogicalChannelListByAuxLightSource",LogicalChannelDTO.class); }
    public int countLogicalChannelListByAuxLightSource()
    { return countListElement("LogicalChannelListByAuxLightSource"); }

    public List getLogicalChannelListByLightSource()
    { return (List) parseListElement("LogicalChannelListByLightSource",LogicalChannelDTO.class); }
    public int countLogicalChannelListByLightSource()
    { return countListElement("LogicalChannelListByLightSource"); }


}
