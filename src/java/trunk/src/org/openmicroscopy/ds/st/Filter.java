/*
 * org.openmicroscopy.ds.st.Filter
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
 * Created by dcreager via omejava on Thu Feb 12 14:35:07 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Dichroic;
import org.openmicroscopy.ds.st.EmissionFilter;
import org.openmicroscopy.ds.st.ExcitationFilter;
import org.openmicroscopy.ds.st.FilterSet;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.LogicalChannel;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Filter
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Instrument</code> */
    public Instrument getInstrument();
    public void setInstrument(Instrument value);

    /** Criteria field name: <code>Dichroics</code> */
    public List getDichroics();
    /** Criteria field name: <code>#Dichroics</code> */
    public int countDichroics();

    /** Criteria field name: <code>EmissionFilters</code> */
    public List getEmissionFilters();
    /** Criteria field name: <code>#EmissionFilters</code> */
    public int countEmissionFilters();

    /** Criteria field name: <code>ExcitationFilters</code> */
    public List getExcitationFilters();
    /** Criteria field name: <code>#ExcitationFilters</code> */
    public int countExcitationFilters();

    /** Criteria field name: <code>FilterSets</code> */
    public List getFilterSets();
    /** Criteria field name: <code>#FilterSets</code> */
    public int countFilterSets();

    /** Criteria field name: <code>LogicalChannels</code> */
    public List getLogicalChannels();
    /** Criteria field name: <code>#LogicalChannels</code> */
    public int countLogicalChannels();

    /** Criteria field name: <code>OTFs</code> */
    public List getOTFs();
    /** Criteria field name: <code>#OTFs</code> */
    public int countOTFs();

}
