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
 * Created by callan via omejava on Fri Dec 17 12:37:15 2004
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

    /** Criteria field name: <code>DichroicList</code> */
    public List getDichroicList();
    /** Criteria field name: <code>#DichroicList</code> or <code>DichroicList</code> */
    public int countDichroicList();

    /** Criteria field name: <code>EmissionFilterList</code> */
    public List getEmissionFilterList();
    /** Criteria field name: <code>#EmissionFilterList</code> or <code>EmissionFilterList</code> */
    public int countEmissionFilterList();

    /** Criteria field name: <code>ExcitationFilterList</code> */
    public List getExcitationFilterList();
    /** Criteria field name: <code>#ExcitationFilterList</code> or <code>ExcitationFilterList</code> */
    public int countExcitationFilterList();

    /** Criteria field name: <code>FilterSetList</code> */
    public List getFilterSetList();
    /** Criteria field name: <code>#FilterSetList</code> or <code>FilterSetList</code> */
    public int countFilterSetList();

    /** Criteria field name: <code>LogicalChannelList</code> */
    public List getLogicalChannelList();
    /** Criteria field name: <code>#LogicalChannelList</code> or <code>LogicalChannelList</code> */
    public int countLogicalChannelList();

    /** Criteria field name: <code>OTFList</code> */
    public List getOTFList();
    /** Criteria field name: <code>#OTFList</code> or <code>OTFList</code> */
    public int countOTFList();

}
