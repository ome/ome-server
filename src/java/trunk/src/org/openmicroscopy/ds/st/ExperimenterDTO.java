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

    public String getDataDirectory()
    { return getStringElement("DataDirectory"); }
    public void setDataDirectory(String value)
    { setElement("DataDirectory",value); }

    public Group getGroup()
    { return (Group) getObjectElement("Group"); }
    public void setGroup(Group value)
    { setElement("Group",value); }

    public List getDatasetAnnotations()
    { return (List) getObjectElement("DatasetAnnotations"); }
    public int countDatasetAnnotations()
    { return countListElement("DatasetAnnotations"); }

    public List getExperiments()
    { return (List) getObjectElement("Experiments"); }
    public int countExperiments()
    { return countListElement("Experiments"); }

    public List getExperimenterGroups()
    { return (List) getObjectElement("ExperimenterGroups"); }
    public int countExperimenterGroups()
    { return countListElement("ExperimenterGroups"); }

    public List getGroupsByContact()
    { return (List) getObjectElement("GroupsByContact"); }
    public int countGroupsByContact()
    { return countListElement("GroupsByContact"); }

    public List getGroupsByLeader()
    { return (List) getObjectElement("GroupsByLeader"); }
    public int countGroupsByLeader()
    { return countListElement("GroupsByLeader"); }

    public List getImageAnnotations()
    { return (List) getObjectElement("ImageAnnotations"); }
    public int countImageAnnotations()
    { return countListElement("ImageAnnotations"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Group",GroupDTO.class);
        parseListElement("DatasetAnnotations",DatasetAnnotationDTO.class);
        parseListElement("Experiments",ExperimentDTO.class);
        parseListElement("ExperimenterGroups",ExperimenterGroupDTO.class);
        parseListElement("GroupsByContact",GroupDTO.class);
        parseListElement("GroupsByLeader",GroupDTO.class);
        parseListElement("ImageAnnotations",ImageAnnotationDTO.class);
    }

}
