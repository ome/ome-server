/*
 * org.openmicroscopy.imageviewer.OMEImageFilterWidget
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
package org.openmicroscopy.imageviewer.ui;

import org.openmicroscopy.imageviewer.data.ImageInformation;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $ Revision: $ $ Date: $
 */
public interface OMEImageFilterWidget
{
  public int getCurrentZ();
  public int getCurrentT();
  public boolean getRedOn();
  public int getRedChannel();
  public boolean getGreenOn();
  public int getGreenChannel();
  public boolean getBlueOn();
  public int getBlueChannel();
  
  public void updatePossibleValues(ImageInformation info);
  public void loadDefaults(int z, int t, int redChannel, int greenChannel,
                           int blueChannel, boolean redOn, boolean greenOn,
                           boolean blueOn);
}
