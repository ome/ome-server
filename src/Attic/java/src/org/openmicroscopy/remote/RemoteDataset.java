/*
 * org.openmicroscopy.remote.RemoteDataset
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import org.openmicroscopy.remote.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteDataset
    extends RemoteOMEObject
    implements Dataset
{
    static {
	RemoteObjectCache.addClass("OME::Dataset",RemoteDataset.class);
	RemoteObjectCache.addClass("OME::Image::DatasetMap",DatasetLink.class);
    }

    public RemoteDataset() { super(); }
    public RemoteDataset(RemoteSession session, String reference)
    { super(session,reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public boolean isLocked()
    { return getBooleanElement("locked"); }
    public void setLocked(boolean locked)
    { setBooleanElement("locked",locked); }

    public Attribute getOwner()
    { return getAttributeElement("owner"); }
    public void setOwner(Attribute owner)
    { setAttributeElement("owner",owner); }

    public List getProjects()
    {
        List linkList = getRemoteListElement("OME::Project::DatasetMap",
                                             "project_links");
        List projectList = new ArrayList();
        Iterator i = linkList.iterator();
        while (i.hasNext())
        {
            RemoteProject.DatasetLink link = (RemoteProject.DatasetLink) i.next();
            projectList.add(link.getProject());
        }
        return projectList;
    }

    public Iterator iterateProjects()
    {
        final RemoteIterator i = (RemoteIterator) 
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_project_links");
        i.setClass("OME::Project::DatasetMap");
        return new Iterator()
            {
                public boolean hasNext() { return i.hasNext(); }
                public void remove() { i.remove(); }
                public Object next()
                {
                    RemoteProject.DatasetLink link =
                        (RemoteProject.DatasetLink) i.next();
                    return link.getProject();
                }
            };
    }

    public List getImages()
    {
        List linkList = getRemoteListElement("OME::Image::DatasetMap",
                                             "image_links");
        List imageList = new ArrayList();
        Iterator i = linkList.iterator();
        while (i.hasNext())
        {
            RemoteImage.DatasetLink link = (RemoteImage.DatasetLink) i.next();
            imageList.add(link.getImage());
        }
        return imageList;
    }

    public Iterator iterateImages()
    {
        final RemoteIterator i = (RemoteIterator) 
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_image_links");
        i.setClass("OME::Image::DatasetMap");
        return new Iterator()
            {
                public boolean hasNext() { return i.hasNext(); }
                public void remove() { i.remove(); }
                public Object next()
                {
                    RemoteImage.DatasetLink link =
                        (RemoteImage.DatasetLink) i.next();
                    return link.getImage();
                }
            };
    }

    public void addImage(Image im) {
	setRemoteElement("addImage", im);
	return;
    }


    static class DatasetLink
        extends RemoteOMEObject
    {
        public DatasetLink() { super(); }
        public DatasetLink(RemoteSession session, String reference)
        { super(session,reference); }

        Image getImage()
        { return (Image) getRemoteElement("OME::Image","image"); }

        Dataset getDataset()
        { return (Dataset) getRemoteElement("OME::Dataset","dataset"); }
    }
}
