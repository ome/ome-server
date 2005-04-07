/*
 * org.openmicroscopy.ds.st.ExperimenterDTO
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:03 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Experiment;
import org.openmicroscopy.ds.st.ExperimenterGroup;
import org.openmicroscopy.ds.st.Group;
import org.openmicroscopy.ds.st.RenderingSettings;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ExperimenterDTO
    extends AttributeDTO
    implements Experimenter
{
    public ExperimenterDTO() { super(); }
    public ExperimenterDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Experimenter"; }
    public Class getDTOType() { return Experimenter.class; }

    public String getDataDirectory()
    { return getStringElement("DataDirectory"); }
    public void setDataDirectory(String value)
    { setElement("DataDirectory",value); }

    public String getFirstName()
    { return getStringElement("FirstName"); }
    public void setFirstName(String value)
    { setElement("FirstName",value); }

    public String getLastName()
    { return getStringElement("LastName"); }
    public void setLastName(String value)
    { setElement("LastName",value); }

    public String getEmail()
    { return getStringElement("Email"); }
    public void setEmail(String value)
    { setElement("Email",value); }

    public String getInstitution()
    { return getStringElement("Institution"); }
    public void setInstitution(String value)
    { setElement("Institution",value); }

    public Group getGroup()
    { return (Group) parseChildElement("Group",GroupDTO.class); }
    public void setGroup(Group value)
    { setElement("Group",value); }

    public List getExperimentList()
    { return (List) parseListElement("ExperimentList",ExperimentDTO.class); }
    public int countExperimentList()
    { return countListElement("ExperimentList"); }

    public List getExperimenterGroupList()
    { return (List) parseListElement("ExperimenterGroupList",ExperimenterGroupDTO.class); }
    public int countExperimenterGroupList()
    { return countListElement("ExperimenterGroupList"); }

    public List getGroupListByContact()
    { return (List) parseListElement("GroupListByContact",GroupDTO.class); }
    public int countGroupListByContact()
    { return countListElement("GroupListByContact"); }

    public List getGroupListByLeader()
    { return (List) parseListElement("GroupListByLeader",GroupDTO.class); }
    public int countGroupListByLeader()
    { return countListElement("GroupListByLeader"); }

    public List getRenderingSettingsList()
    { return (List) parseListElement("RenderingSettingsList",RenderingSettingsDTO.class); }
    public int countRenderingSettingsList()
    { return countListElement("RenderingSettingsList"); }


}
