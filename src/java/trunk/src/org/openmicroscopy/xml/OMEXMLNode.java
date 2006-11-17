/*
 * org.openmicroscopy.xml.OMEXMLNode
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

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.Vector;
import org.openmicroscopy.ds.dto.DataInterface;
import org.w3c.dom.*;

/**
 * OMEXMLNode is the abstract superclass of all OME-XML nodes. These nodes are
 * similar to, but more sophisticated than, the nodes obtained from a direct
 * DOM parse of an OME-XML file. Every OME-XML node is backed by a
 * corresponding DOM element from the directly parsed XML, but not all DOM
 * elements have a corresponding OME-XML node; some (such as FirstName within
 * Experimenter) are implicit within more significant OME-XML nodes (e.g.,
 * ExperimenterNode). In general, it is not guaranteed that all DOM elements
 * and attributes be exposed through subclasses of OMEXMLNode, though the
 * intent is for the OMEXMLNode infrastructure to be as complete as possible.
 *
 * Subclasses of OMEXMLNode provide OME-specific functionality such as more
 * intuitive traversal of OME structures, achieved through implementation of
 * the org.openmicroscopy.ds.dto and org.openmicroscopy.ds.st interfaces
 * whenever possible.
 */
public abstract class OMEXMLNode implements DataInterface {

  // -- Constants --

  /** List of packages to check for ST interfaces. */
  protected static final String[] DTO_PACKAGES = {
    "org.openmicroscopy.ds.dto", "org.openmicroscopy.ds.st"
  };

  /** List of packages to check for ST nodes. */
  protected static final String[] NODE_PACKAGES = {
    "org.openmicroscopy.xml", "org.openmicroscopy.xml.st"
  };


  // -- Static fields --

  /** Next free ID number for generating internal ID attribute values. */
  protected static int nextId = 1;


  // -- Fields --

  /** Associated DOM element for this node. */
  protected Element element;


  // -- Constructor --

  /** Constructs an OME-XML node with the given associated DOM element. */
  public OMEXMLNode(Element element) {
    this.element = element;
    if (hasLSID() && getLSID() == null) setLSID("id" + nextId++);
  }


  // -- OMEXMLNode API methods --

  /** Gets the DOM element backing this OME-XML node. */
  public Element getDOMElement() { return element; }

  /** Gets whether this type of node should have an LSID. */
  public boolean hasLSID() { return true; }

  /** Gets the LSID for this node, or null if none. */
  public String getLSID() { return getAttribute("ID"); }

  /** Sets the LSID for this node. */
  public void setLSID(String lsid) { setAttribute("ID", lsid); }

  /** Gets the name of the DOM element. */
  public String getElementName() { return element.getTagName(); }

  /** Gets an OME-XML node representing the first child with the given name. */
  public OMEXMLNode getChild(String name) {
    return createNode(DOMUtil.getChildElement(name, element));
  }

  /** Gets a list of OME-XML node children with the given name. */
  public Vector getChildren(String name) {
    return createNodes(DOMUtil.getChildElements(name, element));
  }

  /** Gets a list of all DOM element attribute names. */
  public String[] getAttributeNames() {
    return DOMUtil.getAttributeNames(element);
  }

  /** Gets a list of all DOM element attribute values. */
  public String[] getAttributeValues() {
    return DOMUtil.getAttributeValues(element);
  }

  /** Gets the value of the DOM element's attribute with the given name. */
  public String getAttribute(String name) {
    return DOMUtil.getAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified value.
   */
  public void setAttribute(String name, String value) {
    DOMUtil.setAttribute(name, value, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Boolean, or null if the value is not a boolean.
   */
  public Boolean getBooleanAttribute(String name) {
    return DOMUtil.getBooleanAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Boolean.
   */
  public void setBooleanAttribute(String name, Boolean value) {
    DOMUtil.setBooleanAttribute(name, value, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Double, or null if the value is not a double.
   */
  public Double getDoubleAttribute(String name) {
    return DOMUtil.getDoubleAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Double.
   */
  public void setDoubleAttribute(String name, Double value) {
    DOMUtil.setDoubleAttribute(name, value, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Float, or null if the value is not a float.
   */
  public Float getFloatAttribute(String name) {
    return DOMUtil.getFloatAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public void setFloatAttribute(String name, Float value) {
    DOMUtil.setFloatAttribute(name, value, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as an Integer, or null if the value is not an integer.
   */
  public Integer getIntegerAttribute(String name) {
    return DOMUtil.getIntegerAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public void setIntegerAttribute(String name, Integer value) {
    DOMUtil.setIntegerAttribute(name, value, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Long, or null if the value is not a long.
   */
  public Long getLongAttribute(String name) {
    return DOMUtil.getLongAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public void setLongAttribute(String name, Long value) {
    DOMUtil.setLongAttribute(name, value, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Short, or null if the value is not a short.
   */
  public Short getShortAttribute(String name) {
    return DOMUtil.getShortAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public void setShortAttribute(String name, Short value) {
    DOMUtil.setShortAttribute(name, value, element);
  }


  // -- Object API methods --

  /**
   * Tests whether two OME-XML nodes are equal. Nodes are considered equal if
   * they are instances of the same class with the same backing DOM element.
   */
  public boolean equals(Object obj) {
    if (obj == null) return false;
    if (!obj.getClass().equals(getClass())) return false;
    return element.equals(((OMEXMLNode) obj).element);
  }

  /** Gets a string representation of this node. */
  public String toString() { return element.toString(); }


  // -- DataInterface API methods --

  /** Returns the name of the data type this object represents. */
  public String getDTOTypeName() {
    // extract the type name from the class name
    String className = getClass().getName();
    if (className.endsWith("Node")) {
      int dot = className.lastIndexOf(".");
      int len = className.length();
      return className.substring(dot + 1, len - 4);
    }
    return null;
  }

  /** Returns the interface class of the data type this object represents. */
  public Class getDTOType() {
    // search for the correct interface among the known packages
    String typeName = getDTOTypeName();
    for (int i=0; i<DTO_PACKAGES.length; i++) {
      String className = DTO_PACKAGES[i] + "." + typeName;
      try { return Class.forName(className); }
      catch (ClassNotFoundException exc) { }
    }
    return null;
  }


  // -- Internal OMEXMLNode API methods - DOM methods --

  /** Gets the first child DOM element with the specified name. */
  protected Element getChildElement(String name) {
    return DOMUtil.getChildElement(name, element);
  }

  /** Gets a list of child DOM elements with the specified name. */
  protected Vector getChildElements(String name) {
    return DOMUtil.getChildElements(name, element);
  }

  /** Gets the first ancestor DOM element with the specified name. */
  protected Element getAncestorElement(String name) {
    return DOMUtil.getAncestorElement(name, element);
  }

  /** Finds the DOM element with the specified name and ID attribute value. */
  protected Element findElement(String name, String id) {
    return findElement(name, id, element.getOwnerDocument());
  }

  /**
   * Gets a list of elements of a certain type (with the given name)
   * that refer to this OME-XML node using a child *Ref element.
   *
   * For example, if this node is a Project node and getReferrals("Dataset") is
   * called, it will search the DOM structure for Dataset elements with a child
   * ProjectRef element whose ID matches this Project node's LSID value.
   */
  protected Vector getReferrals(String name) {
    return getReferrals(name, getDTOTypeName() + "Ref");
  }

  /**
   * Gets a list of elements of a certain type (with the given name)
   * that refer to this OME-XML node using a child element (with name refName).
   *
   * For example, if this node is an Experimenter node and
   * getReferrals("ExperimenterGroup", "Contact") is called, it will search the
   * DOM structure for ExperimenterGroup elements with a child
   * Contact element whose ID matches this Experimenter node's LSID value.
   */
  protected Vector getReferrals(String name, String refName) {
    return getReferrals(name, refName, getLSID(), element.getOwnerDocument());
  }

  /**
   * Gets a list of elements of a certain type (with the given name)
   * that refer to this OME-XML node using an attribute.
   *
   * For example, if this node is a PixelsNode and
   * getAttrReferrals("ChannelComponent", "Pixels") is called, it will search
   * the DOM structure for ChannelComponent elements with a Pixels attribute
   * whose value matches this Pixels node's LSID value.
   */
  protected Vector getAttrReferrals(String name, String attrName) {
    return DOMUtil.findElementList(name,
      attrName, getLSID(), element.getOwnerDocument());
  }

  /**
   * Creates a reference element beneath this node.
   *
   * For example, if this node is a DatasetNode and "project" is a ProjectNode,
   * createReference(project) references the Project from this Dataset by
   * adding a child XML element called ProjectRef with an ID attribute matching
   * the ID of the referenced Project.
   */
  protected void createReference(OMEXMLNode node) {
    Element ref = DOMUtil.createChild(element, node.getDTOTypeName() + "Ref");
    DOMUtil.setAttribute("ID", node.getLSID(), ref);
  }


  // -- Internal OMEXMLNode API methods - OME-XML node methods --

  /**
   * Creates an OME-XML node of the given type, using the
   * first child DOM element with the given name as a source.
   */
  protected OMEXMLNode createChildNode(Class nodeType, String name) {
    return createNode(nodeType, getChildElement(name));
  }

  /**
   * Creates a list of OME-XML nodes of the given type, using the
   * list of child DOM elements with the given name as a source.
   */
  protected Vector createChildNodes(Class nodeType, String name) {
    return createNodes(nodeType, getChildElements(name));
  }

  /**
   * Creates an OME-XML node of the given type, using the
   * first ancestor DOM element with the given name as a source.
   */
  protected OMEXMLNode createAncestorNode(Class nodeType, String name) {
    return createNode(nodeType, getAncestorElement(name));
  }

  /**
   * Creates a list of OME-XML nodes of the given type, using the
   * list of referring DOM elements (via *Ref child element) with
   * the given name as a source.
   */
  protected Vector createReferralNodes(Class nodeType, String name) {
    return createNodes(nodeType, getReferrals(name));
  }

  /**
   * Creates a list of OME-XML nodes of the given type, using the
   * list of referring DOM elements with the given name and matching ID
   * attribute as a source.
   */
  protected Vector createAttrReferralNodes(Class nodeType,
    String name, String attrName)
  {
    return createNodes(nodeType, getAttrReferrals(name, attrName));
  }

  /**
   * Creates an OME-XML node of the given type, using the first
   * referenced DOM element with the given name as a source.
   */
  protected OMEXMLNode createReferencedNode(Class nodeType, String name) {
    Element ref = getChildElement(name + "Ref");
    if (ref == null) return null;
    Element el = findElement(name, DOMUtil.getAttribute("ID", ref));
    return createNode(nodeType, el);
  }

  /**
   * Creates an OME-XML node of the given type, using the first
   * DOM element with the given name, and referenced by the specified
   * attribute, as a source.
   */
  protected OMEXMLNode createReferencedNode(Class nodeType,
    String name, String attrName)
  {
    Element el = findElement(name, getAttribute(attrName));
    return createNode(nodeType, el);
  }

  /**
   * Creates a list of OME-XML nodes of the given type, using the
   * list of referenced DOM elements with the given name as a source.
   */
  protected Vector createReferencedNodes(Class nodeType, String name) {
    Vector refs = getChildElements(name + "Ref");
    if (refs == null) return null;
    Vector v = new Vector();
    int size = refs.size();
    for (int i=0; i<size; i++) {
      Element ref = (Element) refs.elementAt(i);
      Element el = findElement(name, DOMUtil.getAttribute("ID", ref));
      v.add(createNode(nodeType, el));
    }
    return v;
  }

  /**
   * Sets the referenced DOM element of a certain type (with the given name)
   * to match the specified node.
   */
  protected void setReferencedNode(OMEXMLNode node, String name) {
    if (node == null || name == null) return;

    Element ref = getChildElement(name + "Ref");
    if (node == null) element.removeChild(ref);
    else {
      // get new ID from the provided OMEXMLNode's DOM element
      String id = DOMUtil.getAttribute("ID", node.getDOMElement());

      // set *Ref element's ID attribute to match the new ID
      if (id != null) ref.setAttribute("ID", id);
    }
  }

  /**
   * Sets the DOM element of a certain type (with the given name), and
   * referenced by the specified attribute, to match the specified node.
   *
   * The name parameter is not actually used,
   * but should match node's element tag.
   */
  protected void setReferencedNode(OMEXMLNode node, String name,
    String attrName)
  {
    if (node == null || name == null || attrName == null) return;

    // get new ID from the provided OMEXMLNode's DOM element
    String id = DOMUtil.getAttribute("ID", node.getDOMElement());

    // set attribute's value to match the new ID
    if (id != null) setAttribute(attrName, id);
  }


  // -- Utility methods --

  /** Finds the DOM element with the specified name and ID attribute value. */
  public static Element findElement(String name, String id, Document doc) {
    return DOMUtil.findElement(name, "ID", id, doc);
  }

  /**
   * Gets a list of elements of a certain type (with the given name)
   * that refer to the element with the specified ID using a child element
   * (with name refName).
   */
  public static Vector getReferrals(String name,
    String refName, String id, Document doc)
  {
    if (name == null || refName == null || id == null) return null;
    Vector possible = DOMUtil.findElementList(name, doc);
    if (possible == null) return null;

    Vector v = new Vector();
    int psize = possible.size();
    for (int i=0; i<psize; i++) {
      Element el = (Element) possible.elementAt(i);
      Vector refs = DOMUtil.getChildElements(refName, el);
      int rsize = refs.size();
      boolean match = false;
      for (int j=0; j<rsize; j++) {
        Element ref = (Element) refs.elementAt(j);
        if (id.equals(DOMUtil.getAttribute("ID", ref))) {
          match = true;
          break;
        }
      }
      if (match) v.add(el);
    }
    return v;
  }

  /**
   * Creates an OME-XML node of the proper type
   * using the specified DOM element as a source.
   */
  public static OMEXMLNode createNode(Element el) {
    if (el == null) return null;

    // search for the correct OMEXMLNode subclass among the known packages
    String nodeName = el.getTagName() + "Node";
    for (int i=0; i<NODE_PACKAGES.length; i++) {
      try {
        Class c = Class.forName(NODE_PACKAGES[i] + "." + nodeName);
        return createNode(c, el);
      }
      catch (ClassNotFoundException exc) { }
    }

    // no subclass found; wrap element in generic CA type
    return new AttributeNode(el);
  }

  /**
   * Creates an OME-XML node of the given type,
   * using the specified DOM element as a source.
   */
  public static OMEXMLNode createNode(Class nodeType, Element el) {
    if (nodeType == null || el == null) return null;

    // node type must extend OMEXMLNode
    if (!OMEXMLNode.class.isAssignableFrom(nodeType)) return null;

    // construct a new instance of the given OMEXMLNode subclass
    try {
      Constructor con = nodeType.getConstructor(new Class[] {Element.class});
      return (OMEXMLNode) con.newInstance(new Object[] {el});
    }
    catch (IllegalAccessException exc) { }
    catch (InstantiationException exc) { }
    catch (InvocationTargetException exc) { }
    catch (NoSuchMethodException exc) { }
    return null;
  }

  /**
   * Creates a list of OME-XML nodes of the proper types,
   * using the specified list of DOM elements as a source.
   */
  public static Vector createNodes(Vector els) {
    if (els == null) return null;
    int size = els.size();
    Vector v = new Vector(size);
    for (int i=0; i<size; i++) {
      Object o = (Object) els.elementAt(i);
      if (o instanceof Element) {
        Element el = (Element) o;
        OMEXMLNode node = createNode(el);
        if (node != null && v.indexOf(node) < 0) v.addElement(node);
      }
    }
    return v;
  }

  /**
   * Creates a list of OME-XML nodes of the given type,
   * using the specified list of DOM elements as a source.
   */
  public static Vector createNodes(Class nodeType, Vector els) {
    if (nodeType == null || els == null) return null;
    int size = els.size();
    Vector v = new Vector(size);
    for (int i=0; i<size; i++) {
      Object o = (Object) els.elementAt(i);
      if (o instanceof Element) {
        Element el = (Element) o;
        OMEXMLNode node = createNode(nodeType, el);
        if (node != null && v.indexOf(node) < 0) v.addElement(node);
      }
    }
    return v;
  }

  /** Gets the size of the vector. Returns 0 if the vector is null. */
  public static int getSize(Vector v) { return v == null ? 0 : v.size(); }

}
