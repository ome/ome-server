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
 * Created by hochheiserha via omejava on Mon May  2 15:12:24 2005
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

    public String getDTOTypeName() { return "@LogicalChannel"; }
    public Class getDTOType() { return LogicalChannel.class; }

    public Float getNDFilter()
    { return getFloatElement("NDFilter"); }
    public void setNDFilter(Float value)
    { setElement("NDFilter",value); }

    public String getFluor()
    { return getStringElement("Fluor"); }
    public void setFluor(String value)
    { setElement("Fluor",value); }

    public Integer getEmissionWavelength()
    { return getIntegerElement("EmissionWavelength"); }
    public void setEmissionWavelength(Integer value)
    { setElement("EmissionWavelength",value); }

    public Integer getExcitationWavelength()
    { return getIntegerElement("ExcitationWavelength"); }
    public void setExcitationWavelength(Integer value)
    { setElement("ExcitationWavelength",value); }

    public Integer getAuxLightWavelength()
    { return getIntegerElement("AuxLightWavelength"); }
    public void setAuxLightWavelength(Integer value)
    { setElement("AuxLightWavelength",value); }

    public String getAuxTechnique()
    { return getStringElement("AuxTechnique"); }
    public void setAuxTechnique(String value)
    { setElement("AuxTechnique",value); }

    public Float getAuxLightAttenuation()
    { return getFloatElement("AuxLightAttenuation"); }
    public void setAuxLightAttenuation(Float value)
    { setElement("AuxLightAttenuation",value); }

    public LightSource getAuxLightSource()
    { return (LightSource) parseChildElement("AuxLightSource",LightSourceDTO.class); }
    public void setAuxLightSource(LightSource value)
    { setElement("AuxLightSource",value); }

    public String getContrastMethod()
    { return getStringElement("ContrastMethod"); }
    public void setContrastMethod(String value)
    { setElement("ContrastMethod",value); }

    public String getMode()
    { return getStringElement("Mode"); }
    public void setMode(String value)
    { setElement("Mode",value); }

    public String getPhotometricInterpretation()
    { return getStringElement("PhotometricInterpretation"); }
    public void setPhotometricInterpretation(String value)
    { setElement("PhotometricInterpretation",value); }

    public Integer getPinholeSize()
    { return getIntegerElement("PinholeSize"); }
    public void setPinholeSize(Integer value)
    { setElement("PinholeSize",value); }

    public String getIlluminationType()
    { return getStringElement("IlluminationType"); }
    public void setIlluminationType(String value)
    { setElement("IlluminationType",value); }

    public Float getDetectorGain()
    { return getFloatElement("DetectorGain"); }
    public void setDetectorGain(Float value)
    { setElement("DetectorGain",value); }

    public Float getDetectorOffset()
    { return getFloatElement("DetectorOffset"); }
    public void setDetectorOffset(Float value)
    { setElement("DetectorOffset",value); }

    public Detector getDetector()
    { return (Detector) parseChildElement("Detector",DetectorDTO.class); }
    public void setDetector(Detector value)
    { setElement("Detector",value); }

    public OTF getOTF()
    { return (OTF) parseChildElement("OTF",OTFDTO.class); }
    public void setOTF(OTF value)
    { setElement("OTF",value); }

    public Integer getLightWavelength()
    { return getIntegerElement("LightWavelength"); }
    public void setLightWavelength(Integer value)
    { setElement("LightWavelength",value); }

    public Float getLightAttenuation()
    { return getFloatElement("LightAttenuation"); }
    public void setLightAttenuation(Float value)
    { setElement("LightAttenuation",value); }

    public LightSource getLightSource()
    { return (LightSource) parseChildElement("LightSource",LightSourceDTO.class); }
    public void setLightSource(LightSource value)
    { setElement("LightSource",value); }

    public Filter getFilter()
    { return (Filter) parseChildElement("Filter",FilterDTO.class); }
    public void setFilter(Filter value)
    { setElement("Filter",value); }

    public Integer getSamplesPerPixel()
    { return getIntegerElement("SamplesPerPixel"); }
    public void setSamplesPerPixel(Integer value)
    { setElement("SamplesPerPixel",value); }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public List getPixelChannelComponentList()
    { return (List) parseListElement("PixelChannelComponentList",PixelChannelComponentDTO.class); }
    public int countPixelChannelComponentList()
    { return countListElement("PixelChannelComponentList"); }


}
