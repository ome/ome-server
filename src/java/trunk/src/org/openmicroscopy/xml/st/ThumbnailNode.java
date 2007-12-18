/*
 * org.openmicroscopy.xml.ThumbnailNode
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
 * Created by curtis via Xmlgen on Dec 18, 2007 12:41:44 PM CST
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import ome.xml.OMEXMLNode;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * ThumbnailNode is the node corresponding to the
 * "Thumbnail" XML element.
 *
 * Name: Thumbnail
 * AppliesTo: I
 * Location: OME/src/xml/OME/Core/Image.ome
 * Description: Una vista previa es usada para mostrar una rapida y pequena
 *   representacion de la imagen al usuario.
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
  public ThumbnailNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Thumbnail node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public ThumbnailNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Thumbnail", attach);
  }

  /**
   * Constructs a Thumbnail node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public ThumbnailNode(CustomAttributesNode parent, String mimeType,
    Repository repository, String path)
  {
    this(parent, true);
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
    setAttribute("MimeType", value);  }

  /**
   * Gets Repository referenced by Repository
   * attribute of the Thumbnail element.
   */
  public Repository getRepository() {
    return (Repository)
      getAttrReferencedNode("Repository", "Repository");
  }

  /**
   * Sets Repository referenced by Repository
   * attribute of the Thumbnail element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of RepositoryNode
   */
  public void setRepository(Repository value) {
    setAttrReferencedNode((OMEXMLNode) value, "Repository");
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
    setAttribute("Path", value);  }

}
