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
 * Created by dcreager via omejava on Thu Feb 12 14:35:08 2004
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
    /** Criteria field name: <code>Name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>SamplesPerPixel</code> */
    public int getSamplesPerPixel();
    public void setSamplesPerPixel(int value);

    /** Criteria field name: <code>Filter</code> */
    public Filter getFilter();
    public void setFilter(Filter value);

    /** Criteria field name: <code>LightSource</code> */
    public LightSource getLightSource();
    public void setLightSource(LightSource value);

    /** Criteria field name: <code>LightAttenuation</code> */
    public float getLightAttenuation();
    public void setLightAttenuation(float value);

    /** Criteria field name: <code>LightWavelength</code> */
    public int getLightWavelength();
    public void setLightWavelength(int value);

    /** Criteria field name: <code>OTF</code> */
    public OTF getOTF();
    public void setOTF(OTF value);

    /** Criteria field name: <code>Detector</code> */
    public Detector getDetector();
    public void setDetector(Detector value);

    /** Criteria field name: <code>DetectorOffset</code> */
    public float getDetectorOffset();
    public void setDetectorOffset(float value);

    /** Criteria field name: <code>DetectorGain</code> */
    public float getDetectorGain();
    public void setDetectorGain(float value);

    /** Criteria field name: <code>IlluminationType</code> */
    public String getIlluminationType();
    public void setIlluminationType(String value);

    /** Criteria field name: <code>PinholeSize</code> */
    public int getPinholeSize();
    public void setPinholeSize(int value);

    /** Criteria field name: <code>PhotometricInterpretation</code> */
    public String getPhotometricInterpretation();
    public void setPhotometricInterpretation(String value);

    /** Criteria field name: <code>Mode</code> */
    public String getMode();
    public void setMode(String value);

    /** Criteria field name: <code>ContrastMethod</code> */
    public String getContrastMethod();
    public void setContrastMethod(String value);

    /** Criteria field name: <code>AuxLightSource</code> */
    public LightSource getAuxLightSource();
    public void setAuxLightSource(LightSource value);

    /** Criteria field name: <code>AuxLightAttenuation</code> */
    public float getAuxLightAttenuation();
    public void setAuxLightAttenuation(float value);

    /** Criteria field name: <code>AuxTechnique</code> */
    public String getAuxTechnique();
    public void setAuxTechnique(String value);

    /** Criteria field name: <code>AuxLightWavelength</code> */
    public int getAuxLightWavelength();
    public void setAuxLightWavelength(int value);

    /** Criteria field name: <code>ExcitationWavelength</code> */
    public int getExcitationWavelength();
    public void setExcitationWavelength(int value);

    /** Criteria field name: <code>EmissionWavelength</code> */
    public int getEmissionWavelength();
    public void setEmissionWavelength(int value);

    /** Criteria field name: <code>Fluor</code> */
    public String getFluor();
    public void setFluor(String value);

    /** Criteria field name: <code>NDFilter</code> */
    public float getNDFilter();
    public void setNDFilter(float value);

    /** Criteria field name: <code>PixelChannelComponents</code> */
    public List getPixelChannelComponents();
    /** Criteria field name: <code>#PixelChannelComponents</code> */
    public int countPixelChannelComponents();

}
