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

public class RemoteChain
    extends RemoteOMEObject
    implements Chain
{
    static
    { 
        addClass("OME::AnalysisChain",RemoteChain.class);
        addClass("OME::AnalysisChain::Node",RemoteChain.Node.class);
        addClass("OME::AnalysisChain::Link",RemoteChain.Link.class);
    }


    public RemoteChain() { super(); }
    public RemoteChain(String reference) { super(reference); }

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
    { return getRemoteListElement(getClass("OME::AnalysisChain::Node"),
                                  "nodes"); }
    public Iterator iterateNodes()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_nodes");
        i.setClass(getClass("OME::AnalysisChain::Node"));
        return i;
    }

    public List getLinks()
    { return getRemoteListElement(getClass("OME::AnalysisChain::Link"),
                                  "links"); }
    public Iterator iterateLinks()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_links");
        i.setClass(getClass("OME::AnalysisChain::Link"));
        return i;
    }

    public List getPaths()
    { return getRemoteListElement(getClass("OME::AnalysisPath"),
                                  "paths"); }
    public Iterator iteratePaths()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_paths");
        i.setClass(getClass("OME::AnalysisPath"));
        return i;
    }

    public static class Node
        extends RemoteOMEObject
        implements Chain.Node
    {
        public Node() { super(); }
        public Node(String reference) { super(reference); }

        public Chain getChain()
        { return (Chain)
                getRemoteElement(getClass("OME::AnalysisChain"),
                                 "analysis_chain"); }

        public Module getModule()
        { return (Module)
                getRemoteElement(getClass("OME::Module"),
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
        { return getRemoteListElement(getClass("OME::AnalysisChain::Link"),
                                      "input_links"); }
        public Iterator iterateInputLinks()
        {
            RemoteIterator i = (RemoteIterator)
                getRemoteElement(getClass("OME::Factory::Iterator"),
                                 "iterate_input_links");
            i.setClass(getClass("OME::AnalysisChain::Link"));
            return i;
        }

        public List getOutputLinks()
        { return getRemoteListElement(getClass("OME::AnalysisChain::Link"),
                                      "output_links"); }
        public Iterator iterateOutputLinks()
        {
            RemoteIterator i = (RemoteIterator)
                getRemoteElement(getClass("OME::Factory::Iterator"),
                                 "iterate_output_links");
            i.setClass(getClass("OME::AnalysisClass:Link"));
            return i;
        }
    }

    public static class Link
        extends RemoteOMEObject
        implements Chain.Link
    {
        public Link() { super(); }
        public Link(String reference) { super(reference); }

        public Chain getChain()
        { return (Chain)
                getRemoteElement(getClass("OME::AnalysisChain"),
                                 "analysis_chain"); }

        public Chain.Node getFromNode()
        { return (Chain.Node)
                getRemoteElement(getClass("OME::AnalysisChain::Node"),
                                 "from_node"); }
        public void setFromNode(Chain.Node fromNode)
        { setRemoteElement("from_node",fromNode); }

        public Module.FormalOutput getFromOutput()
        { return (Module.FormalOutput)
                getRemoteElement(getClass("OME::Module::FormalOutput"),
                                 "from_output"); }
        public void setFromOutput(Module.FormalOutput fromOutput)
        { setRemoteElement("from_output",fromOutput); }

        public Chain.Node getToNode()
        { return (Chain.Node)
                getRemoteElement(getClass("OME::AnalysisChain::Node"),
                                 "to_node"); }
        public void setToNode(Chain.Node toNode)
        { setRemoteElement("to_node",toNode); }

        public Module.FormalInput getToInput()
        { return (Module.FormalInput)
                getRemoteElement(getClass("OME::Module::FormalInput"),
                                 "to_input"); }
        public void setToInput(Module.FormalInput toInput)
        { setRemoteElement("to_input",toInput); }
    }
}
