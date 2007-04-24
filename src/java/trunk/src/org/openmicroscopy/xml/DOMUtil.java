/*
 * org.openmicroscopy.xml.DOMUtil
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

import java.io.*;
import java.util.Vector;
import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import org.w3c.dom.*;
import org.xml.sax.SAXException;

/** DOMUtil contains useful functions for traversing and manipulating a DOM. */
public abstract class DOMUtil {

  // -- Static fields --

  /** Factory for generating transformers. */
  public static final TransformerFactory TRANS_FACT =
    TransformerFactory.newInstance();

  /** Factory for generating document builders. */
  public static final DocumentBuilderFactory DOC_FACT =
    DocumentBuilderFactory.newInstance();

  /** Factory for generating SAX parsers. */
  public static final SAXParserFactory SAX_FACT =
    SAXParserFactory.newInstance();


  // -- I/O and XSLT methods --

  /** Writes the specified DOM to the given output stream. */
  public static void writeXML(OutputStream os, Document doc)
    throws TransformerException
  {
    Transformer idTransform = TRANS_FACT.newTransformer();
    Source input = new DOMSource(doc);
    Result output = new StreamResult(os);
    idTransform.transform(input, output);
  }

  /**
   * Transforms the given XML input stream using
   * the specified cached XSLT stylesheet.
   */
  public static Document transform(Source source, Templates cachedXSLT)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    DocumentBuilder builder = DOC_FACT.newDocumentBuilder();
    Document document = builder.newDocument();
    Result result = new DOMResult(document);
    Transformer trans = cachedXSLT.newTransformer();
    trans.transform(source, result);
    return document;
  }

  /** Creates a cached XSLT stylesheet object. */
  public static Templates makeTemplates(String sheet)
    throws IOException, TransformerConfigurationException
  {
    InputStream in = OMENode.class.getResource(sheet).openStream();
    Templates t = TRANS_FACT.newTemplates(new StreamSource(in));
    in.close();
    return t;
  }


  // -- Element methods --

  /** Gets the character data corresponding to the given DOM element. */
  public static String getCharacterData(Element el) {
    Text text = getChildTextNode(el);
    return text == null ? null : text.getData();
  }

  /** Sets the character data corresponding to the given DOM element. */
  public static void setCharacterData(String data, Element el) {
    Text text = getChildTextNode(el);
    if (text != null) text.setData(data);
  }

  /**
   * Gets the child text node containing character data
   * for the given DOM element.
   */
  public static Text getChildTextNode(Element el) {
    if (el == null) return null;
    NodeList list = el.getChildNodes();
    int size = list.getLength();
    for (int i=0; i<size; i++) {
      Node node = list.item(i);
      if (!(node instanceof Text)) continue;
      return (Text) node;
    }
    return null;
  }

  /**
   * Gets the given element's first child DOM element with the specified name.
   */
  public static Element getChildElement(String name, Element el) {
    if (name == null || el == null) return null;
    NodeList list = el.getChildNodes();
    int size = list.getLength();
    for (int i=0; i<size; i++) {
      Node node = list.item(i);
      if (!(node instanceof Element)) continue;
      if (name.equals(node.getNodeName())) return (Element) node;
    }
    return null;
  }

  /** Gets a list of the given element's child DOM elements. */
  public static Vector getChildElements(Element el) {
    if (el == null) return null;
    Vector v = new Vector();
    NodeList list = el.getChildNodes();
    int size = list.getLength();
    for (int i=0; i<size; i++) {
      Node node = list.item(i);
      if (!(node instanceof Element)) continue;
      v.add(node);
    }
    return v;
  }

  /**
   * Gets a list of the given element's child DOM elements
   * with the specified name.
   */
  public static Vector getChildElements(String name, Element el) {
    if (name == null || el == null) return null;
    Vector v = new Vector();
    NodeList list = el.getChildNodes();
    int size = list.getLength();
    for (int i=0; i<size; i++) {
      Node node = list.item(i);
      if (!(node instanceof Element)) continue;
      if (name.equals(node.getNodeName())) v.add(node);
    }
    return v;
  }

  /**
   * Gets the given element's first ancestor DOM element
   * with the specified name.
   */
  public static Element getAncestorElement(String name, Element el) {
    if (name == null || el == null) return null;
    Node parent = el.getParentNode();
    while (parent != null && !name.equals(parent.getNodeName())) {
      parent = parent.getParentNode();
    }
    if (parent == null || (!(parent instanceof Element))) return null;
    return (Element) parent;
  }

  /** Finds the first DOM element with the specified name. */
  public static Element findElement(String name, Document doc) {
    return findElement(name, null, null, doc);
  }

  /**
   * Finds the first (breadth first) DOM element with the specified
   * name that has an attribute with the given name and value.
   */
  public static Element findElement(String name, String attrName,
    String attrValue, Document doc)
  {
    if (name == null) return null;
    NodeList list = doc.getElementsByTagName(name);
    int size = list.getLength();
    for (int i=0; i<size; i++) {
      Node node = list.item(i);
      if (!(node instanceof Element)) continue;
      Element el = (Element) node;
      if (attrName == null || attrValue == null ||
        attrValue.equals(getAttribute(attrName, el)))
      {
        return el;
      }
    }
    return null;
  }

  /**
   * Gets a list of DOM elements with the specified name throughout
   * the document (not just children of a specific element).
   */
  public static Vector findElementList(String name, Document doc) {
    return findElementList(name, null, null, doc);
  }

  /**
   * Gets a list of DOM elements with the specified name
   * that have an attribute with the given name and value.
   */
  public static Vector findElementList(String name, String attrName,
    String attrValue, Document doc)
  {
    if (name == null) return null;
    Vector v = new Vector();
    NodeList list = doc.getElementsByTagName(name);
    int size = list.getLength();
    for (int i=0; i<size; i++) {
      Node node = list.item(i);
      if (!(node instanceof Element)) continue;
      Element el = (Element) node;
      if (attrName == null || attrValue == null ||
        attrValue.equals(getAttribute(attrName, el)))
      {
        v.add(el);
      }
    }
    return v;
  }

  /**
   * Creates a child element with the given name beneath the specified element.
   */
  public static Element createChild(Element el, String name) {
    Element child = el.getOwnerDocument().createElement(name);
    el.appendChild(child);
    return child;
  }


  // -- Attribute methods --

  /** Gets a list of all attribute names for the given DOM element. */
  public static String[] getAttributeNames(Element el) {
    NamedNodeMap map = el.getAttributes();
    int len = map.getLength();
    String[] attrNames = new String[len];
    for (int i=0; i<len; i++) {
      Attr attr = (Attr) map.item(i);
      attrNames[i] = attr == null ? null : attr.getName();
    }
    return attrNames;
  }

  /** Gets a list of all attribute values for the given DOM element. */
  public static String[] getAttributeValues(Element el) {
    NamedNodeMap map = el.getAttributes();
    int len = map.getLength();
    String[] attrValues = new String[len];
    for (int i=0; i<len; i++) {
      Attr attr = (Attr) map.item(i);
      attrValues[i] = attr == null ? null : attr.getValue();
    }
    return attrValues;
  }

  /**
   * Gets the value of the given DOM element's attribute
   * with the specified name.
   */
  public static String getAttribute(String name, Element el) {
    if (name == null || el == null) return null;
    if (!el.hasAttribute(name)) return null;
    return el.getAttribute(name);
  }

  /**
   * Sets the value of the given DOM element's attribute
   * with the specified name to the given value.
   */
  public static void setAttribute(String name, String value, Element el) {
    if (name == null || value == null || el == null) return;

    // strip out invalid characters from the value
    char[] v = value.toCharArray();
    int count = 0;
    for (int i=0; i<v.length; i++) {
      if (!Character.isISOControl(v[i])) count++;
    }
    if (count < v.length) {
      char[] nv = new char[count];
      count = 0;
      for (int i=0; i<v.length; i++) {
        if (!Character.isISOControl(v[i])) nv[count++] = v[i];
      }
      value = new String(nv);
    }

    el.setAttribute(name, value);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Boolean, or null if the value is not a boolean.
   */
  public static Boolean getBooleanAttribute(String name, Element el) {
    String value = getAttribute(name, el);
    return value == null ? null : new Boolean(value.equalsIgnoreCase("true"));
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Boolean.
   */
  public static void setBooleanAttribute(String name, Boolean value,
    Element el)
  {
    if (value != null) {
      setAttribute(name, value.booleanValue() ? "true" : "false", el);
    }
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Double, or null if the value is not a double.
   */
  public static Double getDoubleAttribute(String name, Element el) {
    String value = getAttribute(name, el);
    Double q;
    try { q = value == null ? null : new Double(value); }
    catch (NumberFormatException exc) { q = null; }
    return q;
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Double.
   */
  public static void setDoubleAttribute(String name, Double value,
    Element el)
  {
    if (value != null) setAttribute(name, value.toString(), el);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Float, or null if the value is not a float.
   */
  public static Float getFloatAttribute(String name, Element el) {
    String value = getAttribute(name, el);
    Float q;
    try { q = value == null ? null : new Float(value); }
    catch (NumberFormatException exc) { q = null; }
    return q;
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public static void setFloatAttribute(String name, Float value,
    Element el)
  {
    if (value != null) setAttribute(name, value.toString(), el);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as an Integer, or null if the value is not an integer.
   */
  public static Integer getIntegerAttribute(String name, Element el) {
    String value = getAttribute(name, el);
    Integer q;
    try { q = value == null ? null : new Integer(value); }
    catch (NumberFormatException exc) { q = null; }
    return q;
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public static void setIntegerAttribute(String name, Integer value,
    Element el)
  {
    if (value != null) setAttribute(name, value.toString(), el);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Long, or null if the value is not a long.
   */
  public static Long getLongAttribute(String name, Element el) {
    String value = getAttribute(name, el);
    Long q;
    try { q = value == null ? null : new Long(value); }
    catch (NumberFormatException exc) { q = null; }
    return q;
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public static void setLongAttribute(String name, Long value, Element el) {
    if (value != null) setAttribute(name, value.toString(), el);
  }

  /**
   * Gets the value of the DOM element's attribute with the given name
   * as a Short, or null if the value is not a short.
   */
  public static Short getShortAttribute(String name, Element el) {
    String value = getAttribute(name, el);
    Short q;
    try { q = value == null ? null : new Short(value); }
    catch (NumberFormatException exc) { q = null; }
    return q;
  }

  /**
   * Sets the value of the DOM element's attribute with the given name
   * to the specified Float.
   */
  public static void setShortAttribute(String name, Short value,
    Element el)
  {
    if (value != null) setAttribute(name, value.toString(), el);
  }

}
