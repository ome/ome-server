/*
 * org.openmicroscopy.xml.ThumbnailNode
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
 * Created by curtis via Xmlgen on Apr 24, 2006 4:30:18 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ThumbnailNode is the node corresponding to the
 * "Thumbnail" XML element.
 *
 * Name: Thumbnail
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: A thumbnail is used to display a quick small representation of
 *   the image to the user.
 */
public class ThumbnailNode extends AttributeNode
  implements Thumbnail
{

  // -- Constructors --

  /**
   * Constructs a Thumbnail node
   * with the given associated DOM element.
   */
  public ThumbnailNode(Element element) { super(element); }

  /**
   * Constructs a Thumbnail node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ThumbnailNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("Thumbnail"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a Thumbnail node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ThumbnailNode(OMEXMLNode parent, String mimeType,
    Repository repository, String path)
  {
    this(parent);
    setMimeType(mimeType);
    setRepository(repository);
    setPath(path);
  }


  // -- Thumbnail API methods --

  /**
   * Gets MimeType attribute
   * of the Thumbnail element.
   */
  public String getMimeType() {
    return getAttribute("MimeType");
  }

  /**
   * Sets MimeType attribute
   * for the Thumbnail element.
   */
  public void setMimeType(String value) {
    setAttribute("MimeType", value);
  }

  /**
   * Gets Repository referenced by Repository
   * attribute of the Thumbnail element.
   */
  public Repository getRepository() {
    return (Repository)
      createReferencedNode(RepositoryNode.class,
      "Repository", "Repository");
  }

  /**
   * Sets Repository referenced by Repository
   * attribute of the Thumbnail element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of RepositoryNode
   */
  public void setRepository(Repository value) {
    setReferencedNode((OMEXMLNode) value, "Repository", "Repository");
  }

  /**
   * Gets Path attribute
   * of the Thumbnail element.
   */
  public String getPath() {
    return getAttribute("Path");
  }

  /**
   * Sets Path attribute
   * for the Thumbnail element.
   */
  public void setPath(String value) {
    setAttribute("Path", value);
  }

}
