/*
 * org.openmicroscopy.ds.st.Plate
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by hochheiserha via omejava on Mon May  2 15:12:23 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.ImagePlate;
import org.openmicroscopy.ds.st.PlateScreen;
import org.openmicroscopy.ds.st.Screen;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Plate
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Screen</code> */
    public Screen getScreen();
    public void setScreen(Screen value);

    /** Criteria field name: <code>ExternalReference</code> */
    public String getExternalReference();
    public void setExternalReference(String value);

    /** Criteria field name: <code>Name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>ImagePlateList</code> */
    public List getImagePlateList();
    /** Criteria field name: <code>#ImagePlateList</code> or <code>ImagePlateListList</code> */
    public int countImagePlateList();

    /** Criteria field name: <code>PlateScreenList</code> */
    public List getPlateScreenList();
    /** Criteria field name: <code>#PlateScreenList</code> or <code>PlateScreenListList</code> */
    public int countPlateScreenList();

}