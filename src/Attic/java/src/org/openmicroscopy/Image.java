/*
 * org.openmicroscopy.Image
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy;

import java.util.List;
import java.util.Iterator;

public interface Image
    extends OMEObject
{
    public String getName();
    public void setName(String name);

    public String getDescription();
    public void setDescription(String description);

    public String getImageGUID();
    public void setImageGUID(String imageGUID);

    public String getCreated();
    public void setCreated(String created);

    public String getInserted();
    public void setInserted(String inserted);

    public Attribute getExperimenter();
    public void setExperimenter(Attribute experimenter);

    public Attribute getGroup();
    public void setGroup(Attribute group);

    public List getDatasets();
    public Iterator iterateDatasets();

    public List getAllFeatures();
    public Iterator iterateAllFeatures();

    public ImagePixels getPixels(Attribute pixels);
}
