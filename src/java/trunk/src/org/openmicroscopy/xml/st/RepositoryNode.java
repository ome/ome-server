/*
 * org.openmicroscopy.xml.RepositoryNode
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

import java.util.List;
import org.openmicroscopy.xml.AttributeNode;
import org.openmicroscopy.xml.OMEXMLNode;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * RepositoryNode is the node corresponding to the
 * "Repository" XML element.
 *
 * Name: Repository
 * AppliesTo: G
 * Location: OME/src/xml/OME/Core/OMEIS/Repository.ome
 * Description: A repository is a portion of the server-side file system
 *   devoted to OME. It is used primarily to store the pixels of OME images.
 */
public class RepositoryNode extends AttributeNode
  implements Repository
{

  // -- Constructors --

  /**
   * Constructs a Repository node
   * with the given associated DOM element.
   */
  public RepositoryNode(Element element) { super(element); }

  /**
   * Constructs a Repository node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public RepositoryNode(OMEXMLNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Repository node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public RepositoryNode(OMEXMLNode parent, boolean attach) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("Repository"));
    if (attach) parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a Repository node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public RepositoryNode(OMEXMLNode parent, Boolean isLocal, String path,
    String imageServerURL)
  {
    this(parent, true);
    setLocal(isLocal);
    setPath(path);
    setImageServerURL(imageServerURL);
  }


  // -- Repository API methods --

  /**
   * Gets IsLocal attribute
   * of the Repository element.
   */
  public Boolean isLocal() {
    return getBooleanAttribute("IsLocal");
  }

  /**
   * Sets IsLocal attribute
   * for the Repository element.
   */
  public void setLocal(Boolean value) {
    setBooleanAttribute("IsLocal", value);
  }

  /**
   * Gets Path attribute
   * of the Repository element.
   */
  public String getPath() {
    return getAttribute("Path");
  }

  /**
   * Sets Path attribute
   * for the Repository element.
   */
  public void setPath(String value) {
    setAttribute("Path", value);
  }

  /**
   * Gets ImageServerURL attribute
   * of the Repository element.
   */
  public String getImageServerURL() {
    return getAttribute("ImageServerURL");
  }

  /**
   * Sets ImageServerURL attribute
   * for the Repository element.
   */
  public void setImageServerURL(String value) {
    setAttribute("ImageServerURL", value);
  }

  /**
   * Gets a list of Thumbnail elements
   * referencing this Repository node.
   */
  public List getThumbnailList() {
    return createAttrReferralNodes(ThumbnailNode.class,
      "Thumbnail", "Repository");
  }

  /**
   * Gets the number of Thumbnail elements
   * referencing this Repository node.
   */
  public int countThumbnailList() {
    return getSize(getAttrReferrals("Thumbnail",
      "Repository"));
  }

  /**
   * Gets a list of Pixels elements
   * referencing this Repository node.
   */
  public List getPixelsList() {
    return createAttrReferralNodes(PixelsNode.class,
      "Pixels", "Repository");
  }

  /**
   * Gets the number of Pixels elements
   * referencing this Repository node.
   */
  public int countPixelsList() {
    return getSize(getAttrReferrals("Pixels",
      "Repository"));
  }

  /**
   * Gets a list of OTF elements
   * referencing this Repository node.
   */
  public List getOTFList() {
    return createAttrReferralNodes(OTFNode.class,
      "OTF", "Repository");
  }

  /**
   * Gets the number of OTF elements
   * referencing this Repository node.
   */
  public int countOTFList() {
    return getSize(getAttrReferrals("OTF",
      "Repository"));
  }

  /**
   * Gets a list of OriginalFile elements
   * referencing this Repository node.
   */
  public List getOriginalFileList() {
    return createAttrReferralNodes(OriginalFileNode.class,
      "OriginalFile", "Repository");
  }

  /**
   * Gets the number of OriginalFile elements
   * referencing this Repository node.
   */
  public int countOriginalFileList() {
    return getSize(getAttrReferrals("OriginalFile",
      "Repository"));
  }

}
