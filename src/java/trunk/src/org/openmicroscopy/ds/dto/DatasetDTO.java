/*
 * org.openmicroscopy.ds.dto.DatasetDTO
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
 * Created by dcreager via omejava on Thu Feb 12 14:34:47 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterDTO;
import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class DatasetDTO
    extends MappedDTO
    implements Dataset
{
    public DatasetDTO() { super(); }
    public DatasetDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "Dataset"; }
    public Class getDTOType() { return Dataset.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String value)
    { setElement("name",value); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String value)
    { setElement("description",value); }

    public Experimenter getOwner()
    { return (Experimenter) getObjectElement("owner"); }
    public void setOwner(Experimenter value)
    { setElement("owner",value); }

    public List getProjects()
    { return (List) getObjectElement("projects"); }
    public int countProjects()
    { return countListElement("projects"); }

    public List getImages()
    { return (List) getObjectElement("images"); }
    public int countImages()
    { return countListElement("images"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("owner",ExperimenterDTO.class);
        parseListElement("projects",ProjectDTO.class);
        parseListElement("images",ImageDTO.class);
    }

}
