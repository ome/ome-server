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
 * Created by callan via omejava on Fri Dec 17 12:37:15 2004
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
    { return (Instrument) getObjectElement("Instrument"); }
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
    { return (List) getObjectElement("ArcList"); }
    public int countArcList()
    { return countListElement("ArcList"); }

    public List getFilamentList()
    { return (List) getObjectElement("FilamentList"); }
    public int countFilamentList()
    { return countListElement("FilamentList"); }

    public List getLaserListByLightSource()
    { return (List) getObjectElement("LaserListByLightSource"); }
    public int countLaserListByLightSource()
    { return countListElement("LaserListByLightSource"); }

    public List getLaserListByPump()
    { return (List) getObjectElement("LaserListByPump"); }
    public int countLaserListByPump()
    { return countListElement("LaserListByPump"); }

    public List getLogicalChannelListByAuxLightSource()
    { return (List) getObjectElement("LogicalChannelListByAuxLightSource"); }
    public int countLogicalChannelListByAuxLightSource()
    { return countListElement("LogicalChannelListByAuxLightSource"); }

    public List getLogicalChannelListByLightSource()
    { return (List) getObjectElement("LogicalChannelListByLightSource"); }
    public int countLogicalChannelListByLightSource()
    { return countListElement("LogicalChannelListByLightSource"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Instrument",InstrumentDTO.class);
        parseListElement("ArcList",ArcDTO.class);
        parseListElement("FilamentList",FilamentDTO.class);
        parseListElement("LaserListByLightSource",LaserDTO.class);
        parseListElement("LaserListByPump",LaserDTO.class);
        parseListElement("LogicalChannelListByAuxLightSource",LogicalChannelDTO.class);
        parseListElement("LogicalChannelListByLightSource",LogicalChannelDTO.class);
    }

}
