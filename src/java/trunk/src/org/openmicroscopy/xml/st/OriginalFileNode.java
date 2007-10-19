/*
 * org.openmicroscopy.xml.OriginalFileNode
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
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by curtis via Xmlgen on Oct 19, 2007 5:03:39 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * OriginalFileNode is the node corresponding to the
 * "OriginalFile" XML element.
 *
 * Name: OriginalFile
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/OMEIS/OriginalFile.ome
 * Description: Un archivo propietario o XML original.
 */
public class OriginalFileNode extends AttributeNode
  implements OriginalFile
{

  // -- Constructors --

  /**
   * Constructs an OriginalFile node
   * with the given associated DOM element.
   */
  public OriginalFileNode(Element element) { super(element); }

  /**
   * Constructs an OriginalFile node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public OriginalFileNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs an OriginalFile node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public OriginalFileNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "OriginalFile", attach);
  }

  /**
   * Constructs an OriginalFile node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public OriginalFileNode(CustomAttributesNode parent, Repository repository,
    String path, Long fileID, String sha1, String format)
  {
    this(parent, true);
    setRepository(repository);
    setPath(path);
    setFileID(fileID);
    setSHA1(sha1);
    setFormat(format);
  }


  // -- OriginalFile API methods --

  /**
   * Gets Repository referenced by Repository
   * attribute of the OriginalFile element.
   */
  public Repository getRepository() {
    return (Repository)
      getAttrReferencedNode("Repository", "Repository");
  }

  /**
   * Sets Repository referenced by Repository
   * attribute of the OriginalFile element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of RepositoryNode
   */
  public void setRepository(Repository value) {
    setAttrReferencedNode((OMEXMLNode) value, "Repository");
  }

  /**
   * Gets Path attribute
   * of the OriginalFile element.
   */
  public String getPath() {
    return getAttribute("Path");
  }

  /**
   * Sets Path attribute
   * for the OriginalFile element.
   */
  public void setPath(String value) {
    setAttribute("Path", value);  }

  /**
   * Gets FileID attribute
   * of the OriginalFile element.
   */
  public Long getFileID() {
    return getLongAttribute("FileID");
  }

  /**
   * Sets FileID attribute
   * for the OriginalFile element.
   */
  public void setFileID(Long value) {
    setAttribute("FileID", value);  }

  /**
   * Gets SHA1 attribute
   * of the OriginalFile element.
   */
  public String getSHA1() {
    return getAttribute("SHA1");
  }

  /**
   * Sets SHA1 attribute
   * for the OriginalFile element.
   */
  public void setSHA1(String value) {
    setAttribute("SHA1", value);  }

  /**
   * Gets Format attribute
   * of the OriginalFile element.
   */
  public String getFormat() {
    return getAttribute("Format");
  }

  /**
   * Sets Format attribute
   * for the OriginalFile element.
   */
  public void setFormat(String value) {
    setAttribute("Format", value);  }

}
