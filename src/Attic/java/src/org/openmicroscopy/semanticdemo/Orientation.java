/*
 * org.openmicroscopy.semanticdemo.Orientation
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
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
 *------------------------------------------------------------------------------
 */




/*------------------------------------------------------------------------------
 *
 * Written by:    Jeff Mellen <jeffm@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.semanticdemo;

/**
 * An enumerated type that encapsulates the eight cardinal and subcardinal
 * directions (used in this context for orientation of overlays with respect
 * to a certain point)
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public final class Orientation
{
  private int value;
  
  private Orientation(int value)
  {
    this.value = value;
  }
  
  public static Orientation getStringInstance(String s)
  {
    if(s.equalsIgnoreCase("NW"))
    {
      return NW;
    }
    if(s.equalsIgnoreCase("N"))
    {
      return N;
    }
    if(s.equalsIgnoreCase("NE"))
    {
      return NE;
    }
    if(s.equalsIgnoreCase("E"))
    {
      return E;
    }
    if(s.equalsIgnoreCase("SE"))
    {
      return SE;
    }
    if(s.equalsIgnoreCase("S"))
    {
      return S;
    }
    if(s.equalsIgnoreCase("SW"))
    {
      return SW;
    }
    if(s.equalsIgnoreCase("W"))
    {
      return W;
    }
    if(s.equalsIgnoreCase("CTR"))
    {
      return CTR;
    }
    return null;
  }
  
  public static final Orientation NW = new Orientation(1);
  public static final Orientation N = new Orientation(2);
  public static final Orientation NE = new Orientation(3);
  public static final Orientation E = new Orientation(4);
  public static final Orientation SE = new Orientation(5);
  public static final Orientation S = new Orientation(6);
  public static final Orientation SW = new Orientation(7);
  public static final Orientation W = new Orientation(8);
  public static final Orientation CTR = new Orientation(0);
  
  public boolean equals(Object o)
  {
    return o == this; 
  }
  
  public int hashCode()
  {
    return value;
  }
}