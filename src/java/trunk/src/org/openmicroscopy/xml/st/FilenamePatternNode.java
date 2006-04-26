/*
 * org.openmicroscopy.xml.FilenamePatternNode
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
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by curtis via Xmlgen on Apr 26, 2006 2:22:49 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * FilenamePatternNode is the node corresponding to the
 * "FilenamePattern" XML element.
 *
 * Name: FilenamePattern
 * AppliesTo: G
 * Location: OME/src/xml/OME/Import/FilenamePattern.ome
 * Description: Storage of a regular expression that specifies a filename
 *   pattern. Used to group files based on custom filenames.
 */
public class FilenamePatternNode extends AttributeNode
  implements FilenamePattern
{

  // -- Constructors --

  /**
   * Constructs a FilenamePattern node
   * with the given associated DOM element.
   */
  public FilenamePatternNode(Element element) { super(element); }

  /**
   * Constructs a FilenamePattern node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilenamePatternNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a FilenamePattern node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public FilenamePatternNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("FilenamePattern"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a FilenamePattern node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public FilenamePatternNode(OMEXMLNode parent, String format, String regEx,
    String name, String baseName, Integer theZ, Integer theT, Integer theC)
  {
    this(parent, true);
    setFormat(format);
    setRegEx(regEx);
    setName(name);
    setBaseName(baseName);
    setTheZ(theZ);
    setTheT(theT);
    setTheC(theC);
  }


  // -- FilenamePattern API methods --

  /**
   * Gets Format attribute
   * of the FilenamePattern element.
   */
  public String getFormat() {
    return getAttribute("Format");
  }

  /**
   * Sets Format attribute
   * for the FilenamePattern element.
   */
  public void setFormat(String value) {
    setAttribute("Format", value);
  }

  /**
   * Gets RegEx attribute
   * of the FilenamePattern element.
   */
  public String getRegEx() {
    return getAttribute("RegEx");
  }

  /**
   * Sets RegEx attribute
   * for the FilenamePattern element.
   */
  public void setRegEx(String value) {
    setAttribute("RegEx", value);
  }

  /**
   * Gets Name attribute
   * of the FilenamePattern element.
   */
  public String getName() {
    return getAttribute("Name");
  }

  /**
   * Sets Name attribute
   * for the FilenamePattern element.
   */
  public void setName(String value) {
    setAttribute("Name", value);
  }

  /**
   * Gets BaseName attribute
   * of the FilenamePattern element.
   */
  public String getBaseName() {
    return getAttribute("BaseName");
  }

  /**
   * Sets BaseName attribute
   * for the FilenamePattern element.
   */
  public void setBaseName(String value) {
    setAttribute("BaseName", value);
  }

  /**
   * Gets TheZ attribute
   * of the FilenamePattern element.
   */
  public Integer getTheZ() {
    return getIntegerAttribute("TheZ");
  }

  /**
   * Sets TheZ attribute
   * for the FilenamePattern element.
   */
  public void setTheZ(Integer value) {
    setIntegerAttribute("TheZ", value);
  }

  /**
   * Gets TheT attribute
   * of the FilenamePattern element.
   */
  public Integer getTheT() {
    return getIntegerAttribute("TheT");
  }

  /**
   * Sets TheT attribute
   * for the FilenamePattern element.
   */
  public void setTheT(Integer value) {
    setIntegerAttribute("TheT", value);
  }

  /**
   * Gets TheC attribute
   * of the FilenamePattern element.
   */
  public Integer getTheC() {
    return getIntegerAttribute("TheC");
  }

  /**
   * Sets TheC attribute
   * for the FilenamePattern element.
   */
  public void setTheC(Integer value) {
    setIntegerAttribute("TheC", value);
  }

}
