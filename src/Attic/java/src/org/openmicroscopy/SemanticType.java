/*
 * org.openmicroscopy.SemanticType
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
 * <p>The <code>SemanticType</code> interface describes the semantic
 * types known to OME.  A semantic type is similar to a record or
 * class in standard programming languages, in that is has a list of
 * columns (or <i>semantic elements</i>) which contain the actual data
 * of the attribute.  These elements are represented by instance of
 * {@link SemanticType.Element}.</p>
 *
 * <p>Semantic types also define, indirectly, where in the OME
 * database their data is stored.  This information is represented by
 * instances of {@link DataTable} and {@link DataTable.Column}
 * classes, and can be accessed via the {@link
 * SemanticType.Element#getDataColumn()} method of {@link
 * SemanticType.Element}.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 * @see DataTable
 */

public interface SemanticType
    extends OMEObject
{
    /**
     * Returns the name of this semantic type.
     * @return the name of this semantic type.
     */
    public String getName();

    /**
     * Sets the name of this semantic type.
     * @param name the name of this semantic type.
     */
    public void setName(String name);

    /**
     * Returns the description of this semantic type.
     * @return the description of this semantic type.
     */
    public String getDescription();

    /**
     * Sets the description of this semantic type.
     * @param description the description of this semantic type.
     */
    public void setDescription(String description);

    /**
     * Returns the granularity of this semantic type.  Will be one of
     * the values defined in {@link Granularity}.
     * @return the granularity of this semantic type.
     */
    public int getGranularity();

    /**
     * Sets the granularity of this semantic type.  Must be one of the
     * values defined in {@link Granularity}.
     * @param granularity the granularity of this semantic type
     * @throws IllegalArgumentException if <code>granularity</code> is
     * not one of the values defined in {@link Granularity}.
     */
    public void setGranularity(int granularity);

    /**
     * Returns a list of elements in this semantic type.
     * @return a {@link List} of {@link SemanticType.Element Elements}
     */
    public List getElements();

    /**
     * Returns an iterator of elements in this semantic type.
     * @return an {@link Iterator} of {@link SemanticType.Element
     * Elements}
     */
    public Iterator iterateElements();

    /**
     * <p>This <code>SemanticType.Element</code> interface represents
     * one element of a semantic type.  The storage type of the
     * element can be accessed via the element's data column:</p>
     *
     * <pre>
     *    DataTable.Column dataColumn = semanticElement.getDataColumn();
     *    String sqlType = dataColumn.getSQLType();
     * </pre>
     *
     * @author Douglas Creager
     * @version 2.0
     * @since OME2.0
     * @see DataTable.Column
     */

    public interface Element
        extends OMEObject
    {
        /**
         * Returns the semantic type that this element belongs to.
         * @return the semantic type that this element belongs to.
         */
        public SemanticType getSemanticType();

        /**
         * Returns the name of this semantic element.
         * @return the name of this semantic element.
         */
        public String getElementName();

        /**
         * Sets the name of this semantic element.
         * @param elementName the name of this semantic element.
         */
        public void setElementName(String elementName);

        /**
         * Returns the description of this semantic element.
         * @return the description of this semantic element.
         */
        public String getElementDescription();

        /**
         * Sets the description of this semantic element.
         * @param elementDescription the description of this semantic
         * element.
         */
        public void setElementDescription(String elementDescription);

        /**
         * Returns the data column associated with this semantic
         * element.  The data column specifies where in the OME
         * database this element is stored, and what its storage type
         * is.
         * @return the data column associated with this semantic
         * element.
         */
        public DataTable.Column getDataColumn();

        /**
         * Sets the data column associated with this semantic element.
         * @param dataColumn the data column associated with this
         * semantic element.
         */
        public void setDataColumn(DataTable.Column dataColumn);
    }
}
