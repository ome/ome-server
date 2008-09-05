/*
 * org.openmicroscopy.xml.XSLTUtil
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2007-2008 Open Microscopy Environment
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
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import org.w3c.dom.*;
import org.xml.sax.SAXException;

/** XSLTUtil contains useful functions for working with XSLT stylesheets. */
public final class XSLTUtil {

  // -- Constructor --

  private XSLTUtil() { }

  // -- Static fields --

  /** Factory for generating transformers. */
  public static final TransformerFactory TRANS_FACT =
    TransformerFactory.newInstance();

  /** Factory for generating document builders. */
  public static final DocumentBuilderFactory DOC_FACT =
    DocumentBuilderFactory.newInstance();

  // -- XSLT methods --

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
    InputStream in = XSLTUtil.class.getResource(sheet).openStream();
    Templates t = TRANS_FACT.newTemplates(new StreamSource(in));
    in.close();
    return t;
  }

}
