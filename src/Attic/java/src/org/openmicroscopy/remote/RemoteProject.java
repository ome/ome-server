/*
 * org.openmicroscopy.remote.RemoteProject
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

public class RemoteProject
    extends RemoteOMEObject
    implements Project
{
    static
    {
        RemoteObjectCache.addClass("OME::Project",RemoteProject.class);
        RemoteObjectCache.addClass("OME::Project::DatasetMap",
                                   DatasetLink.class);
    }
        

    public RemoteProject() { super(); }
    public RemoteProject(RemoteSession session, String reference)
    { super(session,reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public Attribute getOwner()
    { return getAttributeElement("owner"); }
    public void setOwner(Attribute owner)
    { setAttributeElement("owner",owner); }

    public List getDatasets()
    {
        List linkList = getRemoteListElement("OME::Project::DatasetMap",
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
        i.setClass("OME::Project::DatasetMap");
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

    public void addDataset(Dataset ds) {
	setRemoteElement("addDataset", ds);
	return;
    }


    static class DatasetLink
        extends RemoteOMEObject
    {
        public DatasetLink() { super(); }
        public DatasetLink(RemoteSession session, String reference)
        { super(session,reference); }

        Project getProject()
        { return (Project) getRemoteElement("OME::Project","project"); }

        Dataset getDataset()
        { return (Dataset) getRemoteElement("OME::Dataset","dataset"); }
    }
}
