/*
 * org.openmicroscopy.ds.st.Group
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
 * Created by dcreager via omejava on Wed Feb 11 16:07:59 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterGroup;
import org.openmicroscopy.ds.st.ImageGroup;
import java.util.List;
import java.util.Map;

public interface Group
    extends Attribute
{
    /** Criteria field name: <code>Name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>Leader</code> */
    public Experimenter getLeader();
    public void setLeader(Experimenter value);

    /** Criteria field name: <code>Contact</code> */
    public Experimenter getContact();
    public void setContact(Experimenter value);

    /** Criteria field name: <code>Experimenters</code> */
    public List getExperimenters();
    /** Criteria field name: <code>#Experimenters</code> */
    public int countExperimenters();

    /** Criteria field name: <code>ExperimenterGroups</code> */
    public List getExperimenterGroups();
    /** Criteria field name: <code>#ExperimenterGroups</code> */
    public int countExperimenterGroups();

    /** Criteria field name: <code>ImageGroups</code> */
    public List getImageGroups();
    /** Criteria field name: <code>#ImageGroups</code> */
    public int countImageGroups();

}
