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
import java.util.*;
import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.StreamSource;
//import javax.xml.transform.dom.DOMSource;
import org.w3c.dom.*;
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
    "xsi:schemaLocation=\"" +
    "http://www.openmicroscopy.org/XMLschemas/OME/FC/ome.xsd " +
    "http://www.openmicroscopy.org/XMLschemas/OME/FC/ome.xsd " +
    "http://www.openmicroscopy.org/XMLschemas/STD/RC2/STD.xsd " +
    "http://www.openmicroscopy.org/XMLschemas/STD/RC2/STD.xsd " +
    "http://www.openmicroscopy.org/XMLschemas/CA/RC1/CA.xsd " +
    "http://www.openmicroscopy.org/XMLschemas/CA/RC1/CA.xsd\"/>";

  /** Element name for storing extra path information. */
  protected static final String PATH = "Path";


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

  /**
   * Writes the DOM to the given file in OME-XML or OMECA-XML format.
   * BinData and TiffData elements are restored in their original form
   * from the document's input source, if available.
   */
  public void writeOME(File file, boolean omeca)
    throws FileNotFoundException, IOException, ParserConfigurationException,
    SAXException, TransformerException
  {
    Document doc = getOMEDocument(omeca, true);
    File tempFile = File.createTempFile("omexml", ".tmp");
    FileOutputStream os = new FileOutputStream(tempFile);
    boolean extra = !omeca; // don't write BinData character data for OMECA-XML
    writeOME(os, doc, extra);
    if (file.exists()) file.delete();
    tempFile.renameTo(file);
  }

  /**
   * Writes the DOM to a string in OME-XML format.
   * BinData and TiffData elements are discarded, since they could be too
   * large to fit in memory completely as a string.
   * @return a string containing the resultant OME-XML
   */
  public String writeOME(boolean omeca)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerException
  {
    Document doc = getOMEDocument(omeca, false);
    ByteArrayOutputStream os = new ByteArrayOutputStream();
    writeOME(os, doc, false);
    return os.toString();
  }

  /**
   * Writes the DOM to the given output stream in OME-XML format. As a side
   * effect, the output stream is closed. If extra is true, BinData elements
   * are restored in their original form from the document's input source,
   * if available.
   */
  public void writeOME(OutputStream os, Document doc, boolean extra)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerException
  {
    if (extra) {
      // first, write document to an array of bytes
      ByteArrayOutputStream baos = new ByteArrayOutputStream();
      DOMUtil.writeXML(baos, doc);

      // now run bytes through SAX parser
      OMEXMLOutputHandler handler = new OMEXMLOutputHandler(os);
      SAXParser saxParser = DOMUtil.SAX_FACT.newSAXParser();
      saxParser.parse(new ByteArrayInputStream(baos.toByteArray()), handler);
    }
    else {
      DOMUtil.writeXML(os, doc);
      os.close();
    }
  }

  /**
   * Gets the node's DOM in OME-XML (transformed) or OMECA-XML (native) format.
   */
  public Document getOMEDocument(boolean omeca)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    return getOMEDocument(omeca, false);
  }

  /**
   * Gets the node's DOM in OME-XML (transformed) or OMECA-XML (native) format,
   * possibly with extra elements and attributes: Path attribute for Pixels
   * pointing to original BinData character data; and BinData/TiffData elements
   * identifying where to place binary data.
   */
  public Document getOMEDocument(boolean omeca, boolean extra)
    throws IOException, ParserConfigurationException, SAXException,
    TransformerConfigurationException, TransformerException
  {
    if (omeca) return element.getOwnerDocument();
    if (xsltOMECA2OME == null) {
      xsltOMECA2OME = DOMUtil.makeTemplates(XSLT_OMECA2OME);
    }

    // extract extra elements before they are dropped
    Document caDoc = element.getOwnerDocument();
    Vector caPix = DOMUtil.findElementList("Pixels", caDoc);
    //Hashtable bigEndian = new Hashtable();
    //Hashtable dimOrder = new Hashtable();
    //Hashtable path = new Hashtable();
    Hashtable data = new Hashtable();
    for (int i=0; i<caPix.size(); i++) {
      Element el = (Element) caPix.elementAt(i);
      String id = DOMUtil.getAttribute("ID", el);
      //String big = DOMUtil.getAttribute("BigEndian", el);
      //if (big != null) bigEndian.put(id, big);
      //String dim = DOMUtil.getAttribute("DimensionOrder", el);
      //if (dim != null) dimOrder.put(id, dim);
      //String p = DOMUtil.getAttribute(PATH, el);
      //if (p != null) path.put(id, p);
      NodeList nl = el.getChildNodes();
      if (nl != null) data.put(id, nl);
    }

    // HACK - workaround for strange error that drops all attribute values
    ByteArrayOutputStream os = new ByteArrayOutputStream();
    DOMUtil.writeXML(os, caDoc);
    os.close();
    Source source = new StreamSource(
      new ByteArrayInputStream(os.toByteArray()));
    //Source source = new DOMSource(element.getOwnerDocument());

    // transform OMECA-XML -> OME-XML
    Document doc = DOMUtil.transform(source, xsltOMECA2OME);

    // re-insert dropped elements
    Vector pix = DOMUtil.findElementList("Pixels", doc);
    for (int i=0; i<pix.size(); i++) {
      Element el = (Element) pix.elementAt(i);
      String id = DOMUtil.getAttribute("ID", el);
      //String big = (String) bigEndian.get(id);
      //if (big != null) DOMUtil.setAttribute("BigEndian", big, el);
      //String dim = (String) dimOrder.get(id);
      //if (dim != null) DOMUtil.setAttribute("DimensionOrder", dim, el);
      if (extra) {
        //String p = (String) path.get(id);
        //if (p != null) DOMUtil.setAttribute(PATH, p, el);
        NodeList nl = (NodeList) data.get(id);
        if (nl != null) {
          int size = nl.getLength();
          for (int j=0; j<size; j++) {
            Node node = nl.item(j);
            if (!(node instanceof Element)) continue;
            Element n = (Element) node;
            Element child = DOMUtil.createChild(el, DOMUtil.getName(n));
            String[] names = DOMUtil.getAttributeNames(n);
            String[] values = DOMUtil.getAttributeValues(n);
            for (int k=0; k<names.length; k++) {
              DOMUtil.setAttribute(names[k], values[k], child);
            }
          }
        }
      }
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
    OMEXMLHandler handler = saxParse(is, file.getPath());
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
    OMEXMLHandler handler = saxParse(is, null);
    is.close();
    is = new ByteArrayInputStream(bytes);
    Document doc = parseOME(is, handler.isOMECA());
    is.close();
    tweakPixels(doc, handler);
    return doc;
  }


  // -- Helper methods --

  /** Parses the given stream with SAX, recording certain characteristics. */
  protected static OMEXMLHandler saxParse(InputStream is, String path)
    throws IOException, ParserConfigurationException, SAXException
  {
    OMEXMLHandler handler = new OMEXMLHandler(path);
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
   * parsed by the specified SAX handler. Also adds a Path attribute to
   * record the original path of the XML stream (if any), and appends child
   * BinData and TiffData element beneath the corresponding Pixels elements
   * as well. When the document is written back to disk, the original Path
   * can be used to reinsert dropped BinData character data so that a complete
   * OME-XML file is written without needing to hold the potentially massive
   * BinData blocks in memory all at once.
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
      String path = handler.getPath();
      if (path != null) DOMUtil.setAttribute(PATH, path, el);
      String[] names = handler.getDataNames(id);
      String[][] attrs = handler.getDataAttrNames(id);
      String[][] values = handler.getDataAttrValues(id);
      for (int j=0; j<names.length; j++) {
        Element data = DOMUtil.createChild(el, names[j]);
        for (int k=0; k<attrs[j].length; k++) {
          DOMUtil.setAttribute(attrs[j][k], values[j][k], data);
        }
      }
    }
  }

}
