/*
 * org.openmicroscopy.ds.st.LogicalChannelDTO
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
import org.openmicroscopy.ds.st.Detector;
import org.openmicroscopy.ds.st.Filter;
import org.openmicroscopy.ds.st.LightSource;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.st.PixelChannelComponent;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class LogicalChannelDTO
    extends AttributeDTO
    implements LogicalChannel
{
    public LogicalChannelDTO() { super(); }
    public LogicalChannelDTO(Map elements) { super(elements); }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public int getSamplesPerPixel()
    { return getIntElement("SamplesPerPixel"); }
    public void setSamplesPerPixel(int value)
    { setElement("SamplesPerPixel",new Integer(value)); }

    public Filter getFilter()
    { return (Filter) getObjectElement("Filter"); }
    public void setFilter(Filter value)
    { setElement("Filter",value); }

    public LightSource getLightSource()
    { return (LightSource) getObjectElement("LightSource"); }
    public void setLightSource(LightSource value)
    { setElement("LightSource",value); }

    public float getLightAttenuation()
    { return getFloatElement("LightAttenuation"); }
    public void setLightAttenuation(float value)
    { setElement("LightAttenuation",new Float(value)); }

    public int getLightWavelength()
    { return getIntElement("LightWavelength"); }
    public void setLightWavelength(int value)
    { setElement("LightWavelength",new Integer(value)); }

    public OTF getOTF()
    { return (OTF) getObjectElement("OTF"); }
    public void setOTF(OTF value)
    { setElement("OTF",value); }

    public Detector getDetector()
    { return (Detector) getObjectElement("Detector"); }
    public void setDetector(Detector value)
    { setElement("Detector",value); }

    public float getDetectorOffset()
    { return getFloatElement("DetectorOffset"); }
    public void setDetectorOffset(float value)
    { setElement("DetectorOffset",new Float(value)); }

    public float getDetectorGain()
    { return getFloatElement("DetectorGain"); }
    public void setDetectorGain(float value)
    { setElement("DetectorGain",new Float(value)); }

    public String getIlluminationType()
    { return getStringElement("IlluminationType"); }
    public void setIlluminationType(String value)
    { setElement("IlluminationType",value); }

    public int getPinholeSize()
    { return getIntElement("PinholeSize"); }
    public void setPinholeSize(int value)
    { setElement("PinholeSize",new Integer(value)); }

    public String getPhotometricInterpretation()
    { return getStringElement("PhotometricInterpretation"); }
    public void setPhotometricInterpretation(String value)
    { setElement("PhotometricInterpretation",value); }

    public String getMode()
    { return getStringElement("Mode"); }
    public void setMode(String value)
    { setElement("Mode",value); }

    public String getContrastMethod()
    { return getStringElement("ContrastMethod"); }
    public void setContrastMethod(String value)
    { setElement("ContrastMethod",value); }

    public LightSource getAuxLightSource()
    { return (LightSource) getObjectElement("AuxLightSource"); }
    public void setAuxLightSource(LightSource value)
    { setElement("AuxLightSource",value); }

    public float getAuxLightAttenuation()
    { return getFloatElement("AuxLightAttenuation"); }
    public void setAuxLightAttenuation(float value)
    { setElement("AuxLightAttenuation",new Float(value)); }

    public String getAuxTechnique()
    { return getStringElement("AuxTechnique"); }
    public void setAuxTechnique(String value)
    { setElement("AuxTechnique",value); }

    public int getAuxLightWavelength()
    { return getIntElement("AuxLightWavelength"); }
    public void setAuxLightWavelength(int value)
    { setElement("AuxLightWavelength",new Integer(value)); }

    public int getExcitationWavelength()
    { return getIntElement("ExcitationWavelength"); }
    public void setExcitationWavelength(int value)
    { setElement("ExcitationWavelength",new Integer(value)); }

    public int getEmissionWavelength()
    { return getIntElement("EmissionWavelength"); }
    public void setEmissionWavelength(int value)
    { setElement("EmissionWavelength",new Integer(value)); }

    public String getFluor()
    { return getStringElement("Fluor"); }
    public void setFluor(String value)
    { setElement("Fluor",value); }

    public float getNDFilter()
    { return getFloatElement("NDFilter"); }
    public void setNDFilter(float value)
    { setElement("NDFilter",new Float(value)); }

    public List getPixelChannelComponents()
    { return (List) getObjectElement("PixelChannelComponents"); }
    public int countPixelChannelComponents()
    { return countListElement("PixelChannelComponents"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Filter",FilterDTO.class);
        parseChildElement("LightSource",LightSourceDTO.class);
        parseChildElement("OTF",OTFDTO.class);
        parseChildElement("Detector",DetectorDTO.class);
        parseChildElement("AuxLightSource",LightSourceDTO.class);
        parseListElement("PixelChannelComponents",PixelChannelComponentDTO.class);
    }

}
