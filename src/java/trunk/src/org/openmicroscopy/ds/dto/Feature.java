/*
 * org.openmicroscopy.ds.dto.Feature
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
 * Created by dcreager via omejava on Wed Feb 18 17:57:24 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Feature
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>image</code> */
    public Image getImage();
    public void setImage(Image value);

    /** Criteria field name: <code>parent_feature</code> */
    public Feature getParentFeature();
    public void setParentFeature(Feature value);

    /** Criteria field name: <code>tag</code> */
    public String getTag();
    public void setTag(String value);

    /** Criteria field name: <code>name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>children</code> */
    public List getChildren();
    /** Criteria field name: <code>#children</code> */
    public int countChildren();

}
