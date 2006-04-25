/*
 * org.openmicroscopy.xml.TrajectoryEntryNode
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
 * TrajectoryEntryNode is the node corresponding to the
 * "TrajectoryEntry" XML element.
 *
 * Name: TrajectoryEntry
 * AppliesTo: F
 * Location: OME/src/xml/OME/Analysis/FindSpots/spotModules.ome
 */
public class TrajectoryEntryNode extends AttributeNode
  implements TrajectoryEntry
{

  // -- Constructors --

  /**
   * Constructs a TrajectoryEntry node
   * with the given associated DOM element.
   */
  public TrajectoryEntryNode(Element element) { super(element); }

  /**
   * Constructs a TrajectoryEntry node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public TrajectoryEntryNode(OMEXMLNode parent) {
    super(parent.getDOMElement().getOwnerDocument().
      createElement("TrajectoryEntry"));
    parent.getDOMElement().appendChild(element);
  }

  /**
   * Constructs a TrajectoryEntry node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public TrajectoryEntryNode(OMEXMLNode parent, Trajectory trajectory,
    Integer order, Float deltaX, Float deltaY, Float deltaZ, Float distance,
    Float velocity)
  {
    this(parent);
    setTrajectory(trajectory);
    setOrder(order);
    setDeltaX(deltaX);
    setDeltaY(deltaY);
    setDeltaZ(deltaZ);
    setDistance(distance);
    setVelocity(velocity);
  }


  // -- TrajectoryEntry API methods --

  /**
   * Gets Trajectory referenced by Trajectory
   * attribute of the TrajectoryEntry element.
   */
  public Trajectory getTrajectory() {
    return (Trajectory)
      createReferencedNode(TrajectoryNode.class,
      "Trajectory", "Trajectory");
  }

  /**
   * Sets Trajectory referenced by Trajectory
   * attribute of the TrajectoryEntry element.
   *
   * @throws ClassCastException
   *   if parameter is not an instance of TrajectoryNode
   */
  public void setTrajectory(Trajectory value) {
    setReferencedNode((OMEXMLNode) value, "Trajectory", "Trajectory");
  }

  /**
   * Gets Order attribute
   * of the TrajectoryEntry element.
   */
  public Integer getOrder() {
    return getIntegerAttribute("Order");
  }

  /**
   * Sets Order attribute
   * for the TrajectoryEntry element.
   */
  public void setOrder(Integer value) {
    setIntegerAttribute("Order", value);
  }

  /**
   * Gets DeltaX attribute
   * of the TrajectoryEntry element.
   */
  public Float getDeltaX() {
    return getFloatAttribute("DeltaX");
  }

  /**
   * Sets DeltaX attribute
   * for the TrajectoryEntry element.
   */
  public void setDeltaX(Float value) {
    setFloatAttribute("DeltaX", value);
  }

  /**
   * Gets DeltaY attribute
   * of the TrajectoryEntry element.
   */
  public Float getDeltaY() {
    return getFloatAttribute("DeltaY");
  }

  /**
   * Sets DeltaY attribute
   * for the TrajectoryEntry element.
   */
  public void setDeltaY(Float value) {
    setFloatAttribute("DeltaY", value);
  }

  /**
   * Gets DeltaZ attribute
   * of the TrajectoryEntry element.
   */
  public Float getDeltaZ() {
    return getFloatAttribute("DeltaZ");
  }

  /**
   * Sets DeltaZ attribute
   * for the TrajectoryEntry element.
   */
  public void setDeltaZ(Float value) {
    setFloatAttribute("DeltaZ", value);
  }

  /**
   * Gets Distance attribute
   * of the TrajectoryEntry element.
   */
  public Float getDistance() {
    return getFloatAttribute("Distance");
  }

  /**
   * Sets Distance attribute
   * for the TrajectoryEntry element.
   */
  public void setDistance(Float value) {
    setFloatAttribute("Distance", value);
  }

  /**
   * Gets Velocity attribute
   * of the TrajectoryEntry element.
   */
  public Float getVelocity() {
    return getFloatAttribute("Velocity");
  }

  /**
   * Sets Velocity attribute
   * for the TrajectoryEntry element.
   */
  public void setVelocity(Float value) {
    setFloatAttribute("Velocity", value);
  }

}
