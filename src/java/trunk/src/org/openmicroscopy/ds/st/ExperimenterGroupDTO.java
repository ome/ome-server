/*
 * org.openmicroscopy.ds.st.ExperimenterGroupDTO
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
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.Group;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ExperimenterGroupDTO
    extends AttributeDTO
    implements ExperimenterGroup
{
    public ExperimenterGroupDTO() { super(); }
    public ExperimenterGroupDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@ExperimenterGroup"; }
    public Class getDTOType() { return ExperimenterGroup.class; }

    public Group getGroup()
    { return (Group) parseChildElement("Group",GroupDTO.class); }
    public void setGroup(Group value)
    { setElement("Group",value); }

    public Experimenter getExperimenter()
    { return (Experimenter) parseChildElement("Experimenter",ExperimenterDTO.class); }
    public void setExperimenter(Experimenter value)
    { setElement("Experimenter",value); }


}
