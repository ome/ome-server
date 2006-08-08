/*
 * org.openmicroscopy.xml.OMEXMLOutputHandler
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
import org.xml.sax.Attributes;
import org.xml.sax.helpers.DefaultHandler;

/**
 * SAX handler for writing an OME-XML document to disk, replacing BinData
 * blocks with their original counterparts from the document's input source,
 * if available.
 */
public class OMEXMLOutputHandler extends DefaultHandler {

  // -- Fields --

  /** Input stream to check for BinData character data. */
  protected BufferedReader in;

  /** Output stream to which XML should be written. */
  protected PrintWriter out;

  /** Last element started. */
  private String lastElement;

  // -- Constructor --

  /**
   * Constructs a new OME-XML SAX handler for output.
   * The parsed XML is dumped to the given output stream.
   */
  public OMEXMLOutputHandler(OutputStream out) {
    this.out = new PrintWriter(new OutputStreamWriter(out));
  }

  // -- DefaultHandler API methods --

  public void startDocument() {
    out.print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
  }

  public void endDocument() {
    out.println();
    out.close();
  }

  public void startElement(String uri,
    String localName, String qName, Attributes attributes)
  {
    if (lastElement != null) out.print(">");
    lastElement = qName;
    out.print("<" + qName);
    int len = attributes == null ? 0 : attributes.getLength();
    for (int i=0; i<len; i++) {
      String name = attributes.getQName(i);
      String value = attributes.getValue(i);
      value.replaceAll("&", "&amp;");
      value.replaceAll("<", "&lt;");
      value.replaceAll(">", "&gt;");
      value.replaceAll("\"", "&quot;");
      value.replaceAll("\n", "&#10;");
      value.replaceAll("\r", "&#13;");
      out.print(" " + name + "=\"" + value + "\"");
    }
    if (in == null && qName.equals("Pixels")) {
      // get document's original input stream from Path attribute, to check
      // for BinData character data to output with BinData output elements
      String path = attributes == null ? null :
        attributes.getValue(OMENode.PATH);
      if (path != null) {
        try { in = new BufferedReader(new FileReader(path)); }
        catch (IOException exc) { exc.printStackTrace(); }
      }
    }
    if (in != null && qName.equals("BinData")) {
      try {
        // get next BinData element from input stream
        readUntil(in, "BinData");
        readUntil(in, ">");
        out.print(">");

        // transfer character data from input to output
        char[] buf = new char[8192];
        while (true) {
          in.mark(buf.length);
          int r = in.read(buf);
          int ndx = -1;
          if (r < 0) {
            ndx = 0;
            break; // EOF
          }
          for (int i=0; i<r; i++) {
            if (buf[i] == '<') {
              ndx = i;
              break;
            }
          }
          out.write(buf, 0, ndx < 0 ? r : ndx);
          if (ndx >= 0) { // end of character data
            in.reset();
            while (true) {
              long skip = in.skip(ndx);
              if (skip <= 0) throw new IOException("Cannot skip forward");
              ndx -= skip;
              if (ndx == 0) break;
            }
            break;
          }
        }
        readUntil(in, ">");
      }
      catch (IOException exc) { exc.printStackTrace(); }
      lastElement = null;
    }
  }

  public void endElement(String uri, String localName, String qName) {
    out.print(qName.equals(lastElement) ? "/>" : ("</" + qName + ">"));
  }

  // -- Helper methods --

  /** Reads from the reader until the given string is read, or EOF occurs. */
  protected void readUntil(BufferedReader in, String s)
    throws IOException
  {
    char[] arr = s.toCharArray();
    int p = 0;
    while (p < arr.length) {
      int c = in.read();
      if (p == 0) in.mark(arr.length);
      if (c < 0) break; // EOF
      if (c == arr[p]) p++;
      else {
        p = 0;
        in.reset();
      }
    }
  }

}
