/*
 * org.openmicroscopy.ds.st.FilterDTO
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
import org.openmicroscopy.ds.st.Dichroic;
import org.openmicroscopy.ds.st.EmissionFilter;
import org.openmicroscopy.ds.st.ExcitationFilter;
import org.openmicroscopy.ds.st.FilterSet;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.LogicalChannel;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class FilterDTO
    extends AttributeDTO
    implements Filter
{
    public FilterDTO() { super(); }
    public FilterDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Filter"; }
    public Class getDTOType() { return Filter.class; }

    public Instrument getInstrument()
    { return (Instrument) getObjectElement("Instrument"); }
    public void setInstrument(Instrument value)
    { setElement("Instrument",value); }

    public List getDichroicList()
    { return (List) getObjectElement("DichroicList"); }
    public int countDichroicList()
    { return countListElement("DichroicList"); }

    public List getEmissionFilterList()
    { return (List) getObjectElement("EmissionFilterList"); }
    public int countEmissionFilterList()
    { return countListElement("EmissionFilterList"); }

    public List getExcitationFilterList()
    { return (List) getObjectElement("ExcitationFilterList"); }
    public int countExcitationFilterList()
    { return countListElement("ExcitationFilterList"); }

    public List getFilterSetList()
    { return (List) getObjectElement("FilterSetList"); }
    public int countFilterSetList()
    { return countListElement("FilterSetList"); }

    public List getLogicalChannelList()
    { return (List) getObjectElement("LogicalChannelList"); }
    public int countLogicalChannelList()
    { return countListElement("LogicalChannelList"); }

    public List getOTFList()
    { return (List) getObjectElement("OTFList"); }
    public int countOTFList()
    { return countListElement("OTFList"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Instrument",InstrumentDTO.class);
        parseListElement("DichroicList",DichroicDTO.class);
        parseListElement("EmissionFilterList",EmissionFilterDTO.class);
        parseListElement("ExcitationFilterList",ExcitationFilterDTO.class);
        parseListElement("FilterSetList",FilterSetDTO.class);
        parseListElement("LogicalChannelList",LogicalChannelDTO.class);
        parseListElement("OTFList",OTFDTO.class);
    }

}
