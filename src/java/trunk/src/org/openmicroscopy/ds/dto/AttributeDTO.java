/*
 * org.openmicroscopy.ds.dto.AttributeDTO
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

import java.util.Map;
import org.openmicroscopy.ds.DataException;

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
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 * @see SemanticType
 */

public class AttributeDTO
    extends MappedDTO
    implements Attribute
{
    public AttributeDTO() { super(); }
    public AttributeDTO(Map elements) { super(elements); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("dataset",DatasetDTO.class);
        parseChildElement("image",ImageDTO.class);
        parseChildElement("feature",FeatureDTO.class);
        parseChildElement("semantic_type",SemanticTypeDTO.class);
        parseChildElement("module_execution",ModuleExecutionDTO.class);
    }

    // Inherited javadoc
    public String getDTOTypeName()
    {
        try
        {
            return "@"+getSemanticType().getName();
        } catch (DataException e) {
            return "Unknown";
        }
    }

    // Inherited javadoc
    public Class getDTOType() { return Attribute.class; }

    // Inherited javadoc
    public int getID()
    { return getIntElement("id"); }

    // Inherited javadoc
    public SemanticType getSemanticType()
    { return (SemanticType) getObjectElement("semantic_type"); }

    // Inherited javadoc
    public Dataset getDataset()
    { return (Dataset) getObjectElement("dataset"); }

    // Inherited javadoc
    public void setDataset(Dataset dataset)
    { setElement("dataset",dataset); }

    // Inherited javadoc
    public Image getImage()
    { return (Image) getObjectElement("image"); }

    // Inherited javadoc
    public void setImage(Image image)
    { setElement("image",image); }

    // Inherited javadoc
    public Feature getFeature()
    { return (Feature) getObjectElement("feature"); }

    // Inherited javadoc
    public void setFeature(Feature feature)
    { setElement("feature",feature); }

    // Inherited javadoc
    public ModuleExecution getModuleExecution()
    { return (ModuleExecution) getObjectElement("module_execution"); }

    // Inherited javadoc
    public void setModuleExecution(ModuleExecution mex)
    { setElement("module_execution",mex); }

    /**
     * Ensures that this attribute has the given semantic type.  If
     * not, an exception is thrown.
     * @param type the semantic type to verify
     * @throws ClassCastException if this attribute is not of semantic
     * type <code>type</code>
     */
    public void verifySemanticType(SemanticType type) {}

    /**
     * Ensures that this attribute has the given semantic type.  If
     * not, an exception is thrown.  The semantic type is specified by
     * name, and is retrieved using the same method that retrieved
     * this attribute.
     * @param typeName the name of the semantic type to verify
     * @throws ClassCastException if this attribute is not of semantic
     * type <code>type</code>
     */
    public void verifySemanticType(String typeName) {}

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>boolean</code>.
     * @param element the name of the element to retrieve
     * @return the <code>boolean</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>boolean</code> value
     */
    public Boolean getBooleanElement(String element)
    { return super.getBooleanElement(element); }

    /**
     * Returns the value of one of the attribute's elements as an
     * <code>short</code>.
     * @param element the name of the element to retrieve
     * @return the <code>short</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain an
     * <code>short</code> value
     */
    public Short getShortElement(String element)
    { return super.getShortElement(element); }

    /**
     * Returns the value of one of the attribute's elements as an
     * <code>int</code>.
     * @param element the name of the element to retrieve
     * @return the <code>int</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain an
     * <code>int</code> value
     */
    public Integer getIntegerElement(String element)
    { return super.getIntegerElement(element); }

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>long</code>.
     * @param element the name of the element to retrieve
     * @return the <code>long</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>long</code> value
     */
    public Long getLongElement(String element)
    { return super.getLongElement(element); }

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>float</code>.
     * @param element the name of the element to retrieve
     * @return the <code>float</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>float</code> value
     */
    public Float getFloatElement(String element)
    { return super.getFloatElement(element); }

    /**
     * Returns the value of one of the attribute's elements as a
     * <code>double</code>.
     * @param element the name of the element to retrieve
     * @return the <code>double</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * <code>double</code> value
     */
    public Double getDoubleElement(String element)
    { return super.getDoubleElement(element); }

    /**
     * Returns the value of one of the attribute's elements as a
     * {@link String}.
     * @param element the name of the element to retrieve
     * @return the <code>String</code> value of <code>element</code>
     * @throws ClassCastException if the element does not contain a
     * {@link String} value
     */
    public String getStringElement(String element)
    { return super.getStringElement(element); }

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>boolean</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setBooleanElement(String element, Boolean value)
    { setElement(element,value); }

    /**
     * Sets the value of one of the attribute's elements to an
     * <code>short</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setShortElement(String element, Short value)
    { setElement(element,value); }

    /**
     * Sets the value of one of the attribute's elements to an
     * <code>int</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setIntegerElement(String element, Integer value)
    { setElement(element,value); }

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>long</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setLongElement(String element, Long value)
    { setElement(element,value); }

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>float</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setFloatElement(String element, Float value)
    { setElement(element,value); }

    /**
     * Sets the value of one of the attribute's elements to a
     * <code>double</code> value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setDoubleElement(String element, Double value)
    { setElement(element,value); }

    /**
     * Sets the value of one of the attribute's elements to a
     * {@link String} value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setStringElement(String element, String value)
    { setElement(element,value); }

    /**
     * Returns the value of one of the attribute's elements as an
     * {@link Attribute}.
     * @param element the name of the element to retrieve
     * @return the {@link Attribute} value of <code>element</code>
     * @throws ClassCastException if the element does not contain an
     * {@link Attribute} value
     */
    public Attribute getAttributeElement(String element)
    {
        Object value = getObjectElement(element);
        if (value == null)
        {
            return null;
        } else if (value instanceof Attribute) {
            return (Attribute) value;
        } else if (value instanceof Map) {
            Map map = (Map) value;
            AttributeDTO attr = new AttributeDTO(map);
            setElement(element,attr);
            return attr;
        } else {
            throw new DataException("Invalid type for attribute element "+
                                    value.getClass());
        }
    }

    /**
     * Sets the value of one of the attribute's elements to a
     * {@link Attribute} value.
     * @param element the name of the element to set
     * @param value the element's new value
     */
    public void setAttributeElement(String element, Attribute value)
    { setElement(element,value); }
}
