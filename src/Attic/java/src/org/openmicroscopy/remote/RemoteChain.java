/*
 * org.openmicroscopy.remote.RemoteChain
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

public class RemoteChain
    extends RemoteOMEObject
    implements Chain
{
    static
    { 
        RemoteObject.addClass("OME::AnalysisChain",RemoteChain.class);
        RemoteObject.addClass("OME::AnalysisChain::Node",RemoteChain.Node.class);
        RemoteObject.addClass("OME::AnalysisChain::Link",RemoteChain.Link.class);
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
    { return getRemoteListElement(Node.class,"nodes"); }
    public Iterator iterateNodes()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_nodes");
        i.setClass(Node.class);
        return i;
    }

    public List getLinks()
    { return getRemoteListElement(Link.class,"links"); }
    public Iterator iterateLinks()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_links");
        i.setClass(Link.class);
        return i;
    }

    public List getPaths()
    { return getRemoteListElement(RemoteAnalysisPath.class,"paths"); }
    public Iterator iteratePaths()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_paths");
        i.setClass(RemoteAnalysisPath.class);
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
              getRemoteElement(RemoteChain.class,"analysis_view"); }

        public Module getModule()
        { return (Module)
              getRemoteElement(RemoteModule.class,"program"); }
        public void setModule(Module module)
        { setRemoteElement("program",module); }

        public String getIteratorTag()
        { return getStringElement("iterator_tag"); }
        public void setIteratorTag(String iteratorTag)
        { setStringElement("iterator_tag",iteratorTag); }

        public String getNewFeatureTag()
        { return getStringElement("new_feature_tag"); }
        public void setNewFeatureTag(String newFeatureTag)
        { setStringElement("new_feature_tag",newFeatureTag); }

        public List getInputLinks()
        { return getRemoteListElement(Link.class,"input_links"); }
        public Iterator iterateInputLinks()
        {
            RemoteIterator i = (RemoteIterator)
                getRemoteElement(RemoteIterator.class,
                                 "iterate_input_links");
            i.setClass(Link.class);
            return i;
        }

        public List getOutputLinks()
        { return getRemoteListElement(Link.class,"output_links"); }
        public Iterator iterateOutputLinks()
        {
            RemoteIterator i = (RemoteIterator)
                getRemoteElement(RemoteIterator.class,
                                 "iterate_output_links");
            i.setClass(Link.class);
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
              getRemoteElement(RemoteChain.class,"analysis_view"); }

        public Chain.Node getFromNode()
        { return (Chain.Node)
              getRemoteElement(Node.class,"from_node"); }
        public void setFromNode(Chain.Node fromNode)
        { setRemoteElement("from_node",fromNode); }

        public Module.FormalOutput getFromOutput()
        { return (Module.FormalOutput)
              getRemoteElement(RemoteModule.FormalOutput.class,"from_output"); }
        public void setFromOutput(Module.FormalOutput fromOutput)
        { setRemoteElement("from_output",fromOutput); }

        public Chain.Node getToNode()
        { return (Chain.Node)
              getRemoteElement(Node.class,"to_node"); }
        public void setToNode(Chain.Node toNode)
        { setRemoteElement("to_node",toNode); }

        public Module.FormalInput getToInput()
        { return (Module.FormalInput)
              getRemoteElement(RemoteModule.FormalInput.class,"to_input"); }
        public void setToInput(Module.FormalInput toInput)
        { setRemoteElement("to_input",toInput); }
    }
}
