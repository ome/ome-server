/*
 * org.openmicroscopy.ds.dto.Image
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
 * Created by hochheiserha via omejava on Mon May  2 15:18:38 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterDTO;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.st.PixelsDTO;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Image
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>description</code> */
    public String getDescription();
    public void setDescription(String value);

    /** Criteria field name: <code>owner</code> */
    public Experimenter getOwner();
    public void setOwner(Experimenter value);

    /** Criteria field name: <code>created</code> */
    public String getCreated();
    public void setCreated(String value);

    /** Criteria field name: <code>inserted</code> */
    public String getInserted();
    public void setInserted(String value);

    /** Criteria field name: <code>default_pixels</code> */
    public Pixels getDefaultPixels();
    public void setDefaultPixels(Pixels value);

    /** Criteria field name: <code>datasets</code> */
    public List getDatasets();
    /** Criteria field name: <code>#datasets</code> or <code>datasetsList</code> */
    public int countDatasets();

    /** Criteria field name: <code>all_features</code> */
    public List getFeatures();
    /** Criteria field name: <code>#all_features</code> or <code>all_featuresList</code> */
    public int countFeatures();

}
