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
 * Created by dcreager via omejava on Tue Feb 24 17:23:15 2004
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

    public String getManufacturer()
    { return getStringElement("Manufacturer"); }
    public void setManufacturer(String value)
    { setElement("Manufacturer",value); }

    public String getModel()
    { return getStringElement("Model"); }
    public void setModel(String value)
    { setElement("Model",value); }

    public String getSerialNumber()
    { return getStringElement("SerialNumber"); }
    public void setSerialNumber(String value)
    { setElement("SerialNumber",value); }

    public Instrument getInstrument()
    { return (Instrument) getObjectElement("Instrument"); }
    public void setInstrument(Instrument value)
    { setElement("Instrument",value); }

    public List getArcs()
    { return (List) getObjectElement("Arcs"); }
    public int countArcs()
    { return countListElement("Arcs"); }

    public List getFilaments()
    { return (List) getObjectElement("Filaments"); }
    public int countFilaments()
    { return countListElement("Filaments"); }

    public List getLasersByLightSource()
    { return (List) getObjectElement("LasersByLightSource"); }
    public int countLasersByLightSource()
    { return countListElement("LasersByLightSource"); }

    public List getLasersByPump()
    { return (List) getObjectElement("LasersByPump"); }
    public int countLasersByPump()
    { return countListElement("LasersByPump"); }

    public List getLogicalChannelsByAuxLightSource()
    { return (List) getObjectElement("LogicalChannelsByAuxLightSource"); }
    public int countLogicalChannelsByAuxLightSource()
    { return countListElement("LogicalChannelsByAuxLightSource"); }

    public List getLogicalChannelsByLightSource()
    { return (List) getObjectElement("LogicalChannelsByLightSource"); }
    public int countLogicalChannelsByLightSource()
    { return countListElement("LogicalChannelsByLightSource"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Instrument",InstrumentDTO.class);
        parseListElement("Arcs",ArcDTO.class);
        parseListElement("Filaments",FilamentDTO.class);
        parseListElement("LasersByLightSource",LaserDTO.class);
        parseListElement("LasersByPump",LaserDTO.class);
        parseListElement("LogicalChannelsByAuxLightSource",LogicalChannelDTO.class);
        parseListElement("LogicalChannelsByLightSource",LogicalChannelDTO.class);
    }

}
