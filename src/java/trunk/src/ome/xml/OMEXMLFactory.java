/*
 * ome.xml.OMEXMLFactory
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

package ome.xml;

import java.io.*;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.xml.sax.SAXException;

/** OMEXMLFactory is a factory for creating OME-XML node hierarchies. */
public final class OMEXMLFactory {

  // -- Constants --

  /** Latest OME-XML version namespace. */
  public static final String LATEST_VERSION = "2007-06";

  /** Basic skeleton for an OME-XML node. */
  protected static final String SKELETON =
    "<?xml version=\"1.0\"?>\n" +
    "<OME xmlns=\"http://www.openmicroscopy.org/Schemas/OME/VERSION\" " +
    "xmlns:Bin=\"http://www.openmicroscopy.org/Schemas/BinaryFile/VERSION\" " +
    "xmlns:CA=\"http://www.openmicroscopy.org/Schemas/CA/VERSION\" " +
    "xmlns:STD=\"http://www.openmicroscopy.org/Schemas/STD/VERSION\" " +
    "xmlns:SPW=\"http://www.openmicroscopy.org/Schemas/SPW/VERSION\" " +
    "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
    "xsi:schemaLocation=\"" +
    "http://www.openmicroscopy.org/Schemas/OME/VERSION " +
    "http://www.openmicroscopy.org/Schemas/OME/VERSION/ome.xsd " +
    "http://www.openmicroscopy.org/Schemas/BinaryFile/VERSION " +
    "http://www.openmicroscopy.org/Schemas/BinaryFile/VERSION/BinaryFile.xsd " +
    "http://www.openmicroscopy.org/Schemas/CA/VERSION " +
    "http://www.openmicroscopy.org/Schemas/CA/VERSION/CA.xsd " +
    "http://www.openmicroscopy.org/Schemas/SPW/VERSION " +
    "http://www.openmicroscopy.org/Schemas/SPW/VERSION/SPW.xsd " +
    "http://www.openmicroscopy.org/Schemas/STD/VERSION " +
    "http://www.openmicroscopy.org/Schemas/STD/VERSION/STD.xsd\"/>";

  // -- Constructor --

  private OMEXMLFactory() { }

  // -- Static OMEXMLFactory API methods --

  /** Constructs a new, empty OME-XML root node of the latest schema version. */
  public static OMEXMLNode newOMENode()
    throws ParserConfigurationException, SAXException, IOException
  {
    return newOMENode(LATEST_VERSION);
  }

  /**
   * Constructs a new, empty OME-XML root node of the given schema version.
   * @param version The schema version (e.g., 2007-06) to use for the OME-XML.
   */
  public static OMEXMLNode newOMENode(String version)
    throws ParserConfigurationException, SAXException, IOException
  {
    return newOMENodeFromSource(SKELETON.replaceAll("VERSION", version));
  }

  /** Constructs an OME-XML root node from the given file on disk. */
  public static OMEXMLNode newOMENodeFromSource(File file)
    throws ParserConfigurationException, SAXException, IOException
  {
    return newOMENodeFromSource(parseOME(file));
  }

  /** Constructs an OME-XML root node from the given XML string. */
  public static OMEXMLNode newOMENodeFromSource(String xml)
    throws ParserConfigurationException, SAXException, IOException
  {
    return newOMENodeFromSource(parseOME(xml));
  }

  /** Constructs an OME-XML root node from the given DOM tree. */
  public static OMEXMLNode newOMENodeFromSource(Document doc) {
    final String legacy = "http://www.openmicroscopy.org/XMLschemas/";
    final String modern = "http://www.openmicroscopy.org/Schemas/OME/";

    Element el = doc.getDocumentElement();

    // parse schema version from xmlns attribute
    String xmlns = DOMUtil.getAttribute("xmlns", el);
    if (xmlns == null) return null;
    xmlns = xmlns.trim();
    if (xmlns.startsWith(legacy)) {
      // CTR TODO - this doesn't work, because by the time we get here, we
      // already have a DOM document that is not in OME-CA form, and the
      // 2003/FC OMENode does not like such documents. It assumes you are
      // giving it one in OME-CA form. Ideally, we'd pass the OMENode the
      // file handle or string in the appropriate newOMENodeFromSource method,
      // but at that point we do not yet know what kind of OME-XML block it is.
      // So we should feed it into a SAX parser to find out first, I guess.
      // Think about this some more...

      // legacy schema; use org.openmicroscopy.xml
      return new org.openmicroscopy.xml.OMENode(doc.getDocumentElement());
    }
    if (!xmlns.startsWith(modern)) return null; // unknown schema

    // modern schema; use ome.xml subpackage
    int len = modern.length();
    int slash = modern.indexOf("/", len);
    if (slash < 0) slash = xmlns.length();
    String version = xmlns.substring(len, slash).replaceAll("\\W", "");
    Object o = null;
    try {
      Class c = Class.forName("ome.xml.r" + version + ".ome.OMENode");
      Constructor con = c.getConstructor(new Class[] {Element.class});
      o = con.newInstance(new Object[] {el});
    }
    catch (ClassNotFoundException exc) { }
    catch (NoClassDefFoundError err) { }
    catch (NoSuchMethodException exc) { }
    catch (InstantiationException exc) { }
    catch (IllegalAccessException exc) { }
    catch (InvocationTargetException exc) { }
    if (o == null || !(o instanceof OMEXMLNode)) return null;

    return (OMEXMLNode) o;
  }

  // -- Utility methods --

  /** Parses a DOM from the given OME-XML file on disk. */
  public static Document parseOME(File file)
    throws ParserConfigurationException, SAXException, IOException
  {
    InputStream is = new FileInputStream(file);
    Document doc = parseOME(is);
    is.close();
    return doc;
  }

  /** Parses a DOM from the given OME-XML string. */
  public static Document parseOME(String xml)
    throws ParserConfigurationException, SAXException, IOException
  {
    byte[] bytes = xml.getBytes();
    InputStream is = new ByteArrayInputStream(bytes);
    Document doc = parseOME(is);
    is.close();
    return doc;
  }

  /** Parses a DOM from the given OME-XML input stream. */
  public static Document parseOME(InputStream is)
    throws ParserConfigurationException, SAXException, IOException
  {
    DocumentBuilder db = DOMUtil.DOC_FACT.newDocumentBuilder();
    return db.parse(is);
  }

}
