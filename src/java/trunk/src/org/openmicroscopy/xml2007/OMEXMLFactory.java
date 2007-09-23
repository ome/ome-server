/*
 * org.openmicroscopy.xml.OMEXMLFactory
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

import java.io.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.ParserConfigurationException;
import org.openmicroscopy.xml.DOMUtil;
import org.w3c.dom.Document;
import org.xml.sax.SAXException;

/** OMEXMLFactory is a factory for creating OME-XML node hierarchies. */
public final class OMEXMLFactory {

  // -- Constants --

  /** Basic skeleton for an OME-XML node. */
  protected static final String SKELETON =
    "<?xml version=\"1.0\"?>\n" +
    "<OME xmlns=\"http://www.openmicroscopy.org/Schemas/OME/2007-06\" " +
    "xmlns:CA=\"http://www.openmicroscopy.org/Schemas/CA/2007-06\" " +
    "xmlns:STD=\"http://www.openmicroscopy.org/Schemas/STD/2007-06\" " +
    "xmlns:Bin=\"http://www.openmicroscopy.org/Schemas/BinaryFile/2007-06\" " +
    "xmlns:SPW=\"http://www.openmicroscopy.org/Schemas/SPW/2007-06\" " +
    "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
    "xsi:schemaLocation=\"" +
    "http://www.openmicroscopy.org/Schemas/OME/2007-06 " +
    "http://www.openmicroscopy.org/Schemas/OME/2007-06/ome.xsd\"/>";

  // -- Constructor --

  private OMEXMLFactory() { }

  // -- Static OMEXMLFactory API methods --

  /** Constructs a new, empty OME-XML root node. */
  public static OMENode newOMEDocument()
    throws ParserConfigurationException, SAXException, IOException
  {
    return newOMEDocument(SKELETON);
  }

  /** Constructs a new OME-XML root node from the given file on disk. */
  public static OMENode newOMEDocument(File file)
    throws ParserConfigurationException, SAXException, IOException
  {
    return new OMENode(parseOME(file).getDocumentElement());
  }

  /** Constructs a new OME-XML root node from the given XML string. */
  public static OMENode newOMEDocument(String xml)
    throws ParserConfigurationException, SAXException, IOException
  {
    return new OMENode(parseOME(xml).getDocumentElement());
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

  // -- Helper methods --

  /** Parses a DOM from the given OME-XML or OMECA-XML input stream. */
  protected static Document parseOME(InputStream is)
    throws ParserConfigurationException, SAXException, IOException
  {
    DocumentBuilder db = DOMUtil.DOC_FACT.newDocumentBuilder();
    return db.parse(is);
  }

}
