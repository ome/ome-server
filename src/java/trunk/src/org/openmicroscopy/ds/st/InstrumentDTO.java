/*
 * org.openmicroscopy.ds.st.InstrumentDTO
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
import org.openmicroscopy.ds.st.Detector;
import org.openmicroscopy.ds.st.Filter;
import org.openmicroscopy.ds.st.ImageInstrument;
import org.openmicroscopy.ds.st.LightSource;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.st.Objective;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class InstrumentDTO
    extends AttributeDTO
    implements Instrument
{
    public InstrumentDTO() { super(); }
    public InstrumentDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Instrument"; }
    public Class getDTOType() { return Instrument.class; }

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

    public String getType()
    { return getStringElement("Type"); }
    public void setType(String value)
    { setElement("Type",value); }

    public List getDetectors()
    { return (List) getObjectElement("Detectors"); }
    public int countDetectors()
    { return countListElement("Detectors"); }

    public List getFilters()
    { return (List) getObjectElement("Filters"); }
    public int countFilters()
    { return countListElement("Filters"); }

    public List getImageInstruments()
    { return (List) getObjectElement("ImageInstruments"); }
    public int countImageInstruments()
    { return countListElement("ImageInstruments"); }

    public List getLightSources()
    { return (List) getObjectElement("LightSources"); }
    public int countLightSources()
    { return countListElement("LightSources"); }

    public List getOTFs()
    { return (List) getObjectElement("OTFs"); }
    public int countOTFs()
    { return countListElement("OTFs"); }

    public List getObjectives()
    { return (List) getObjectElement("Objectives"); }
    public int countObjectives()
    { return countListElement("Objectives"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseListElement("Detectors",DetectorDTO.class);
        parseListElement("Filters",FilterDTO.class);
        parseListElement("ImageInstruments",ImageInstrumentDTO.class);
        parseListElement("LightSources",LightSourceDTO.class);
        parseListElement("OTFs",OTFDTO.class);
        parseListElement("Objectives",ObjectiveDTO.class);
    }

}
