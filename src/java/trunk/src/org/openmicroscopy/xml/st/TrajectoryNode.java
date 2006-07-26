/*
 * org.openmicroscopy.xml.TrajectoryNode
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
 * Created by curtis via Xmlgen on Jul 26, 2006 3:09:05 PM CDT
 *
 *-----------------------------------------------------------------------------
 */

package org.openmicroscopy.xml.st;

import java.util.List;
import org.openmicroscopy.xml.*;
import org.openmicroscopy.ds.st.*;
import org.w3c.dom.Element;

/**
 * TrajectoryNode is the node corresponding to the
 * "Trajectory" XML element.
 *
 * Name: Trajectory
 * AppliesTo: F
 * Location: OME/src/xml/OME/Analysis/FindSpots/spotModules.ome
 */
public class TrajectoryNode extends AttributeNode
  implements Trajectory
{

  // -- Constructors --

  /**
   * Constructs a Trajectory node
   * with the given associated DOM element.
   */
  public TrajectoryNode(Element element) { super(element); }

  /**
   * Constructs a Trajectory node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public TrajectoryNode(CustomAttributesNode parent) {
    this(parent, true);
  }

  /**
   * Constructs a Trajectory node,
   * creating its associated DOM element beneath the
   * given parent.
   */
  public TrajectoryNode(CustomAttributesNode parent,
    boolean attach)
  {
    super(parent, "Trajectory", attach);
  }

  /**
   * Constructs a Trajectory node,
   * creating its associated DOM element beneath the
   * given parent, using the specified parameter values.
   */
  public TrajectoryNode(CustomAttributesNode parent, String name,
    Float totalDistance, Float averageVelocity)
  {
    this(parent, true);
    setName(name);
    setTotalDistance(totalDistance);
    setAverageVelocity(averageVelocity);
  }


  // -- Trajectory API methods --

  /**
   * Gets Name attribute
   * of the Trajectory element.
   */
  public String getName() {
    return getAttribute("Name");
  }

  /**
   * Sets Name attribute
   * for the Trajectory element.
   */
  public void setName(String value) {
    setAttribute("Name", value);
  }

  /**
   * Gets TotalDistance attribute
   * of the Trajectory element.
   */
  public Float getTotalDistance() {
    return getFloatAttribute("TotalDistance");
  }

  /**
   * Sets TotalDistance attribute
   * for the Trajectory element.
   */
  public void setTotalDistance(Float value) {
    setFloatAttribute("TotalDistance", value);
  }

  /**
   * Gets AverageVelocity attribute
   * of the Trajectory element.
   */
  public Float getAverageVelocity() {
    return getFloatAttribute("AverageVelocity");
  }

  /**
   * Sets AverageVelocity attribute
   * for the Trajectory element.
   */
  public void setAverageVelocity(Float value) {
    setFloatAttribute("AverageVelocity", value);
  }

  /**
   * Gets a list of TrajectoryEntry elements
   * referencing this Trajectory node.
   */
  public List getTrajectoryEntryList() {
    return createAttrReferralNodes(TrajectoryEntryNode.class,
      "TrajectoryEntry", "Trajectory");
  }

  /**
   * Gets the number of TrajectoryEntry elements
   * referencing this Trajectory node.
   */
  public int countTrajectoryEntryList() {
    return getSize(getAttrReferrals("TrajectoryEntry",
      "Trajectory"));
  }

}
