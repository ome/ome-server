/*
 * org.openmicroscopy.ds.dto.Attribute
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.ds.dto;

/**
 * <p>Represents a piece of semantically-typed data in OME.  This
 * includes attributes created by the user during image import, and
 * any attributes created as output by the execution of analysis
 * modules.</p>
 *
 * <p>Each attribute has a single semantic type, which is represented
 * by an instance of {@link SemanticType}.  Based on the semantic
 * type's granularity, the attribute will be a property of (or,
 * equivalently, has a target of) a dataset, image, or feature, or it
 * will be a global attribute (and have a target of
 * <code>null</code>.)</p>
 *
 * <p>Most attributes will be generated computationally as the result
 * of an analysis module.  The analysis (and by extension, module)
 * which generated the attribute can be retrieved with the {@link
 * #getModuleExecution()} method.</p>
 *
 * @author Douglas Creager
 * @version 2.0 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.0
 * @see SemanticType
 */

public interface Attribute
    extends DataInterface
{
    /**
     * Returns the attribute's primary key ID.
     * @return the attribute's primary key ID.
     */
    public int getID();

    /**
     * Returns the semantic type of this attribute.
     * @return the semantic type of this attribute.
     */
    public SemanticType getSemanticType();

    /**
     * Returns the target of this attribute, assuming that the
     * semantic type has dataset granularity.
     * @return the target of this attribute
     * @throws ClassCastException if the attribute does not have
     * dataset granularity
     */
    public Dataset getDataset();

    /**
     * Sets the target of this attribute, assuming that the semantic
     * type has dataset granularity.
     * @param dataset the target of this attribute
     */
    public void setDataset(Dataset dataset);

    /**
     * Returns the target of this attribute, assuming that the
     * semantic type has image granularity.
     * @return the target of this attribute
     * @throws ClassCastException if the attribute does not have
     * image granularity
     */
    public Image getImage();

    /**
     * Sets the target of this attribute, assuming that the semantic
     * type has image granularity.
     * @param image the target of this attribute
     */
    public void setImage(Image image);

    /**
     * Returns the target of this attribute, assuming that the
     * semantic type has feature granularity.
     * @return the target of this attribute
     * @throws ClassCastException if the attribute does not have
     * feature granularity
     */
    public Feature getFeature();

    /**
     * Sets the target of this attribute, assuming that the semantic
     * type has feature granularity.
     * @param feature the target of this attribute
     */
    public void setFeature(Feature feature);

    /**
     * Returns the analysis that generated this attribute.  If this
     * attribute was entered by the user, it will be
     * <code>null</code>.
     * @return the analysis that generated this attribute.
     */
    public ModuleExecution getModuleExecution();

    /**
     * Sets the analysis that generated this attribute.  If this
     * attribute was entered by the user, it should be
     * <code>null</code>.
     * @param mex the analysis that generated this attribute.
     */
    public void setModuleExecution(ModuleExecution mex);

    /**
     * Ensures that this attribute has the given semantic type.  If
     * not, an exception is thrown.
     * @param type the semantic type to verify
     * @throws ClassCastException if this attribute is not of semantic
     * type <code>type</code>
     */
    public void verifySemanticType(SemanticType type);

    /**
     * Ensures that this attribute has the given semantic type.  If
     * not, an exception is thrown.  The semantic type is specified by
     * name, and is retrieved using the same method that retrieved
     * this attribute.
     * @param typeName the name of the semantic type to verify
     * @throws ClassCastException if this attribute is not of semantic
     * type <code>type</code>
     */
    public void verifySemanticType(String typeName);

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>boolean</code>.
     * @param element the name of the element to retrieve
     * @return the <code>boolean</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>boolean</code> value
     */
    public Boolean getBooleanElement(String element);

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>boolean</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setBooleanElement(String element, Boolean value);

    /**
     * Returns the value of one of the attribute's elements as an
     * <code>int</code>.
     * @param element the name of the element to retrieve
     * @return the <code>int</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain an
     * <code>int</code> value
     */
    public Integer getIntegerElement(String element);

    /**
     * Sets the value of one of the attribute's elements to an
     * <code>int</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setIntegerElement(String element, Integer value);

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>long</code>.
     * @param element the name of the element to retrieve
     * @return the <code>long</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>long</code> value
     */
    public Long getLongElement(String element);

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>long</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setLongElement(String element, Long value);

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>float</code>.
     * @param element the name of the element to retrieve
     * @return the <code>float</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>float</code> value
     */
    public Float getFloatElement(String element);

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>float</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setFloatElement(String element, Float value);

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>double</code>.
     * @param element the name of the element to retrieve
     * @return the <code>double</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>double</code> value
     */
    public Double getDoubleElement(String element);

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>double</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setDoubleElement(String element, Double value);

    /**
     * Returns the value of one of the attribute's elements as a
     * {@link String}.
     * @param element the name of the element to retrieve
     * @return the <code>String</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * {@link String} value
     */
    public String getStringElement(String element);

    /**
     * Sets the value of one of the attribute's elements to a
     * {@link String} value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setStringElement(String element, String value);

    /**
     * Returns the value of one of the attribute's elements as an
     * {@link Attribute}.
     * @param element the name of the element to retrieve
     * @return the {@link Attribute} value of <code>element</code>
     * @throws ClassCastException if the element does not contain an
     * {@link Attribute} value
     */
    public Attribute getAttributeElement(String element);

    /**
     * Sets the value of one of the attribute's elements to a
     * {@link Attribute} value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setAttributeElement(String element, Attribute value);
}
