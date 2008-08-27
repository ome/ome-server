/*
 * org.openmicroscopy.ds.st.LogicalChannel
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
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface LogicalChannel
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>NDFilter</code> */
    public Float getNDFilter();
    public void setNDFilter(Float value);

    /** Criteria field name: <code>Fluor</code> */
    public String getFluor();
    public void setFluor(String value);

    /** Criteria field name: <code>EmissionWavelength</code> */
    public Integer getEmissionWavelength();
    public void setEmissionWavelength(Integer value);

    /** Criteria field name: <code>ExcitationWavelength</code> */
    public Integer getExcitationWavelength();
    public void setExcitationWavelength(Integer value);

    /** Criteria field name: <code>AuxLightWavelength</code> */
    public Integer getAuxLightWavelength();
    public void setAuxLightWavelength(Integer value);

    /** Criteria field name: <code>AuxTechnique</code> */
    public String getAuxTechnique();
    public void setAuxTechnique(String value);

    /** Criteria field name: <code>AuxLightAttenuation</code> */
    public Float getAuxLightAttenuation();
    public void setAuxLightAttenuation(Float value);

    /** Criteria field name: <code>AuxLightSource</code> */
    public LightSource getAuxLightSource();
    public void setAuxLightSource(LightSource value);

    /** Criteria field name: <code>ContrastMethod</code> */
    public String getContrastMethod();
    public void setContrastMethod(String value);

    /** Criteria field name: <code>Mode</code> */
    public String getMode();
    public void setMode(String value);

    /** Criteria field name: <code>PhotometricInterpretation</code> */
    public String getPhotometricInterpretation();
    public void setPhotometricInterpretation(String value);

    /** Criteria field name: <code>PinholeSize</code> */
    public Integer getPinholeSize();
    public void setPinholeSize(Integer value);

    /** Criteria field name: <code>IlluminationType</code> */
    public String getIlluminationType();
    public void setIlluminationType(String value);

    /** Criteria field name: <code>DetectorGain</code> */
    public Float getDetectorGain();
    public void setDetectorGain(Float value);

    /** Criteria field name: <code>DetectorOffset</code> */
    public Float getDetectorOffset();
    public void setDetectorOffset(Float value);

    /** Criteria field name: <code>Detector</code> */
    public Detector getDetector();
    public void setDetector(Detector value);

    /** Criteria field name: <code>OTF</code> */
    public OTF getOTF();
    public void setOTF(OTF value);

    /** Criteria field name: <code>LightWavelength</code> */
    public Integer getLightWavelength();
    public void setLightWavelength(Integer value);

    /** Criteria field name: <code>LightAttenuation</code> */
    public Float getLightAttenuation();
    public void setLightAttenuation(Float value);

    /** Criteria field name: <code>LightSource</code> */
    public LightSource getLightSource();
    public void setLightSource(LightSource value);

    /** Criteria field name: <code>Filter</code> */
    public Filter getFilter();
    public void setFilter(Filter value);

    /** Criteria field name: <code>SamplesPerPixel</code> */
    public Integer getSamplesPerPixel();
    public void setSamplesPerPixel(Integer value);

    /** Criteria field name: <code>Name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>PixelChannelComponentList</code> */
    public List getPixelChannelComponentList();
    /** Criteria field name: <code>#PixelChannelComponentList</code> or <code>PixelChannelComponentListList</code> */
    public int countPixelChannelComponentList();

}
