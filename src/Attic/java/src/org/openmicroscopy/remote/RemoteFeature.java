/*
 * org.openmicroscopy.remote.RemoteFeature
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

package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import java.util.List;
//import java.util.ArrayList;
import java.util.Iterator;

public class RemoteFeature
    extends RemoteOMEObject
    implements Feature
{
    static { RemoteObject.addClass("OME::Feature",RemoteFeature.class); }

    public RemoteFeature() { super(); }
    public RemoteFeature(String reference) { super(reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getTag()
    { return getStringElement("tag"); }
    public void setTag(String tag)
    { setStringElement("tag",tag); }

    public Image getImage()
    { return (Image) getRemoteElement(RemoteImage.class,"image"); }
    public void setImage(Image image)
    { setRemoteElement("image",image); }

    public Feature getParentFeature()
    { return (Feature) getRemoteElement(RemoteFeature.class,"parent_feature"); }
    public void setParentFeature(Feature parentFeature)
    { setRemoteElement("parent_feature",parentFeature); }

    public List getChildren()
    { return getRemoteListElement(RemoteFeature.class,"all_features"); }

    public Iterator iterateChildren()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_all_features");
        i.setClass(RemoteFeature.class);
        return i;
    }

}
