/*
 * org.openmicroscopy.xml.OMENode
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
import java.util.List;
import java.util.Vector;
import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.StreamSource;
//import javax.xml.transform.dom.DOMSource;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.xml.sax.SAXException;

/**
 * OMENode is the node corresponding to the root "OME" XML element.
 *
 * Note that the DOM wrapped by an OMENode always corresponds to the OMECA-XML
 * schema, not the OME-XML schema. If an OME-XML document is provided, it is
 * automatically converted to OMECA-XML first using the OME2OMECA.xslt
 * stylesheet. In addition, OMENode functionality is provided to dump the DOM
 * to XML in either OME-XML or OMECA-XML format.
 */
public class OMENode extends OMEXMLNode {

  // -- Constants --

  /** Stylesheet for converting to OMECA-XML from OME-XML. */
  protected static final String XSLT_OME2OMECA = "OME2OME-CA.xslt";

  /** Stylesheet for converting to OME-XML from OMECA-XML. */
  protected static final String XSLT_OMECA2OME = "OME-CA2OME.xslt";

  /** Basic skeleton for an OMECA-XML node. */
  protected static final String SKELETON =
    "<?xml version=\"1.0\"?>\n" +
    "<OME xmlns=\"http://www.openmicroscopy.org/XMLschemas/CA/RC1/CA.xsd\" " +
    "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
    "xsi:schemaLocation=\"http://www.openmicroscopy.org/XMLschemas/OME/FC/" +
    "ome.xsd http://www.openmicroscopy.org/XMLschemas/OME/FC/ome.xsd " +
    "http://www.openmicroscopy.org/XMLschemas/STD/RC2/STD.xsd " +
    "http://www.openmicroscopy.org/XMLschemas/STD/RC2/STD.xsd\"/>";


  // -- Static fields --

  /** Cached stylesheet for converting to OMECA-XML from OME-XML. */
  protected static Templates xsltOME2OMECA;

  /** Cache stylesheet for converting to OME-XML from OMECA-XML. */
  protected static Templates xsltOMECA2OME;


  // -- Constructors --

  /** Constructs an empty OME root node. */
  public OMENode()
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    this(SKELETON);
  }

  /** Constructs an OME root node by parsing the given OME-XML file. */
  public OMENode(File file)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    this(parseOME(file).getDocumentElement());
  }

  /** Constructs an OME root node by parsing the given OME-XML string. */
  public OMENode(String xml)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    this(parseOME(xml).getDocumentElement());
  }

  /** Constructs an OME root node with the given associated DOM element. */
  public OMENode(Element element) { super(element); }


  // -- OMENode API methods --

  /** Gets nodes corresponding to Project child elements. */
  public List getProjects() {
    return createChildNodes(ProjectNode.class, "Project");
  }

  /** Gets the number of Project child elements. */
  public int countProjects() { return getSize(getChildElements("Project")); }

  /** Gets nodes corresponding to Dataset child elements. */
  public List getDatasets() {
    return createChildNodes(DatasetNode.class, "Dataset");
  }

  /** Gets the number of Dataset child elements. */
  public int countDatasets() { return getSize(getChildElements("Dataset")); }

  /** Gets nodes corresponding to Image child elements. */
  public List getImages() {
    return createChildNodes(ImageNode.class, "Image");
  }

  /** Gets the number of Image child elements. */
  public int countImages() { return getSize(getChildElements("Image")); }

  /** Gets node corresponding to CustomAttributes child element. */
  public CustomAttributesNode getCustomAttributes() {
    return (CustomAttributesNode)
      createChildNode(CustomAttributesNode.class, "CustomAttributes");
  }

  /** Writes the DOM to the given file in OME-XML or OMECA-XML format. */
  public void writeOME(File file, boolean omeca)
    throws FileNotFoundException, IOException, ParserConfigurationException,
    SAXException, TransformerException
  {
    Document doc = getOMEDocument(omeca);
    OutputStream os = new FileOutputStream(file);
    DOMUtil.writeXML(os, doc);
    os.close();
  }

  /**
   * Writes the DOM to a string in OME-XML format.
   * @return a string containing the resultant OME-XML
   */
  public String writeOME(boolean omeca)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerException
  {
    Document doc = getOMEDocument(omeca);
    ByteArrayOutputStream os = new ByteArrayOutputStream();
    DOMUtil.writeXML(os, doc);
    os.close();
    return os.toString();
  }

  /**
   * Gets the node's DOM in OME-XML (transformed) or OMECA-XML (native) format.
   */
  public Document getOMEDocument(boolean omeca)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    if (omeca) return element.getOwnerDocument();
    if (xsltOMECA2OME == null) {
      xsltOMECA2OME = DOMUtil.makeTemplates(XSLT_OMECA2OME);
    }

    // extract BigEndian & DimensionOrder attributes before they are dropped
    Document caDoc = element.getOwnerDocument();
    Vector caPix = DOMUtil.findElementList("Pixels", caDoc);
    String[] bigEndian = new String[caPix.size()];
    String[] dimOrder = new String[bigEndian.length];
    for (int i=0; i<bigEndian.length; i++) {
      Element el = (Element) caPix.elementAt(i);
      bigEndian[i] = DOMUtil.getAttribute("BigEndian", el);
      dimOrder[i] = DOMUtil.getAttribute("DimensionOrder", el);
    }

    // HACK - workaround for strange error that drops all attribute values
    ByteArrayOutputStream os = new ByteArrayOutputStream();
    DOMUtil.writeXML(os, caDoc);
    os.close();
    Source source = new StreamSource(
      new ByteArrayInputStream(os.toByteArray()));
    //Source source = new DOMSource(element.getOwnerDocument());
    Document doc = DOMUtil.transform(source, xsltOMECA2OME);

    // re-insert dropped DimensionOrder attributes
    Vector pix = DOMUtil.findElementList("Pixels", doc);
    for (int i=0; i<dimOrder.length; i++) {
      Element el = (Element) pix.elementAt(i);
      DOMUtil.setAttribute("BigEndian", bigEndian[i], el);
      DOMUtil.setAttribute("DimensionOrder", dimOrder[i], el);
    }

    return doc;
  }


  // -- OMEXMLNode API methods --

  /** Gets whether this type of node should have an LSID. */
  public boolean hasLSID() { return false; }


  // -- Utility methods --

  /** Parses a DOM from the given OME-XML or OMECA-XML file on disk. */
  public static Document parseOME(File file)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    InputStream is = new FileInputStream(file);
    OMEXMLHandler handler = saxParse(is);
    is.close();
    is = new FileInputStream(file);
    Document doc = parseOME(is, handler.isOMECA());
    is.close();
    tweakPixels(doc, handler);
    return doc;
  }

  /** Parses a DOM from the given OME-XML or OMECA-XML string. */
  public static Document parseOME(String xml)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    byte[] bytes = xml.getBytes();
    InputStream is = new ByteArrayInputStream(bytes);
    OMEXMLHandler handler = saxParse(is);
    is.close();
    is = new ByteArrayInputStream(bytes);
    Document doc = parseOME(is, handler.isOMECA());
    is.close();
    tweakPixels(doc, handler);
    return doc;
  }


  // -- Helper methods --

  /** Parses the given stream with SAX, recording certain characteristics. */
  protected static OMEXMLHandler saxParse(InputStream is)
    throws IOException, ParserConfigurationException, SAXException
  {
    OMEXMLHandler handler = new OMEXMLHandler();
    SAXParser saxParser = DOMUtil.SAX_FACT.newSAXParser();
    saxParser.parse(is, handler);
    return handler;
  }

  /** Parses a DOM from the given OME-XML or OMECA-XML input stream. */
  protected static Document parseOME(InputStream is, boolean omeca)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    if (omeca) {
      // parse OMECA-XML directly from input stream
      DocumentBuilder db = DOMUtil.DOC_FACT.newDocumentBuilder();
      return db.parse(is);
    }
    else {
      // transform OME-XML into OMECA-XML using XSLT stylesheet
      if (xsltOME2OMECA == null) {
        xsltOME2OMECA = DOMUtil.makeTemplates(XSLT_OME2OMECA);
      }
      Source xmlSource = new StreamSource(is);
      return DOMUtil.transform(new StreamSource(is), xsltOME2OMECA);
    }
  }

  /**
   * Repopulates the BigEndian and DimensionOrder Pixels attributes for all
   * Pixels elements in the given document, according to those previously
   * parsed by the specified SAX handler.
   */
  protected static void tweakPixels(Document doc, OMEXMLHandler handler) {
    Vector pix = DOMUtil.findElementList("Pixels", doc);
    for (int i=0; i<pix.size(); i++) {
      Element el = (Element) pix.elementAt(i);
      String id = DOMUtil.getAttribute("ID", el);
      if (id == null) continue;
      String bigEndian = handler.getBigEndian(id);
      DOMUtil.setAttribute("BigEndian", bigEndian, el);
      String dimOrder = handler.getDimensionOrder(id);
      DOMUtil.setAttribute("DimensionOrder", dimOrder, el);
    }
  }

}
