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


  // -- DefaultHandler API methods --

  public void startDocument() {
    pixels.removeAllElements();
  }

  public void startElement(String uri,
    String localName, String qName, Attributes attributes)
  {
    if (qName.equals("OME")) {
      isOMECA = attributes.getValue("xmlns").endsWith("CA.xsd");
    }
    else if (qName.equals("Pixels")) pixels.add(new PixelsInfo(attributes));
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
    PixelsInfo(Attributes attr) {
      id = attr.getValue("ID");
      bigEndian = attr.getValue("BigEndian");
      dimOrder = attr.getValue("DimensionOrder");
    }
  }

}
