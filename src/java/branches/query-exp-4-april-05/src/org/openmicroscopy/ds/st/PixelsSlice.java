/*
 * org.openmicroscopy.ds.st.PixelsSlice
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
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface PixelsSlice
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>StartY</code> */
    public Integer getStartY();
    public void setStartY(Integer value);

    /** Criteria field name: <code>StartX</code> */
    public Integer getStartX();
    public void setStartX(Integer value);

    /** Criteria field name: <code>EndX</code> */
    public Integer getEndX();
    public void setEndX(Integer value);

    /** Criteria field name: <code>EndY</code> */
    public Integer getEndY();
    public void setEndY(Integer value);

    /** Criteria field name: <code>StartZ</code> */
    public Integer getStartZ();
    public void setStartZ(Integer value);

    /** Criteria field name: <code>EndZ</code> */
    public Integer getEndZ();
    public void setEndZ(Integer value);

    /** Criteria field name: <code>StartC</code> */
    public Integer getStartC();
    public void setStartC(Integer value);

    /** Criteria field name: <code>EndC</code> */
    public Integer getEndC();
    public void setEndC(Integer value);

    /** Criteria field name: <code>StartT</code> */
    public Integer getStartT();
    public void setStartT(Integer value);

    /** Criteria field name: <code>EndT</code> */
    public Integer getEndT();
    public void setEndT(Integer value);

    /** Criteria field name: <code>Parent</code> */
    public Pixels getParent();
    public void setParent(Pixels value);

    /** Criteria field name: <code>BinaryMaskList</code> */
    public List getBinaryMaskList();
    /** Criteria field name: <code>#BinaryMaskList</code> or <code>BinaryMaskListList</code> */
    public int countBinaryMaskList();

    /** Criteria field name: <code>ChebyshevCoefficientMatrixList</code> */
    public List getChebyshevCoefficientMatrixList();
    /** Criteria field name: <code>#ChebyshevCoefficientMatrixList</code> or <code>ChebyshevCoefficientMatrixListList</code> */
    public int countChebyshevCoefficientMatrixList();

    /** Criteria field name: <code>ChebyshevFourierCoefficientMatrixList</code> */
    public List getChebyshevFourierCoefficientMatrixList();
    /** Criteria field name: <code>#ChebyshevFourierCoefficientMatrixList</code> or <code>ChebyshevFourierCoefficientMatrixListList</code> */
    public int countChebyshevFourierCoefficientMatrixList();

    /** Criteria field name: <code>FrequencySpaceList</code> */
    public List getFrequencySpaceList();
    /** Criteria field name: <code>#FrequencySpaceList</code> or <code>FrequencySpaceListList</code> */
    public int countFrequencySpaceList();

    /** Criteria field name: <code>GradientList</code> */
    public List getGradientList();
    /** Criteria field name: <code>#GradientList</code> or <code>GradientListList</code> */
    public int countGradientList();

    /** Criteria field name: <code>PixelsChannelSliceList</code> */
    public List getPixelsChannelSliceList();
    /** Criteria field name: <code>#PixelsChannelSliceList</code> or <code>PixelsChannelSliceListList</code> */
    public int countPixelsChannelSliceList();

    /** Criteria field name: <code>PixelsPlaneSliceList</code> */
    public List getPixelsPlaneSliceList();
    /** Criteria field name: <code>#PixelsPlaneSliceList</code> or <code>PixelsPlaneSliceListList</code> */
    public int countPixelsPlaneSliceList();

    /** Criteria field name: <code>PixelsStackSliceList</code> */
    public List getPixelsStackSliceList();
    /** Criteria field name: <code>#PixelsStackSliceList</code> or <code>PixelsStackSliceListList</code> */
    public int countPixelsStackSliceList();

    /** Criteria field name: <code>PixelsTimeSliceList</code> */
    public List getPixelsTimeSliceList();
    /** Criteria field name: <code>#PixelsTimeSliceList</code> or <code>PixelsTimeSliceListList</code> */
    public int countPixelsTimeSliceList();

    /** Criteria field name: <code>SignatureVectorList</code> */
    public List getSignatureVectorList();
    /** Criteria field name: <code>#SignatureVectorList</code> or <code>SignatureVectorListList</code> */
    public int countSignatureVectorList();

    /** Criteria field name: <code>WaveletCoefficientsLevel1List</code> */
    public List getWaveletCoefficientsLevel1List();
    /** Criteria field name: <code>#WaveletCoefficientsLevel1List</code> or <code>WaveletCoefficientsLevel1ListList</code> */
    public int countWaveletCoefficientsLevel1List();

    /** Criteria field name: <code>WaveletCoefficientsLevel2List</code> */
    public List getWaveletCoefficientsLevel2List();
    /** Criteria field name: <code>#WaveletCoefficientsLevel2List</code> or <code>WaveletCoefficientsLevel2ListList</code> */
    public int countWaveletCoefficientsLevel2List();

    /** Criteria field name: <code>ZernikeMomentsList</code> */
    public List getZernikeMomentsList();
    /** Criteria field name: <code>#ZernikeMomentsList</code> or <code>ZernikeMomentsListList</code> */
    public int countZernikeMomentsList();

}
