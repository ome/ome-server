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
 * Created by dcreager via omejava on Wed Feb 11 16:07:59 2004
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

    public Instrument getInstrument()
    { return (Instrument) getObjectElement("Instrument"); }
    public void setInstrument(Instrument value)
    { setElement("Instrument",value); }

    public List getDichroics()
    { return (List) getObjectElement("Dichroics"); }
    public int countDichroics()
    { return countListElement("Dichroics"); }

    public List getEmissionFilters()
    { return (List) getObjectElement("EmissionFilters"); }
    public int countEmissionFilters()
    { return countListElement("EmissionFilters"); }

    public List getExcitationFilters()
    { return (List) getObjectElement("ExcitationFilters"); }
    public int countExcitationFilters()
    { return countListElement("ExcitationFilters"); }

    public List getFilterSets()
    { return (List) getObjectElement("FilterSets"); }
    public int countFilterSets()
    { return countListElement("FilterSets"); }

    public List getLogicalChannels()
    { return (List) getObjectElement("LogicalChannels"); }
    public int countLogicalChannels()
    { return countListElement("LogicalChannels"); }

    public List getOTFs()
    { return (List) getObjectElement("OTFs"); }
    public int countOTFs()
    { return countListElement("OTFs"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Instrument",InstrumentDTO.class);
        parseListElement("Dichroics",DichroicDTO.class);
        parseListElement("EmissionFilters",EmissionFilterDTO.class);
        parseListElement("ExcitationFilters",ExcitationFilterDTO.class);
        parseListElement("FilterSets",FilterSetDTO.class);
        parseListElement("LogicalChannels",LogicalChannelDTO.class);
        parseListElement("OTFs",OTFDTO.class);
    }

}
