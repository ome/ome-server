/*
 * org.openmicroscopy.ds.st.SignalDTO
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
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class SignalDTO
    extends AttributeDTO
    implements Signal
{
    public SignalDTO() { super(); }
    public SignalDTO(Map elements) { super(elements); }

    public int getTheC()
    { return getIntElement("TheC"); }
    public void setTheC(int value)
    { setElement("TheC",new Integer(value)); }

    public float getCentroidX()
    { return getFloatElement("CentroidX"); }
    public void setCentroidX(float value)
    { setElement("CentroidX",new Float(value)); }

    public float getCentroidY()
    { return getFloatElement("CentroidY"); }
    public void setCentroidY(float value)
    { setElement("CentroidY",new Float(value)); }

    public float getCentroidZ()
    { return getFloatElement("CentroidZ"); }
    public void setCentroidZ(float value)
    { setElement("CentroidZ",new Float(value)); }

    public float getIntegral()
    { return getFloatElement("Integral"); }
    public void setIntegral(float value)
    { setElement("Integral",new Float(value)); }

    public float getMean()
    { return getFloatElement("Mean"); }
    public void setMean(float value)
    { setElement("Mean",new Float(value)); }

    public float getGeometricMean()
    { return getFloatElement("GeometricMean"); }
    public void setGeometricMean(float value)
    { setElement("GeometricMean",new Float(value)); }

    public float getSigma()
    { return getFloatElement("Sigma"); }
    public void setSigma(float value)
    { setElement("Sigma",new Float(value)); }

    public float getGeometricSigma()
    { return getFloatElement("GeometricSigma"); }
    public void setGeometricSigma(float value)
    { setElement("GeometricSigma",new Float(value)); }

    public float getBackground()
    { return getFloatElement("Background"); }
    public void setBackground(float value)
    { setElement("Background",new Float(value)); }


}
