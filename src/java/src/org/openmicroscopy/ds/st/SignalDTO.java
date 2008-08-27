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
 * Created by hochheiserha via omejava on Mon May  2 15:12:25 2005
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

    public String getDTOTypeName() { return "@Signal"; }
    public Class getDTOType() { return Signal.class; }

    public Float getBackground()
    { return getFloatElement("Background"); }
    public void setBackground(Float value)
    { setElement("Background",value); }

    public Float getGeometricSigma()
    { return getFloatElement("GeometricSigma"); }
    public void setGeometricSigma(Float value)
    { setElement("GeometricSigma",value); }

    public Float getSigma()
    { return getFloatElement("Sigma"); }
    public void setSigma(Float value)
    { setElement("Sigma",value); }

    public Float getGeometricMean()
    { return getFloatElement("GeometricMean"); }
    public void setGeometricMean(Float value)
    { setElement("GeometricMean",value); }

    public Float getMean()
    { return getFloatElement("Mean"); }
    public void setMean(Float value)
    { setElement("Mean",value); }

    public Float getIntegral()
    { return getFloatElement("Integral"); }
    public void setIntegral(Float value)
    { setElement("Integral",value); }

    public Float getCentroidZ()
    { return getFloatElement("CentroidZ"); }
    public void setCentroidZ(Float value)
    { setElement("CentroidZ",value); }

    public Float getCentroidY()
    { return getFloatElement("CentroidY"); }
    public void setCentroidY(Float value)
    { setElement("CentroidY",value); }

    public Float getCentroidX()
    { return getFloatElement("CentroidX"); }
    public void setCentroidX(Float value)
    { setElement("CentroidX",value); }

    public Integer getTheC()
    { return getIntegerElement("TheC"); }
    public void setTheC(Integer value)
    { setElement("TheC",value); }


}
