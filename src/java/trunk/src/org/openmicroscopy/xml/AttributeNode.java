/*
 * org.openmicroscopy.xml.AttributeNode
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2006 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee,
 *      University of Wisconsin-Madison
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
 *-----------------------------------------------------------------------------
 */


/*-----------------------------------------------------------------------------
 *
 * Written by:    Curtis Rueden <ctrueden@wisc.edu>
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml;

import org.openmicroscopy.ds.dto.*;
import org.w3c.dom.Element;

/**
 * AttributeNode is the superclass of nodes (semantic types) implementing the
 * Attribute DTO interface. It can also be used for custom semantic types that
 * do not have an explicit implementation in org.openmicroscopy.xml.st.
 */
public class AttributeNode extends OMEXMLNode implements Attribute {

  // -- Constructors --

  /** Constructs an attribute node with the given associated DOM element. */
  public AttributeNode(Element element) { super(element); }

  /**
   * Constructs an attribute node with the given element name,
   * creating its associated DOM element beneath the given parent.
   */
  public AttributeNode(CustomAttributesNode parent, String name) {
    this(parent, name, true);
  }

  /**
   * Constructs an attribute node with the given element name,
   * creating its associated DOM element beneath the given parent.
   */
  public AttributeNode(CustomAttributesNode parent, String name,
    boolean attach)
  {
    super(parent.getDOMElement().getOwnerDocument().
      createElement(name));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  // -- Attribute API methods --

  /** Returns -1. Primary key IDs are not applicable for external OME-XML. */
  public int getID() { return -1; }

  /** Gets the semantic type of this attribute. Always returns null. */
  public SemanticType getSemanticType() { return null; }

  /**
   * Returns the target of this attribute, assuming it has dataset granularity,
   * or null if the attribute does not have dataset granularity.
   */
  public Dataset getDataset() {
    return (Dataset) createAncestorNode(DatasetNode.class, "Dataset");
  }

  /**
   * Sets the target of this attribute, assuming that the semantic
   * type has dataset granularity.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of DatasetNode
   */
  public void setDataset(Dataset dataset) {
    ((OMEXMLNode) dataset).getDOMElement().appendChild(element);
  }

  /**
   * Returns the target of this attribute, assuming it has image granularity,
   * or null if the attribute does not have image granularity.
   */
  public Image getImage() {
    return (Image) createAncestorNode(ImageNode.class, "Image");
  }

  /**
   * Sets the target of this attribute, assuming that the semantic
   * type has image granularity.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of ImageNode
   */
  public void setImage(Image image) {
    ((OMEXMLNode) image).getDOMElement().appendChild(element);
  }

  /**
   * Returns the target of this attribute, assuming it has feature granularity,
   * or null if the attribute does not have feature granularity.
   */
  public Feature getFeature() {
    return (Feature) createAncestorNode(FeatureNode.class, "Feature");
  }

  /**
   * Sets the target of this attribute, assuming that the semantic
   * type has feature granularity.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of FeatureNode
   */
  public void setFeature(Feature feature) {
    ((OMEXMLNode) feature).getDOMElement().appendChild(element);
  }

  // NB: The following methods are not applicable to OME-XML and do nothing.
  public ModuleExecution getModuleExecution() { return null; }
  public void setModuleExecution(ModuleExecution mex) { }
  public void verifySemanticType(SemanticType type) { }
  public void verifySemanticType(String typeName) { }
  public Boolean getBooleanElement(String element) { return null; }
  public void setBooleanElement(String element, Boolean value) { }
  public Short getShortElement(String element) { return null; }
  public void setShortElement(String element, Short value) { }
  public Integer getIntegerElement(String element) { return null; }
  public void setIntegerElement(String element, Integer value) { }
  public Long getLongElement(String element) { return null; }
  public void setLongElement(String element, Long value) { }
  public Float getFloatElement(String element) { return null; }
  public void setFloatElement(String element, Float value) { }
  public Double getDoubleElement(String element) { return null; }
  public void setDoubleElement(String element, Double value) { }
  public String getStringElement(String element) { return null; }
  public void setStringElement(String element, String value) { }
  public Attribute getAttributeElement(String element) { return null; }
  public void setAttributeElement(String element, Attribute value) { }

}
