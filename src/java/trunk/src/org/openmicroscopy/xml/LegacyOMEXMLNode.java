/*
 * org.openmicroscopy.xml.LegacyOMEXMLNode
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

import ome.xml.OMEXMLNode;
import org.openmicroscopy.ds.dto.DataInterface;
import org.w3c.dom.Element;

/**
 * LegacyOMEXMLNode is the abstract superclass of OME-XML 2003-FC nodes.
 *
 * Subclasses of this LegacyOMEXMLNode provide OME-specific functionality such
 * as more intuitive traversal of OME structures, achieved through
 * implementation of the org.openmicroscopy.ds.dto and org.openmicroscopy.ds.st
 * interfaces whenever possible.
 */
public abstract class LegacyOMEXMLNode extends OMEXMLNode
  implements DataInterface
{

  // -- Constants --

  /** List of packages to check for ST interfaces. */
  protected static final String[] DTO_PACKAGES = {
    "org.openmicroscopy.ds.dto", "org.openmicroscopy.ds.st"
  };

  // -- Constructor --

  /** Constructs an OME-XML node with the given associated DOM element. */
  public LegacyOMEXMLNode(Element element) { super(element); }

  // -- OMEXMLNode API methods --

  /* @see ome.xml.OMEXMLNode#hasID() */
  public boolean hasID() { return true; }

  // -- DataInterface API methods --

  /** Returns the name of the data type this object represents. */
  public String getDTOTypeName() {
    // extract the type name from the class name
    String className = getClass().getName();
    if (className.endsWith("Node")) {
      int dot = className.lastIndexOf(".");
      int len = className.length();
      return className.substring(dot + 1, len - 4);
    }
    return null;
  }

  /** Returns the interface class of the data type this object represents. */
  public Class getDTOType() {
    // search for the correct interface among the known packages
    String typeName = getDTOTypeName();
    for (int i=0; i<DTO_PACKAGES.length; i++) {
      String className = DTO_PACKAGES[i] + "." + typeName;
      try { return Class.forName(className); }
      catch (ClassNotFoundException exc) { }
      catch (RuntimeException exc) {
        // HACK: workaround for bug in Apache Axis2
        String msg = exc.getMessage();
        if (msg != null && msg.indexOf("ClassNotFound") < 0) throw exc;
      }
    }
    return null;
  }

}
