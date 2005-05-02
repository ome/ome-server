/*
 * org.openmicroscopy.ds.dto.DataColumn
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
 * Created by callan via omejava on Fri Dec 17 12:53:45 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface DataColumn
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>data_table</code> */
    public DataTable getDataTable();
    public void setDataTable(DataTable value);

    /** Criteria field name: <code>column_name</code> */
    public String getColumnName();
    public void setColumnName(String value);

    /** Criteria field name: <code>description</code> */
    public String getDescription();
    public void setDescription(String value);

    /** Criteria field name: <code>sql_type</code> */
    public String getSQLType();
    public void setSQLType(String value);

    /** Criteria field name: <code>reference_semantic_type</code> */
    public SemanticType getReferenceType();
    public void setReferenceType(SemanticType value);

    /** Criteria field name: <code>columns</code> */
    public List getColumns();
    /** Criteria field name: <code>#columns</code> or <code>columns</code> */
    public int countColumns();

}
