/*
 * org.openmicroscopy.xml2007.PixelsNode
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
 * Created by user via NameOfAutogenerator on Sep 22, 2007 12:00:00 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml2007;

import java.util.Vector;
import org.w3c.dom.Element;

/**
 * The Image will be unreadable if any of the required Pixel attributes are missing.
 * The Pixels themselves are stored within the file compressed by plane, and encoded in Base64.
 * The Pixels element must contain a list of BinData, each containing a single plane of pixels.
 * These Pixels elements, when read in document order, must produce a 5-D pixel array
 * of the size specified in this element, and in the dimension order specified by 'DimensionOrder'.
 */
public class PixelsNode extends OMEXMLNode {

  // -- Constructor --

  public PixelsNode(Element element) { super(element); }

  // -- PixelsNode API methods --

  //public int getBinDataCount() {
  //  return getChildCount("BinData");
  //}

  //public Vector getBinDataList() {
  //  return getChildList("BinData");
  //}

  public int getTiffDataCount() {
    return getChildCount("TiffData");
  }

  public Vector getTiffDataList() {
    return getChildNodes("TiffData");
  }

  public int getPlaneCount() {
    return getChildCount("Plane");
  }

  public Vector getPlaneList() {
    return getChildNodes("Plane");
  }

  public String getDimensionOrder() {
    return getAttribute("DimensionOrder");
  }

  public void setDimensionOrder(String dimensionOrder) {
    setAttribute("DimensionOrder", dimensionOrder);
  }

  public String getPixelType() {
    return getAttribute("PixelType");
  }

  public void setPixelType(String pixelType) {
    setAttribute("PixelType", pixelType);
  }

  /** This is true if the pixel data was written in BigEndian order. This is dependent on the system architecture of the machine that wrote the pixels. True for essentially all modern CPUs other than Intel and Alpha. All pixel data must be written in the same endian order. */
  public Boolean isBigEndian() {
    return getBooleanAttribute("BigEndian");
  }

  public void setBigEndian(Boolean bigEndian) {
    setAttribute("BigEndian", bigEndian);
  }

  /** Dimensional size of pixel data array */
  public Integer getSizeX() {
    return getIntegerAttribute("SizeX");
  }

  public void setSizeX(Integer sizeX) {
    setAttribute("SizeX", sizeX);
  }

  /** Dimensional size of pixel data array */
  public Integer getSizeY() {
    return getIntegerAttribute("SizeY");
  }

  public void setSizeY(Integer sizeY) {
    setAttribute("SizeY", sizeY);
  }

  /** Dimensional size of pixel data array */
  public Integer getSizeZ() {
    return getIntegerAttribute("SizeZ");
  }

  public void setSizeZ(Integer sizeZ) {
    setAttribute("SizeZ", sizeZ);
  }

  /** Dimensional size of pixel data array */
  public Integer getSizeC() {
    return getIntegerAttribute("SizeC");
  }

  public void setSizeC(Integer sizeC) {
    setAttribute("SizeC", sizeC);
  }

  /** Dimensional size of pixel data array */
  public Integer getSizeT() {
    return getIntegerAttribute("SizeT");
  }

  public void setSizeT(Integer sizeT) {
    setAttribute("SizeT", sizeT);
  }

  /** Physical size of a pixel */
  public Float getPhysicalSizeX() {
    return getFloatAttribute("PhysicalSizeX");
  }

  public void setPhysicalSizeX(Float physicalSizeX) {
    setAttribute("PhysicalSizeX", physicalSizeX);
  }

  /** Physical size of a pixel */
  public Float getPhysicalSizeY() {
    return getFloatAttribute("PhysicalSizeY");
  }

  public void setPhysicalSizeY(Float physicalSizeY) {
    setAttribute("PhysicalSizeY", physicalSizeY);
  }

  /** Physical size of a pixel */
  public Float getPhysicalSizeZ() {
    return getFloatAttribute("PhysicalSizeZ");
  }

  public void setPhysicalSizeZ(Float physicalSizeZ) {
    setAttribute("PhysicalSizeZ", physicalSizeZ);
  }

  public Float getTimeIncrement() {
    return getFloatAttribute("TimeIncrement");
  }

  public void setTimeIncrement(Float timeIncrement) {
    setAttribute("TimeIncrement", timeIncrement);
  }

  public Integer getWaveStart() {
    return getIntegerAttribute("WaveStart");
  }

  public void setWaveStart(Integer waveStart) {
    setAttribute("WaveStart", waveStart);
  }

  public Integer getWaveIncrement() {
    return getIntegerAttribute("WaveIncrement");
  }

  public void setWaveIncrement(Integer waveIncrement) {
    setAttribute("WaveIncrement", waveIncrement);
  }

  // -- OMEXMLNode API methods --

  public boolean hasID() { return true; }

}
