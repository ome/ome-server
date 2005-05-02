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
 * Created by callan via omejava on Fri Dec 17 12:37:15 2004
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
import org.openmicroscopy.ds.st.RenderingSettings;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Experimenter
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Group</code> */
    public Group getGroup();
    public void setGroup(Group value);

    /** Criteria field name: <code>DataDirectory</code> */
    public String getDataDirectory();
    public void setDataDirectory(String value);

    /** Criteria field name: <code>Institution</code> */
    public String getInstitution();
    public void setInstitution(String value);

    /** Criteria field name: <code>Email</code> */
    public String getEmail();
    public void setEmail(String value);

    /** Criteria field name: <code>LastName</code> */
    public String getLastName();
    public void setLastName(String value);

    /** Criteria field name: <code>FirstName</code> */
    public String getFirstName();
    public void setFirstName(String value);

    /** Criteria field name: <code>DatasetAnnotationList</code> */
    public List getDatasetAnnotationList();
    /** Criteria field name: <code>#DatasetAnnotationList</code> or <code>DatasetAnnotationList</code> */
    public int countDatasetAnnotationList();

    /** Criteria field name: <code>ExperimentList</code> */
    public List getExperimentList();
    /** Criteria field name: <code>#ExperimentList</code> or <code>ExperimentList</code> */
    public int countExperimentList();

    /** Criteria field name: <code>ExperimenterGroupList</code> */
    public List getExperimenterGroupList();
    /** Criteria field name: <code>#ExperimenterGroupList</code> or <code>ExperimenterGroupList</code> */
    public int countExperimenterGroupList();

    /** Criteria field name: <code>GroupListByContact</code> */
    public List getGroupListByContact();
    /** Criteria field name: <code>#GroupListByContact</code> or <code>GroupListByContact</code> */
    public int countGroupListByContact();

    /** Criteria field name: <code>GroupListByLeader</code> */
    public List getGroupListByLeader();
    /** Criteria field name: <code>#GroupListByLeader</code> or <code>GroupListByLeader</code> */
    public int countGroupListByLeader();

    /** Criteria field name: <code>ImageAnnotationList</code> */
    public List getImageAnnotationList();
    /** Criteria field name: <code>#ImageAnnotationList</code> or <code>ImageAnnotationList</code> */
    public int countImageAnnotationList();

    /** Criteria field name: <code>RenderingSettingsList</code> */
    public List getRenderingSettingsList();
    /** Criteria field name: <code>#RenderingSettingsList</code> or <code>RenderingSettingsList</code> */
    public int countRenderingSettingsList();

}
