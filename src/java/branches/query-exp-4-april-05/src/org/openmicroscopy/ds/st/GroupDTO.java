/*
 * org.openmicroscopy.ds.st.GroupDTO
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
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterGroup;
import org.openmicroscopy.ds.st.ImageGroup;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class GroupDTO
    extends AttributeDTO
    implements Group
{
    public GroupDTO() { super(); }
    public GroupDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Group"; }
    public Class getDTOType() { return Group.class; }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public Experimenter getLeader()
    { return (Experimenter) parseChildElement("Leader",ExperimenterDTO.class); }
    public void setLeader(Experimenter value)
    { setElement("Leader",value); }

    public Experimenter getContact()
    { return (Experimenter) parseChildElement("Contact",ExperimenterDTO.class); }
    public void setContact(Experimenter value)
    { setElement("Contact",value); }

    public List getExperimenterList()
    { return (List) parseListElement("ExperimenterList",ExperimenterDTO.class); }
    public int countExperimenterList()
    { return countListElement("ExperimenterList"); }

    public List getExperimenterGroupList()
    { return (List) parseListElement("ExperimenterGroupList",ExperimenterGroupDTO.class); }
    public int countExperimenterGroupList()
    { return countListElement("ExperimenterGroupList"); }

    public List getImageGroupList()
    { return (List) parseListElement("ImageGroupList",ImageGroupDTO.class); }
    public int countImageGroupList()
    { return countListElement("ImageGroupList"); }


}
