/*
 * org.openmicroscopy.ds.st.Instrument
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
 * Created by dcreager via omejava on Wed Feb 18 17:57:29 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Detector;
import org.openmicroscopy.ds.st.Filter;
import org.openmicroscopy.ds.st.ImageInstrument;
import org.openmicroscopy.ds.st.LightSource;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.st.Objective;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Instrument
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Manufacturer</code> */
    public String getManufacturer();
    public void setManufacturer(String value);

    /** Criteria field name: <code>Model</code> */
    public String getModel();
    public void setModel(String value);

    /** Criteria field name: <code>SerialNumber</code> */
    public String getSerialNumber();
    public void setSerialNumber(String value);

    /** Criteria field name: <code>Type</code> */
    public String getType();
    public void setType(String value);

    /** Criteria field name: <code>Detectors</code> */
    public List getDetectors();
    /** Criteria field name: <code>#Detectors</code> */
    public int countDetectors();

    /** Criteria field name: <code>Filters</code> */
    public List getFilters();
    /** Criteria field name: <code>#Filters</code> */
    public int countFilters();

    /** Criteria field name: <code>ImageInstruments</code> */
    public List getImageInstruments();
    /** Criteria field name: <code>#ImageInstruments</code> */
    public int countImageInstruments();

    /** Criteria field name: <code>LightSources</code> */
    public List getLightSources();
    /** Criteria field name: <code>#LightSources</code> */
    public int countLightSources();

    /** Criteria field name: <code>OTFs</code> */
    public List getOTFs();
    /** Criteria field name: <code>#OTFs</code> */
    public int countOTFs();

    /** Criteria field name: <code>Objectives</code> */
    public List getObjectives();
    /** Criteria field name: <code>#Objectives</code> */
    public int countObjectives();

}
