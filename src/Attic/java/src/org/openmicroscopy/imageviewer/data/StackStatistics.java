/*
 * org.openmicroscopy.imageviewer.data.StackStatistics
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
package org.openmicroscopy.imageviewer.data;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class StackStatistics
{
  private int min;
  private int max;
  private float mean;
  private float sigma;
  private float geoMean;
  private float geoSigma;
  
  public StackStatistics()
  {
    // empty constructor
  }
  
  public StackStatistics(int min, int max, float mean, float sigma,
                         float geoMean, float geoSigma)
  {
    this.min = min;
    this.max = max;
    this.mean = mean;
    this.sigma = sigma;
    this.geoMean = geoMean;
    this.geoSigma = geoSigma;
  }
  
  
  /**
   * @return
   */
  public float getGeoMean()
  {
    return geoMean;
  }

  /**
   * @return
   */
  public float getGeoSigma()
  {
    return geoSigma;
  }

  /**
   * @return
   */
  public int getMax()
  {
    return max;
  }

  /**
   * @return
   */
  public float getMean()
  {
    return mean;
  }

  /**
   * @return
   */
  public int getMin()
  {
    return min;
  }

  /**
   * @return
   */
  public float getSigma()
  {
    return sigma;
  }

  /**
   * @param f
   */
  public void setGeoMean(float f)
  {
    geoMean = f;
  }

  /**
   * @param f
   */
  public void setGeoSigma(float f)
  {
    geoSigma = f;
  }

  /**
   * @param i
   */
  public void setMax(int i)
  {
    max = i;
  }

  /**
   * @param f
   */
  public void setMean(float f)
  {
    mean = f;
  }

  /**
   * @param i
   */
  public void setMin(int i)
  {
    min = i;
  }

  /**
   * @param f
   */
  public void setSigma(float f)
  {
    sigma = f;
  }

}
