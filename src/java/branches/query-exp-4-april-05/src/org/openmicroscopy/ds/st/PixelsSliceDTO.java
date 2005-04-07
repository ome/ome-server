/*
 * org.openmicroscopy.ds.st.PixelsSliceDTO
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:07 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.BinaryMask;
import org.openmicroscopy.ds.st.ChebyshevCoefficientMatrix;
import org.openmicroscopy.ds.st.ChebyshevFourierCoefficientMatrix;
import org.openmicroscopy.ds.st.FrequencySpace;
import org.openmicroscopy.ds.st.Gradient;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.st.PixelsChannelSlice;
import org.openmicroscopy.ds.st.PixelsPlaneSlice;
import org.openmicroscopy.ds.st.PixelsStackSlice;
import org.openmicroscopy.ds.st.PixelsTimeSlice;
import org.openmicroscopy.ds.st.SignatureVector;
import org.openmicroscopy.ds.st.WaveletCoefficientsLevel1;
import org.openmicroscopy.ds.st.WaveletCoefficientsLevel2;
import org.openmicroscopy.ds.st.ZernikeMoments;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class PixelsSliceDTO
    extends AttributeDTO
    implements PixelsSlice
{
    public PixelsSliceDTO() { super(); }
    public PixelsSliceDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@PixelsSlice"; }
    public Class getDTOType() { return PixelsSlice.class; }

    public Integer getStartY()
    { return getIntegerElement("StartY"); }
    public void setStartY(Integer value)
    { setElement("StartY",value); }

    public Integer getStartX()
    { return getIntegerElement("StartX"); }
    public void setStartX(Integer value)
    { setElement("StartX",value); }

    public Integer getEndX()
    { return getIntegerElement("EndX"); }
    public void setEndX(Integer value)
    { setElement("EndX",value); }

    public Integer getEndY()
    { return getIntegerElement("EndY"); }
    public void setEndY(Integer value)
    { setElement("EndY",value); }

    public Integer getStartZ()
    { return getIntegerElement("StartZ"); }
    public void setStartZ(Integer value)
    { setElement("StartZ",value); }

    public Integer getEndZ()
    { return getIntegerElement("EndZ"); }
    public void setEndZ(Integer value)
    { setElement("EndZ",value); }

    public Integer getStartC()
    { return getIntegerElement("StartC"); }
    public void setStartC(Integer value)
    { setElement("StartC",value); }

    public Integer getEndC()
    { return getIntegerElement("EndC"); }
    public void setEndC(Integer value)
    { setElement("EndC",value); }

    public Integer getStartT()
    { return getIntegerElement("StartT"); }
    public void setStartT(Integer value)
    { setElement("StartT",value); }

    public Integer getEndT()
    { return getIntegerElement("EndT"); }
    public void setEndT(Integer value)
    { setElement("EndT",value); }

    public Pixels getParent()
    { return (Pixels) parseChildElement("Parent",PixelsDTO.class); }
    public void setParent(Pixels value)
    { setElement("Parent",value); }

    public List getBinaryMaskList()
    { return (List) parseListElement("BinaryMaskList",BinaryMaskDTO.class); }
    public int countBinaryMaskList()
    { return countListElement("BinaryMaskList"); }

    public List getChebyshevCoefficientMatrixList()
    { return (List) parseListElement("ChebyshevCoefficientMatrixList",ChebyshevCoefficientMatrixDTO.class); }
    public int countChebyshevCoefficientMatrixList()
    { return countListElement("ChebyshevCoefficientMatrixList"); }

    public List getChebyshevFourierCoefficientMatrixList()
    { return (List) parseListElement("ChebyshevFourierCoefficientMatrixList",ChebyshevFourierCoefficientMatrixDTO.class); }
    public int countChebyshevFourierCoefficientMatrixList()
    { return countListElement("ChebyshevFourierCoefficientMatrixList"); }

    public List getFrequencySpaceList()
    { return (List) parseListElement("FrequencySpaceList",FrequencySpaceDTO.class); }
    public int countFrequencySpaceList()
    { return countListElement("FrequencySpaceList"); }

    public List getGradientList()
    { return (List) parseListElement("GradientList",GradientDTO.class); }
    public int countGradientList()
    { return countListElement("GradientList"); }

    public List getPixelsChannelSliceList()
    { return (List) parseListElement("PixelsChannelSliceList",PixelsChannelSliceDTO.class); }
    public int countPixelsChannelSliceList()
    { return countListElement("PixelsChannelSliceList"); }

    public List getPixelsPlaneSliceList()
    { return (List) parseListElement("PixelsPlaneSliceList",PixelsPlaneSliceDTO.class); }
    public int countPixelsPlaneSliceList()
    { return countListElement("PixelsPlaneSliceList"); }

    public List getPixelsStackSliceList()
    { return (List) parseListElement("PixelsStackSliceList",PixelsStackSliceDTO.class); }
    public int countPixelsStackSliceList()
    { return countListElement("PixelsStackSliceList"); }

    public List getPixelsTimeSliceList()
    { return (List) parseListElement("PixelsTimeSliceList",PixelsTimeSliceDTO.class); }
    public int countPixelsTimeSliceList()
    { return countListElement("PixelsTimeSliceList"); }

    public List getSignatureVectorList()
    { return (List) parseListElement("SignatureVectorList",SignatureVectorDTO.class); }
    public int countSignatureVectorList()
    { return countListElement("SignatureVectorList"); }

    public List getWaveletCoefficientsLevel1List()
    { return (List) parseListElement("WaveletCoefficientsLevel1List",WaveletCoefficientsLevel1DTO.class); }
    public int countWaveletCoefficientsLevel1List()
    { return countListElement("WaveletCoefficientsLevel1List"); }

    public List getWaveletCoefficientsLevel2List()
    { return (List) parseListElement("WaveletCoefficientsLevel2List",WaveletCoefficientsLevel2DTO.class); }
    public int countWaveletCoefficientsLevel2List()
    { return countListElement("WaveletCoefficientsLevel2List"); }

    public List getZernikeMomentsList()
    { return (List) parseListElement("ZernikeMomentsList",ZernikeMomentsDTO.class); }
    public int countZernikeMomentsList()
    { return countListElement("ZernikeMomentsList"); }


}
