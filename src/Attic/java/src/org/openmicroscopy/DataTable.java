/*
 * org.openmicroscopy.DataTable
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy;

import java.util.List;
import java.util.Iterator;

/**
 * <p>The <code>DataTable</code> interface describes the database
 * tables used to store OME semantic types.  Note that there can be a
 * many-to-many relationship between semantic types and data tables.
 * Semantic types which are logically related can be stored in the
 * same database table, to help reduce the overhead of columns added
 * to each table by the analysis engine.  Further, semantic types
 * which can be broken into sparse distinct subparts can be stored in
 * separate tables to help reduce the sparsity of each data row.</p>
 *
 * <p>The actual mapping between semantic types and data tables occurs
 * as a link between semantic type columns and data table columns.
 * This link can be accessed via the {@link
 * SemanticType.Element#getDataColumn} method.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 * @see SemanticType
 */

public interface DataTable
    extends OMEObject
{
    /**
     * Returns the name of this data table.
     * @return the name of this data table.
     */
    public String getTableName();

    /**
     * Sets the name of this data table.
     * @param tableName the name of this data table.
     */
    public void setTableName(String tableName);

    /**
     * Returns a description of this data table.
     * @return a description of this data table.
     */
    public String getDescription();

    /**
     * Sets a human-helpful description of this data table.
     * @param description a human-helpful description of this data
     * table.
     */
    public void setDescription(String description);
        
    /**
     * Returns the granularity of this data table.  Note that all
     * semantic types which store values in this data table must have
     * the same granularity, and that granularity must match the
     * granularity of the data table.
     * @return the granularity of this data table.
     */
    public int getGranularity();

    /**
     * Sets the granularity of this data table.  Note that all
     * semantic types which store values in this data table must have
     * the same granularity, and that granularity must match the
     * granularity of the data table.
     * @param granularity the granularity of this data table.
     */
    public void setGranularity(int granularity);

    /**
     * Returns a list of the columns in this data table.
     * @return a {@link List} of {@link DataTable.Column Columns}
     */
    public List getColumns();

    /**
     * Returns an iterator of the columns in this data table.
     * @return an {@link Iterator} of {@link DataTable.Column Columns}
     */
    public Iterator iterateColumns();

    /**
     * <p>The <code>DataTable.Column</code> interface describes one
     * column in a data table.  There is a many-to-one map between
     * data columns and semantic elements.  If two semantic elements
     * live in the same data column, then two attributes must have the
     * same value for the respective elements in order to be able to
     * be stored in the same data row.</p>
     *
     * @author Douglas Creager
     * @version 2.0
     * @since OME2.0
     * @see SemanticType.Element
     */

    public interface Column
        extends OMEObject
    {
        /**
         * Returns the data table that this column belongs to.
         * @return the data table that this column belongs to.
         */
        public DataTable getDataTable();

        /**
         * Returns the name of this column.
         * @return the name of this column.
         */
        public String getColumnName();

        /**
         * Sets the name of this column.
         * @param columnName the name of this column.
         */
        public void setColumnName(String columnName);

        /**
         * Returns the description of this column.
         * @return the description of this column.
         */
        public String getColumnDescription();

        /**
         * Sets the description of this column.
         * @param columnDescription the description of this column.
         */
        public void setColumnDescription(String columnDescription);

        /**
         * Returns the SQL type of this column.
         * @return the SQL type of this column.
         */
        public String getSQLType();

        /**
         * Sets the SQL type of this column.
         * @param sqlType the SQL type of this column.
         */
        public void setSQLType(String sqlType);

        /**
         * Returns the semantic type of a reference element.  If this
         * column is not a reference element, the result is
         * unspecified.
         * @return the semantic type of a reference element.
         */
        public SemanticType getReferenceType();

        /**
         * Sets the semantic type of a reference element.
         * @param sqlType the semantic type of a reference element.
         */
        public void setReferenceType(SemanticType sqlType);
    }
}
