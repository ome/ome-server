/*
 * org.openmicroscopy.ds.dto.LookupTableEntryDTO
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
 * Created by dcreager via omejava on Wed Feb 11 16:06:46 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class LookupTableEntryDTO
    extends MappedDTO
    implements LookupTableEntry
{
    public LookupTableEntryDTO() { super(); }
    public LookupTableEntryDTO(Map elements) { super(elements); }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public LookupTable getLookupTable()
    { return (LookupTable) getObjectElement("lookup_table"); }
    public void setLookupTable(LookupTable value)
    { setElement("lookup_table",value); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String value)
    { setElement("name",value); }

    public String getValue()
    { return getStringElement("value"); }
    public void setValue(String value)
    { setElement("value",value); }

    public String getLabel()
    { return getStringElement("label"); }
    public void setLabel(String value)
    { setElement("label",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("lookup_table",LookupTableDTO.class);
    }

}
