/*
 * org.openmicroscopy.ds.st.OTFDTO
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
 * Created by dcreager via omejava on Wed Feb  4 17:49:53 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Filter;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.LogicalChannel;
import org.openmicroscopy.ds.st.Objective;
import org.openmicroscopy.ds.st.Repository;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class OTFDTO
    extends AttributeDTO
    implements OTF
{
    public OTFDTO() { super(); }
    public OTFDTO(Map elements) { super(elements); }

    public Objective getObjective()
    { return (Objective) getObjectElement("Objective"); }
    public void setObjective(Objective value)
    { setElement("Objective",value); }

    public Filter getFilter()
    { return (Filter) getObjectElement("Filter"); }
    public void setFilter(Filter value)
    { setElement("Filter",value); }

    public int getSizeX()
    { return getIntElement("SizeX"); }
    public void setSizeX(int value)
    { setElement("SizeX",new Integer(value)); }

    public int getSizeY()
    { return getIntElement("SizeY"); }
    public void setSizeY(int value)
    { setElement("SizeY",new Integer(value)); }

    public String getPixelType()
    { return getStringElement("PixelType"); }
    public void setPixelType(String value)
    { setElement("PixelType",value); }

    public Repository getRepository()
    { return (Repository) getObjectElement("Repository"); }
    public void setRepository(Repository value)
    { setElement("Repository",value); }

    public String getPath()
    { return getStringElement("Path"); }
    public void setPath(String value)
    { setElement("Path",value); }

    public boolean isOpticalAxisAverage()
    { return getBooleanElement("OpticalAxisAverage"); }
    public void setOpticalAxisAverage(boolean value)
    { setElement("OpticalAxisAverage",new Boolean(value)); }

    public Instrument getInstrument()
    { return (Instrument) getObjectElement("Instrument"); }
    public void setInstrument(Instrument value)
    { setElement("Instrument",value); }

    public List getLogicalChannels()
    { return (List) getObjectElement("LogicalChannels"); }

    protected void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Objective",ObjectiveDTO.class);
        parseChildElement("Filter",FilterDTO.class);
        parseChildElement("Repository",RepositoryDTO.class);
        parseChildElement("Instrument",InstrumentDTO.class);
        parseListElement("LogicalChannels",LogicalChannelDTO.class);
    }

}
