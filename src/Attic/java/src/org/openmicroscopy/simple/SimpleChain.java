/*
 * org.openmicroscopy.simple.SimpleChain
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

package org.openmicroscopy.simple;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import org.openmicroscopy.*;

public class SimpleChain
    extends SimpleObject
    implements Chain
{
    //protected String   owner;
    protected String   name,description;
    protected boolean  locked;
    protected List     nodes, links;

    public SimpleChain()
    {
        super();
        this.nodes = new ArrayList();
        this.links = new ArrayList();
    }

    public SimpleChain(int id, String owner, String name, boolean locked)
    {
        super(id);
        //this.owner = owner;
        this.name = name;
        this.locked = locked;
        this.nodes = new ArrayList();
        this.links = new ArrayList();
    }

    public Attribute getOwner() 
    { return null; }
    public void setOwner(Attribute owner)
    {  }

    public String getName() 
    { return name; }
    public void setName(String name)
    { this.name = name; }

    public String getDescription() 
    { return description; }
    public void setDescription(String description)
    { this.description = description; }

    public boolean getLocked() 
    { return locked; }
    public void setLocked(boolean locked)
    { this.locked = locked; }


    public int getNumNodes()
    { return nodes.size(); }
    public Node getNode(int index)
    { return (Node) nodes.get(index); }
    public Iterator iterateNodes()
    { return nodes.iterator(); }
    public List getNodes() { return nodes; }

    public Node addNode(int    id,
                        Module module,
                        String iteratorTag,
                        String newFeatureTag)
    {
        Node node;

        nodes.add(node = new SimpleNode(id,module,iteratorTag,newFeatureTag));
        return node;
    }


    public int getNumLinks()
    { return links.size(); }
    public Link getLink(int index)
    { return (Link) links.get(index); }
    public Iterator iterateLinks()
    { return links.iterator(); }
    public List getLinks() { return links; }

    public Link addLink(int                 id,
                        Node                fromNode,
                        Module.FormalOutput fromOutput,
                        Node                toNode,
                        Module.FormalInput  toInput)
    {
        Link link;

        links.add(link = new SimpleLink(id,fromNode,fromOutput,toNode,toInput));
        return link;
    }

    public List getPaths() { return null; }
    public Iterator iteratePaths() { return null; }
    
    public class SimpleNode
        extends SimpleObject
        implements Chain.Node
    {
        protected Module  module;
        protected String  iteratorTag, newFeatureTag;

        public SimpleNode() { super(); }

        public SimpleNode(int    id,
                          Module module,
                          String iteratorTag,
                          String newFeatureTag)
        {
            super(id);
            this.module = module;
            this.iteratorTag = iteratorTag;
            this.newFeatureTag = newFeatureTag;
        }

        public Chain getChain() { return SimpleChain.this; }

        public Module getModule() 
        { return module; }
        public void setModule(Module module)
        { this.module = module; }

        public String getIteratorTag() 
        { return iteratorTag; }
        public void setIteratorTag(String iteratorTag)
        { this.iteratorTag = iteratorTag; }

        public String getNewFeatureTag() 
        { return newFeatureTag; }
        public void setNewFeatureTag(String newFeatureTag)
        { this.newFeatureTag = newFeatureTag; }

        public List getInputLinks() { return null; }
        public Iterator iterateInputLinks() { return null; }

        public List getOutputLinks() { return null; }
        public Iterator iterateOutputLinks() { return null; }
    }


    public class SimpleLink
        extends SimpleObject
        implements Chain.Link
    {
        protected Node                 fromNode;
        protected Module.FormalOutput  fromOutput;
        protected Node                 toNode;
        protected Module.FormalInput   toInput;

        public SimpleLink() { super(); }

        public SimpleLink(int                 id,
                          Node                fromNode,
                          Module.FormalOutput fromOutput,
                          Node                toNode,
                          Module.FormalInput  toInput)
        {
            super(id);
            this.fromNode = fromNode;
            this.fromOutput = fromOutput;
            this.toNode = toNode;
            this.toInput = toInput;
        }

        public Chain getChain() { return SimpleChain.this; }

        public Node getFromNode() 
        { return fromNode; }
        public void setFromNode(Node fromNode)
        { this.fromNode = fromNode; }

        public Module.FormalOutput getFromOutput() 
        { return fromOutput; }
        public void setFromOutput(Module.FormalOutput fromOutput)
        { this.fromOutput = fromOutput; }

        public Node getToNode() 
        { return toNode; }
        public void setToNode(Node toNode)
        { this.toNode = toNode; }

        public Module.FormalInput getToInput() 
        { return toInput; }
        public void setToInput(Module.FormalInput toInput)
        { this.toInput = toInput; }
    }
}
