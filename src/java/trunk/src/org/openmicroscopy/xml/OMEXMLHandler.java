/*
 * org.openmicroscopy.xml.OMEXMLHandler
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

import java.util.Vector;
import org.xml.sax.Attributes;
import org.xml.sax.helpers.DefaultHandler;

/**
 * SAX handler for determining if an XML block is OME-XML or OMECA-XML,
 * and for recording certain Pixels attributes (BigEndian, DimensionOrder)
 * not translated by the OME2OME-CA stylesheet.
 */
public class OMEXMLHandler extends DefaultHandler {

  // -- Fields --

  /** Flag for whether the last OME element found indicated OMECA-XML. */
  protected boolean isOMECA;

  /** Pixels element attribute lists collected so far. */
  protected Vector pixels = new Vector();

  /** Counter for BinData and TiffData elements. */
  protected int dataCount = 0;

  /** Path to the XML data. Can be null. */
  protected String path;


  // -- Constructor --

  /** Constructs a new OME-XML SAX handler. */
  public OMEXMLHandler() { }

  /** Constructs a new OME-XML SAX handler with the given path. */
  public OMEXMLHandler(String path) { this.path = path; }


  // -- OMEXMLHandler API methods --

  /** Gets whether the last OME element found indicated OMECA-XML. */
  public boolean isOMECA() { return isOMECA; }

  /**
   * Gets the BigEndian attribute value corresponding
   * to the Pixels element with the given ID.
   */
  public String getBigEndian(String id) {
    PixelsInfo info = getPixelsInfo(id);
    return info == null ? null : info.bigEndian;
  }

  /**
   * Gets the DimensionOrder attribute value corresponding
   * to the Pixels element with the given ID.
   */
  public String getDimensionOrder(String id) {
    PixelsInfo info = getPixelsInfo(id);
    return info == null ? null : info.dimOrder;
  }

  /**
   * Gets the element names of BinData and TiffData children
   * for the Pixels element with the given ID.
   */
  public String[] getDataNames(String id) {
    PixelsInfo info = getPixelsInfo(id);
    if (info == null) return null;
    String[] s = new String[info.data.size()];
    info.data.copyInto(s);
    return s;
  }

  /**
   * Gets the element attribute names of BinData and TiffData children
   * for the Pixels element with the given ID.
   */
  public String[][] getDataAttrNames(String id) {
    PixelsInfo info = getPixelsInfo(id);
    if (info == null) return null;
    String[][] s = new String[info.attrNames.size()][];
    info.attrNames.copyInto(s);
    return s;
  }

  /**
   * Gets the element attribute names of BinData and TiffData children
   * for the Pixels element with the given ID.
   */
  public String[][] getDataAttrValues(String id) {
    PixelsInfo info = getPixelsInfo(id);
    if (info == null) return null;
    String[][] s = new String[info.attrValues.size()][];
    info.attrValues.copyInto(s);
    return s;
  }

  /** Gets the path to the XML data, or null if none. */
  public String getPath() { return path; }


  // -- DefaultHandler API methods --

  public void startDocument() { pixels.removeAllElements(); }

  public void startElement(String uri,
    String localName, String qName, Attributes attributes)
  {
    if (qName.equals("OME")) {
      isOMECA = attributes.getValue("xmlns").endsWith("CA.xsd");
    }
    else if (qName.equals("Pixels")) pixels.add(new PixelsInfo(attributes));
    else if (qName.equals("TiffData") ||
      qName.equals("BinData") || qName.equals("Bin:BinData"))
    {
      boolean bin = !qName.equals("TiffData");
      PixelsInfo info = (PixelsInfo) pixels.lastElement();
      info.data.addElement(bin ? "BinData" : "TiffData");
      int len = attributes.getLength();
      String[] names = new String[len];
      String[] values = new String[len];
      info.attrNames.addElement(names);
      info.attrValues.addElement(values);
      for (int i=0; i<len; i++) {
        names[i] = attributes.getQName(i);
        values[i] = attributes.getValue(i);
      }
    }
  }


  // -- Helper methods --

  /**
   * Gets attributes object corresponding to
   * the pixels element with the given ID.
   */
  protected PixelsInfo getPixelsInfo(String id) {
    if (id == null) return null;
    for (int i=0; i<pixels.size(); i++) {
      PixelsInfo info = (PixelsInfo) pixels.elementAt(i);
      if (id.equals(info.id)) return info;
    }
    return null;
  }


  // -- Helper classes --

  /** Stores important Pixels attributes. */
  protected class PixelsInfo {
    String id, bigEndian, dimOrder;
    Vector data, attrNames, attrValues;
    PixelsInfo(Attributes attr) {
      id = attr.getValue("ID");
      bigEndian = attr.getValue("BigEndian");
      dimOrder = attr.getValue("DimensionOrder");
      data = new Vector();
      attrNames = new Vector();
      attrValues = new Vector();
    }
  }

}
