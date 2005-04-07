/*
 * org.openmicroscopy.ds.st.CoOcMat_MaximalCorrelationCoefficientDTO
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:09 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class CoOcMat_MaximalCorrelationCoefficientDTO
    extends AttributeDTO
    implements CoOcMat_MaximalCorrelationCoefficient
{
    public CoOcMat_MaximalCorrelationCoefficientDTO() { super(); }
    public CoOcMat_MaximalCorrelationCoefficientDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@CoOcMat_MaximalCorrelationCoefficient"; }
    public Class getDTOType() { return CoOcMat_MaximalCorrelationCoefficient.class; }

    public Float getMaxCorrCoef()
    { return getFloatElement("MaxCorrCoef"); }
    public void setMaxCorrCoef(Float value)
    { setElement("MaxCorrCoef",value); }


}
