/*
 * org.openmicroscopy.ds.st.ObjectiveDTO
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
import org.openmicroscopy.ds.st.ImageInstrument;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ObjectiveDTO
    extends AttributeDTO
    implements Objective
{
    public ObjectiveDTO() { super(); }
    public ObjectiveDTO(Map elements) { super(elements); }

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

    public float getLensNA()
    { return getFloatElement("LensNA"); }
    public void setLensNA(float value)
    { setElement("LensNA",new Float(value)); }

    public float getMagnification()
    { return getFloatElement("Magnification"); }
    public void setMagnification(float value)
    { setElement("Magnification",new Float(value)); }

    public Instrument getInstrument()
    { return (Instrument) getObjectElement("Instrument"); }
    public void setInstrument(Instrument value)
    { setElement("Instrument",value); }

    public List getImageInstruments()
    { return (List) getObjectElement("ImageInstruments"); }

    public List getOTFs()
    { return (List) getObjectElement("OTFs"); }

    protected void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Instrument",InstrumentDTO.class);
        parseListElement("ImageInstruments",ImageInstrumentDTO.class);
        parseListElement("OTFs",OTFDTO.class);
    }

}
