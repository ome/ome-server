/*
 * org.openmicroscopy.ds.st.Experimenter
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
 * Created by dcreager via omejava on Mon Aug 23 11:24:39 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.DatasetAnnotation;
import org.openmicroscopy.ds.st.Experiment;
import org.openmicroscopy.ds.st.ExperimenterGroup;
import org.openmicroscopy.ds.st.Group;
import org.openmicroscopy.ds.st.ImageAnnotation;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Experimenter
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>FirstName</code> */
    public String getFirstName();
    public void setFirstName(String value);

    /** Criteria field name: <code>LastName</code> */
    public String getLastName();
    public void setLastName(String value);

    /** Criteria field name: <code>Email</code> */
    public String getEmail();
    public void setEmail(String value);

    /** Criteria field name: <code>Institution</code> */
    public String getInstitution();
    public void setInstitution(String value);

    /** Criteria field name: <code>DataDirectory</code> */
    public String getDataDirectory();
    public void setDataDirectory(String value);

    /** Criteria field name: <code>Group</code> */
    public Group getGroup();
    public void setGroup(Group value);

    /** Criteria field name: <code>DatasetAnnotations</code> */
    public List getDatasetAnnotations();
    /** Criteria field name: <code>#DatasetAnnotations</code> or <code>DatasetAnnotations</code> */
    public int countDatasetAnnotations();

    /** Criteria field name: <code>Experiments</code> */
    public List getExperiments();
    /** Criteria field name: <code>#Experiments</code> or <code>Experiments</code> */
    public int countExperiments();

    /** Criteria field name: <code>ExperimenterGroups</code> */
    public List getExperimenterGroups();
    /** Criteria field name: <code>#ExperimenterGroups</code> or <code>ExperimenterGroups</code> */
    public int countExperimenterGroups();

    /** Criteria field name: <code>GroupsByContact</code> */
    public List getGroupsByContact();
    /** Criteria field name: <code>#GroupsByContact</code> or <code>GroupsByContact</code> */
    public int countGroupsByContact();

    /** Criteria field name: <code>GroupsByLeader</code> */
    public List getGroupsByLeader();
    /** Criteria field name: <code>#GroupsByLeader</code> or <code>GroupsByLeader</code> */
    public int countGroupsByLeader();

    /** Criteria field name: <code>ImageAnnotations</code> */
    public List getImageAnnotations();
    /** Criteria field name: <code>#ImageAnnotations</code> or <code>ImageAnnotations</code> */
    public int countImageAnnotations();

}
