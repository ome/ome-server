/*
 * org.openmicroscopy.ds.dto.DataColumnDTO
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
 * Created by dcreager via omejava on Mon Apr  5 12:32:59 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class DataColumnDTO
    extends MappedDTO
    implements DataColumn
{
    public DataColumnDTO() { super(); }
    public DataColumnDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "DataColumn"; }
    public Class getDTOType() { return DataColumn.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public DataTable getDataTable()
    { return (DataTable) getObjectElement("data_table"); }
    public void setDataTable(DataTable value)
    { setElement("data_table",value); }

    public String getColumnName()
    { return getStringElement("column_name"); }
    public void setColumnName(String value)
    { setElement("column_name",value); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String value)
    { setElement("description",value); }

    public String getSQLType()
    { return getStringElement("sql_type"); }
    public void setSQLType(String value)
    { setElement("sql_type",value); }

    public SemanticType getReferenceType()
    { return (SemanticType) getObjectElement("reference_semantic_type"); }
    public void setReferenceType(SemanticType value)
    { setElement("reference_semantic_type",value); }

    public List getColumns()
    { return (List) getObjectElement("columns"); }
    public int countColumns()
    { return countListElement("columns"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("data_table",DataTableDTO.class);
        parseChildElement("reference_semantic_type",SemanticTypeDTO.class);
        parseListElement("columns",DataColumnDTO.class);
    }

}
