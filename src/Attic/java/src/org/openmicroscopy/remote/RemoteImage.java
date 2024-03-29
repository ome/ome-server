/*
 * org.openmicroscopy.remote.RemoteImage
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
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteImage
    extends RemoteOMEObject
    implements Image
{
    static
    {
        RemoteObjectCache.addClass("OME::Image",RemoteImage.class);
        RemoteObjectCache.addClass("OME::Image::DatasetMap",DatasetLink.class);
    }
        
    public RemoteImage() { super(); }
    public RemoteImage(RemoteSession session, String reference)
    { super(session,reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public String getImageGUID()
    { return getStringElement("image_guid"); }
    public void setImageGUID(String imageGUID)
    { setStringElement("image_guid",imageGUID); }

    public String getCreated()
    { return getStringElement("created"); }
    public void setCreated(String created)
    { setStringElement("created",created); }

    public String getInserted()
    { return getStringElement("inserted"); }
    public void setInserted(String inserted)
    { setStringElement("inserted",inserted); }

    public Attribute getExperimenter()
    { return getAttributeElement("experimenter"); }
    public void setExperimenter(Attribute experimenter)
    { setAttributeElement("experimenter",experimenter); }

    public Attribute getGroup()
    { return getAttributeElement("group"); }
    public void setGroup(Attribute group)
    { setAttributeElement("group",group); }

    public List getDatasets()
    {
        List linkList = getRemoteListElement("OME::Image::DatasetLink",
                                             "dataset_links");
        List datasetList = new ArrayList();
        Iterator i = linkList.iterator();
        while (i.hasNext())
        {
            DatasetLink link = (DatasetLink) i.next();
            datasetList.add(link.getDataset());
        }
        return datasetList;
    }

    public Iterator iterateDatasets()
    {
        final RemoteIterator i = (RemoteIterator) 
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_dataset_links");
        i.setClass("OME::Image::DatasetLink");
        return new Iterator()
            {
                public boolean hasNext() { return i.hasNext(); }
                public void remove() { i.remove(); }
                public Object next()
                {
                    DatasetLink link = (DatasetLink) i.next();
                    return link.getDataset();
                }
            };
    }

    public List getAllFeatures()
    { return getRemoteListElement("OME::Feature",
                                  "all_features"); }

    public Iterator iterateAllFeatures()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_all_features");
        i.setClass("OME::Feature");
        return i;
    }

    public Attribute getDefaultPixels() {
        return getAttributeElement("getDefaultPixels");
    }


    public ImagePixels getPixels(Attribute pixels)
    {
        Attribute repository = pixels.getAttributeElement("Repository");
        if (LocalImagePixels.isRepositoryLocal(repository))
        {
            LocalImagePixels pix = new LocalImagePixels(pixels);
            return pix;
        } else {
            Object o = caller.dispatch("OME::Image","GetPix",
                                       new Object[] { pixels });
            if (o == null) return null;
            RemoteImagePixels pix = (RemoteImagePixels)
                getRemoteSession().getObjectCache().
                getObject("OME::Image::Pixels",(String) o);
            pix.setPixelsAttribute(pixels);
            return pix;
        }
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
