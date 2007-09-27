/*
 * org.openmicroscopy.xml2007.OMEXMLNode
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2007 Open Microscopy Environment
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

package org.openmicroscopy.xml2007;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.Hashtable;
import java.util.Vector;
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
 * intuitive traversal of OME structures.
 */
public abstract class OMEXMLNode {

  // -- Static fields --

  /** Next free ID numbers for generating internal ID attribute values. */
  protected static Hashtable nextIds = new Hashtable();

  // -- Fields --

  /** Associated DOM element for this node. */
  protected Element element;

  // -- Constructor --

  /** Constructs an OME-XML node with the given associated DOM element. */
  public OMEXMLNode(Element element) {
    this.element = element;
    if (hasID() && getID() == null) {
      String name = getElementName();
      Integer id = (Integer) nextIds.get(name);
      int q = id == null ? 0 : id.intValue();
      setID("openmicroscopy.org:" + name + ":" + q);
      nextIds.put(name, new Integer(q + 1));
    }
  }

  // -- OMEXMLNode API methods --

  /** Gets the DOM element backing this OME-XML node. */
  public Element getDOMElement() { return element; }

  /** Gets whether this type of node should have an ID. */
  public abstract boolean hasID();

  /** Gets the ID for this node, or null if none. */
  public String getID() { return getAttribute("ID"); }

  /** Sets the ID for this node. */
  public void setID(String id) { setAttribute("ID", id); }

  /** Gets the name of the DOM element. */
  public String getElementName() { return DOMUtil.getName(element); }

  // -- Internal OMEXMLNode API methods --

  /** Gets the number of child elements with the given name. */
  protected int getChildCount(String name) {
    return getSize(DOMUtil.getChildElements(name, element));
  }

  /** Gets an OME-XML node representing the first child with the given name. */
  protected OMEXMLNode getChildNode(String name) {
    return createNode(DOMUtil.getChildElement(name, element));
  }

  /**
   * Gets an OME-XML node of the specified type
   * representing the first child with the given name.
   */
  protected OMEXMLNode getChildNode(String nodeType, String name) {
    return createNode(nodeType, DOMUtil.getChildElement(name, element));
  }

  /** Gets a list of OME-XML node children with the given name. */
  protected Vector getChildNodes(String name) {
    return createNodes(DOMUtil.getChildElements(name, element));
  }

  /** Gets the total number of child elements. */
  protected int getChildCount() {
    return getSize(DOMUtil.getChildElements(element));
  }

  /** Gets a list of all OME-XML node children. */
  protected Vector getChildNodes() {
    return createNodes(DOMUtil.getChildElements(element));
  }

  /**
   * Gets an OME-XML node of the given type representing the first
   * element referenced by a child element with the given name.
   *
   * For example, if this node is an ImageNode,
   * getReferencedNode("Pixels", "AcquiredPixelsRef") will return a
   * PixelsNode for the Pixels element whose ID matches the one given
   * by the AcquiredPixelsRef child element.
   */
  protected OMEXMLNode getReferencedNode(String nodeType, String refName) {
    Element ref = getChildElement(refName);
    if (ref == null) return null;
    Element el = findElement(nodeType, DOMUtil.getAttribute("ID", ref));
    return createNode(el);
  }

  /**
   * Gets a list of all OME-XML nodes of the given type representing
   * the elements referenced by the child elements with the given name.
   *
   * For example, if this node is an ImageNode,
   * getReferencedNodes("Dataset", "DatasetRef") will return a list of
   * DatasetNode objects for the Dataset elements whose IDs match the
   * ones given by the DatasetRef child elements.
   */
  protected Vector getReferencedNodes(String nodeType, String refName) {
    Vector refs = getChildElements(refName);
    if (refs == null) return null;
    Vector els = new Vector();
    for (int i=0; i<refs.size(); i++) {
      Element ref = (Element) refs.get(i);
      Element el = findElement(nodeType, DOMUtil.getAttribute("ID", ref));
      els.add(el);
    }
    return createNodes(els);
  }

  /**
   * Gets an OME-XML node of the given type representing the first
   * element referenced by an attribute with the given name.
   *
   * For example, if this node is an ImageNode,
   * getAttrReferencedNode("Pixels", "DefaultPixels") will return a
   * PixelsNode for the Pixels element whose ID matches the one given
   * by the DefaultPixels attribute.
   */
  protected OMEXMLNode getAttrReferencedNode(String nodeType, String attrName) {
    Element el = findElement(nodeType, getAttribute(attrName));
    return createNode(el);
  }

  /** Gets the given child node's character data. */
  protected String getCData(String name) {
    return DOMUtil.getCharacterData(getChildElement(name));
  }

  /** Sets the given child node's character data to the specified value. */
  protected void setCData(String name, String value) {
    DOMUtil.setCharacterData(value, getChildElement(name));
  }

  /**
   * Sets the given child node's character data
   * to the specified Object's string representation.
   */
  protected void setCData(String name, Object value) {
    DOMUtil.setCharacterData(value, getChildElement(name));
  }

  /**
   * Gets the given child node's character data as a Boolean,
   * or null if the value is not a boolean.
   */
  protected Boolean getBooleanCData(String name) {
    return DOMUtil.getBooleanCharacterData(getChildElement(name));
  }

  /**
   * Gets the given child node's character data as a Double,
   * or null if the value is not a double.
   */
  protected Double getDoubleCData(String name) {
    return DOMUtil.getDoubleCharacterData(getChildElement(name));
  }

  /**
   * Gets the given child node's character data as a Float,
   * or null if the value is not a float.
   */
  protected Float getFloatCData(String name) {
    return DOMUtil.getFloatCharacterData(getChildElement(name));
  }

  /**
   * Gets the given child node's character data as a Integer,
   * or null if the value is not an integer.
   */
  protected Integer getIntegerCData(String name) {
    return DOMUtil.getIntegerCharacterData(getChildElement(name));
  }

  /**
   * Gets the given child node's character data as a Long,
   * or null if the value is not a long.
   */
  protected Long getLongCData(String name) {
    return DOMUtil.getLongCharacterData(getChildElement(name));
  }

  /** Gets a list of all DOM element attribute names. */
  protected String[] getAttributeNames() {
    return DOMUtil.getAttributeNames(element);
  }

  /** Gets a list of all DOM element attribute values. */
  protected String[] getAttributeValues() {
    return DOMUtil.getAttributeValues(element);
  }

  /** Gets the value of the DOM element's attribute with the given name. */
  protected String getAttribute(String name) {
    return DOMUtil.getAttribute(name, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified value.
   */
  protected void setAttribute(String name, String value) {
    DOMUtil.setAttribute(name, value, element);
  }

  /**
   * Sets the value of the DOM element's attribute with the
   * given name to the specified Object's string representation.
   */
  protected void setAttribute(String name, Object value) {
    DOMUtil.setAttribute(name, value, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Boolean, or null if the value is not a boolean.
   */
  protected Boolean getBooleanAttribute(String name) {
    return DOMUtil.getBooleanAttribute(name, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Double, or null if the value is not a double.
   */
  protected Double getDoubleAttribute(String name) {
    return DOMUtil.getDoubleAttribute(name, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Float, or null if the value is not a float.
   */
  protected Float getFloatAttribute(String name) {
    return DOMUtil.getFloatAttribute(name, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as an Integer, or null if the value is not an integer.
   */
  protected Integer getIntegerAttribute(String name) {
    return DOMUtil.getIntegerAttribute(name, element);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Long, or null if the value is not a long.
   */
  protected Long getLongAttribute(String name) {
    return DOMUtil.getLongAttribute(name, element);
  }

  // -- Helper methods --

  /**
   * Creates an OME-XML node of the proper type
   * using the specified DOM element as a source.
   */
  private OMEXMLNode createNode(Element el) {
    if (el == null) return null;
    return createNode(DOMUtil.getName(el), el);
  }

  /**
   * Creates an OME-XML node of the given type,
   * using the specified DOM element as a source.
   */
  private OMEXMLNode createNode(String nodeType, Element el) {
    if (nodeType == null || el == null) return null;
    Class c = getClass(nodeType);
    if (c == null) {
      // CTR TODO wrap in generic node class?
      return null;
    }
    return createNode(c, el);
  }

  /**
   * Creates an OME-XML node of the given type,
   * using the specified DOM element as a source.
   */
  private OMEXMLNode createNode(Class nodeType, Element el) {
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
  private Vector createNodes(Vector els) {
    if (els == null) return null;
    int size = els.size();
    Vector nodes = new Vector(size);
    for (int i=0; i<size; i++) {
      Object o = (Object) els.elementAt(i);
      if (o instanceof Element) {
        Element el = (Element) o;
        OMEXMLNode node = createNode(el);
        if (node != null && nodes.indexOf(node) < 0) {
          nodes.addElement(node);
          continue;
        }
      }
      nodes.add(null);
    }
    return nodes;
  }

  /** Gets the first child DOM element with the specified name. */
  private Element getChildElement(String name) {
    return DOMUtil.getChildElement(name, element);
  }

  /** Gets a list of child DOM elements with the specified name. */
  private Vector getChildElements(String name) {
    return DOMUtil.getChildElements(name, element);
  }

  /** Finds the DOM element with the specified name and ID attribute value. */
  private Element findElement(String name, String id) {
    if (name == null || id == null) return null;
    return DOMUtil.findElement(name, "ID", id, element.getOwnerDocument());
  }

  /**
   * Gets the node class based on the given name from the class loader.
   * @return null if the class could not be loaded.
   */
  private Class getClass(String nodeName) {
    String pack = getClass().getPackage().getName();
    try {
      return Class.forName(pack + "." + nodeName + "Node");
    }
    catch (ClassNotFoundException exc) { }
    catch (NoClassDefFoundError err) { }
    catch (RuntimeException exc) {
      // HACK: workaround for bug in Apache Axis2
      String msg = exc.getMessage();
      if (msg != null && msg.indexOf("ClassNotFound") < 0) throw exc;
    }
    return null;
  }

  /** Gets the size of the vector. Returns 0 if the vector is null. */
  private int getSize(Vector v) { return v == null ? 0 : v.size(); }

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

}
