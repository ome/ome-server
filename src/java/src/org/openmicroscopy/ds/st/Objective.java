/*
 * org.openmicroscopy.ds.st.Objective
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
 * Created by hochheiserha via omejava on Mon May  2 15:12:23 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.ImageInstrument;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Objective
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Instrument</code> */
    public Instrument getInstrument();
    public void setInstrument(Instrument value);

    /** Criteria field name: <code>Magnification</code> */
    public Float getMagnification();
    public void setMagnification(Float value);

    /** Criteria field name: <code>LensNA</code> */
    public Float getLensNA();
    public void setLensNA(Float value);

    /** Criteria field name: <code>SerialNumber</code> */
    public String getSerialNumber();
    public void setSerialNumber(String value);

    /** Criteria field name: <code>Model</code> */
    public String getModel();
    public void setModel(String value);

    /** Criteria field name: <code>Manufacturer</code> */
    public String getManufacturer();
    public void setManufacturer(String value);

    /** Criteria field name: <code>ImageInstrumentList</code> */
    public List getImageInstrumentList();
    /** Criteria field name: <code>#ImageInstrumentList</code> or <code>ImageInstrumentListList</code> */
    public int countImageInstrumentList();

    /** Criteria field name: <code>OTFList</code> */
    public List getOTFList();
    /** Criteria field name: <code>#OTFList</code> or <code>OTFListList</code> */
    public int countOTFList();

}
