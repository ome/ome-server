/*
 * org.openmicroscopy.remote.RemoteChain
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
//import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class RemoteChain
    extends RemoteOMEObject
    implements Chain
{
    static
    { 
        RemoteObjectCache.addClass("OME::AnalysisChain",RemoteChain.class);
        RemoteObjectCache.addClass("OME::AnalysisChain::Node",
                                   RemoteChain.Node.class);
        RemoteObjectCache.addClass("OME::AnalysisChain::Link",
                                   RemoteChain.Link.class);
    }


    public RemoteChain() { super(); }
    public RemoteChain(RemoteSession session, String reference)
    { super(session,reference); }

    public Attribute getOwner()
    { return getAttributeElement("owner"); }
    public void setOwner(Attribute owner)
    { setAttributeElement("owner",owner); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public boolean getLocked()
    { return getBooleanElement("locked"); }
    public void setLocked(boolean locked)
    { setBooleanElement("locked",locked); }

    public List getNodes()
    { return getCachedRemoteListElement("OME::AnalysisChain::Node",
                                  "nodes"); }
    public Iterator iterateNodes()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_nodes");
        i.setClass("OME::AnalysisChain::Node");
        return i;
    }

    public List getLinks()
    { return getRemoteListElement("OME::AnalysisChain::Link",
                                  "links"); }
    public Iterator iterateLinks()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_links");
        i.setClass("OME::AnalysisChain::Link");
        return i;
    }

    public List getPaths()
    { return getRemoteListElement("OME::AnalysisPath",
                                  "paths"); }
    public Iterator iteratePaths()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_paths");
        i.setClass("OME::AnalysisPath");
        return i;
    }

    public static class Node
        extends RemoteOMEObject
        implements Chain.Node
    {
        public Node() { super(); }
        public Node(RemoteSession session, String reference)
        { super(session,reference); }

        public Chain getChain()
        { return (Chain)
                getRemoteElement("OME::AnalysisChain",
                                 "analysis_chain"); }

        public Module getModule()
        { return (Module)
                getRemoteElement("OME::Module",
                                 "module"); }
        public void setModule(Module module)
        { setRemoteElement("module",module); }

        public String getIteratorTag()
        { return getStringElement("iterator_tag"); }
        public void setIteratorTag(String iteratorTag)
        { setStringElement("iterator_tag",iteratorTag); }

        public String getNewFeatureTag()
        { return getStringElement("new_feature_tag"); }
        public void setNewFeatureTag(String newFeatureTag)
        { setStringElement("new_feature_tag",newFeatureTag); }

        public List getInputLinks()
        { 
        	List list =getCachedRemoteListElement("OME::AnalysisChain::Link",
                                      "input_links"); 
            return list;
        }
        
        public Iterator iterateInputLinks()
        {
            RemoteIterator i = (RemoteIterator)
                getRemoteElement("OME::Factory::Iterator",
                                 "iterate_input_links");
            i.setClass("OME::AnalysisChain::Link");
            return i;
        }

        public List getOutputLinks()
        {
        	List list = getCachedRemoteListElement("OME::AnalysisChain::Link",
                       	               "output_links"); 
            return list;
        }
        
        public Iterator iterateOutputLinks()
        {
            RemoteIterator i = (RemoteIterator)
                getRemoteElement("OME::Factory::Iterator",
                                 "iterate_output_links");
            i.setClass("OME::AnalysisChain::Link");
            return i;
        }
    }

    public static class Link
        extends RemoteOMEObject
        implements Chain.Link
    {
        public Link() { super(); }
        public Link(RemoteSession session, String reference)
        { super(session,reference); }

        public Chain getChain()
        { return (Chain)
                getRemoteElement("OME::AnalysisChain",
                                 "analysis_chain"); }

        public Chain.Node getFromNode()
        { return (Chain.Node)
                getRemoteElement("OME::AnalysisChain::Node",
                                 "from_node"); }
        public void setFromNode(Chain.Node fromNode)
        { setRemoteElement("from_node",fromNode); }

        public Module.FormalOutput getFromOutput()
        { return (Module.FormalOutput)
                getRemoteElement("OME::Module::FormalOutput",
                                 "from_output"); }
        public void setFromOutput(Module.FormalOutput fromOutput)
        { setRemoteElement("from_output",fromOutput); }

        public Chain.Node getToNode()
        { return (Chain.Node)
                getRemoteElement("OME::AnalysisChain::Node",
                                 "to_node"); }
        public void setToNode(Chain.Node toNode)
        { setRemoteElement("to_node",toNode); }

        public Module.FormalInput getToInput()
        { return (Module.FormalInput)
                getRemoteElement("OME::Module::FormalInput",
                                 "to_input"); }
        public void setToInput(Module.FormalInput toInput)
        { setRemoteElement("to_input",toInput); }
    }
}
