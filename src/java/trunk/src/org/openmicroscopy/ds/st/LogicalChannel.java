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
 * Created by dcreager via omejava on Wed Feb  4 17:49:54 2004
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
import java.util.List;
import java.util.Map;

public interface LogicalChannel
    extends Attribute
{
    public String getName();
    public void setName(String value);

    public int getSamplesPerPixel();
    public void setSamplesPerPixel(int value);

    public Filter getFilter();
    public void setFilter(Filter value);

    public LightSource getLightSource();
    public void setLightSource(LightSource value);

    public float getLightAttenuation();
    public void setLightAttenuation(float value);

    public int getLightWavelength();
    public void setLightWavelength(int value);

    public OTF getOTF();
    public void setOTF(OTF value);

    public Detector getDetector();
    public void setDetector(Detector value);

    public float getDetectorOffset();
    public void setDetectorOffset(float value);

    public float getDetectorGain();
    public void setDetectorGain(float value);

    public String getIlluminationType();
    public void setIlluminationType(String value);

    public int getPinholeSize();
    public void setPinholeSize(int value);

    public String getPhotometricInterpretation();
    public void setPhotometricInterpretation(String value);

    public String getMode();
    public void setMode(String value);

    public String getContrastMethod();
    public void setContrastMethod(String value);

    public LightSource getAuxLightSource();
    public void setAuxLightSource(LightSource value);

    public float getAuxLightAttenuation();
    public void setAuxLightAttenuation(float value);

    public String getAuxTechnique();
    public void setAuxTechnique(String value);

    public int getAuxLightWavelength();
    public void setAuxLightWavelength(int value);

    public int getExcitationWavelength();
    public void setExcitationWavelength(int value);

    public int getEmissionWavelength();
    public void setEmissionWavelength(int value);

    public String getFluor();
    public void setFluor(String value);

    public float getNDFilter();
    public void setNDFilter(float value);

    public List getPixelChannelComponents();

}
