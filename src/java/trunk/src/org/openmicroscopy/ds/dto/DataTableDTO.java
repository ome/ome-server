/*
 * org.openmicroscopy.ds.dto.DataTableDTO
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
 * Created by dcreager via omejava on Wed Feb 18 17:57:24 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class DataTableDTO
    extends MappedDTO
    implements DataTable
{
    public DataTableDTO() { super(); }
    public DataTableDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "DataTable"; }
    public Class getDTOType() { return DataTable.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public String getTableName()
    { return getStringElement("table_name"); }
    public void setTableName(String value)
    { setElement("table_name",value); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String value)
    { setElement("description",value); }

    public String getGranularity()
    { return getStringElement("granularity"); }
    public void setGranularity(String value)
    { setElement("granularity",value); }

    public List getColumns()
    { return (List) getObjectElement("columns"); }
    public int countColumns()
    { return countListElement("columns"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseListElement("columns",DataColumnDTO.class);
    }

}