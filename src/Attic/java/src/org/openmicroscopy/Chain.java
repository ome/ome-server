/*
 * org.openmicroscopy.Chain
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

/**
 * <p>The <code>Chain</code> interface represents an OME analysis
 * chain.  An analysis chain consists of a directed acyclic graph
 * (DAG) representing the series of steps to be performed when
 * executing the chain.  The nodes of this graph are analysis modules;
 * the links are data dependencies specifying that the output of a
 * module should be used as input to another.</p>
 *
 * <p>Once an analysis chain has been executed, is must be locked to
 * prevent the set of nodes and links in its graph from changing.  If
 * the user wants to modify a chain which has been executed, they must
 * clone the existing chain and modify the clone.  (This could, of
 * course, be invisible to the user.)</p>
 *
 * <p>Executing an analysis chain generates a new instances of the
 * {@link ChainExecution} and {@link ChainExecution.Node} interfaces.
 * Any of the nodes which actually get executed (as opposed to reusing
 * the results of an existing computation) generate new instances of
 * the {@link ModuleExecution} interface.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 * @see Module
 */

public interface Chain
    extends OMEObject
{
    /**
     * Returns the owner of this analysis chain.  The attribute
     * returned will be of the "Experimenter" semantic type.
     * @return the owner of this analysis chain.
     */
    public Attribute getOwner();

    /**
     * Sets the owner of this analysis chain.  The attribute must be
     * of the "Experimenter" semantic type.
     * @param owner the owner of this analysis chain.
     */
    public void setOwner(Attribute owner);

    /**
     * Returns the name of this analysis chain.
     * @return the name of this analysis chain.
     */
    public String getName();

    /**
     * Sets the name of this analysis chain.
     * @param name the name of this analysis chain.
     */
    public void setName(String name);

    /**
     * Returns the description of this analysis chain.
     * @return the description of this analysis chain.
     */
    public String getDescription();

    /**
     * Sets the description of this analysis chain.
     * @param description the description of this analysis chain.
     */
    public void setDescription(String description);

    /**
     * Returns whether this analysis chain is locked.
     * @return whether this analysis chain is locked.
     */
    public boolean getLocked();

    /**
     * Sets whether this analysis chain is locked.
     * @param locked whether this analysis chain is locked.
     */
    public void setLocked(boolean locked);

    /**
     * Returns a list of {@link Chain.Node Nodes} in this analysis
     * chain.
     * @return a {@link List} of {@link Chain.Node Nodes} in this
     * analysis chain.
     */
    public List getNodes();

    /**
     * Returns an iterator of {@link Chain.Node Nodes} in this
     * analysis chain.
     * @return an {@link Iterator} of {@link Chain.Node Nodes} in this
     * analysis chain.
     */
    public Iterator iterateNodes();

    /**
     * Returns a list of {@link Chain.Link Links} in this analysis
     * chain.
     * @return a {@link List} of {@link Chain.Link Links} in this
     * analysis chain.
     */
    public List getLinks();

    /**
     * Returns an iterator of {@link Chain.Link Links} in this
     * analysis chain.
     * @return an {@link Iterator} of {@link Chain.Link Links} in this
     * analysis chain.
     */
    public Iterator iterateLinks();

    /**
     * Returns a list of {@link AnalysisPath Paths} in this analysis
     * chain.
     * @return a {@link List} of {@link AnalysisPath Paths} in this
     * analysis chain.
     */
    public List getPaths();

    /**
     * Returns an iterator of {@link AnalysisPath Paths} in this
     * analysis chain.
     * @return an {@link Iterator} of {@link AnalysisPath Paths} in this
     * analysis chain.
     */
    public Iterator iteratePaths();

    /**
     * <p>The <code>Chain.Node</code> interface represents the modules
     * in an analysis chain.  The data dependency links between the
     * nodes are specified by the {@link Chain.Link} interface.</p>
     *
     * @author Douglas Creager
     * @version 2.0
     * @since OME2.0
     * @see Chain.Link
     */

    public interface Node
        extends OMEObject
    {
        /**
         * Returns the analysis chain that this node belongs to.
         * @return the analysis chain that this node belongs to. 
         */
        public Chain getChain();

        /**
         * Returns the module that this node represents.
         * @return the module that this node represents.
         */
        public Module getModule(); 

        /**
         * Sets the module that this node represents.
         * @param module the module that this node represents.
         */
        public void setModule(Module module);

        /**
         * Returns the iterator tag for this node.  The iterator tag
         * specifies the grouping that the analysis engine will
         * perform when collecting feature inputs and presenting them
         * to the module.
         * @return the iterator tag for this node.
         */
        public String getIteratorTag();

        /**
         * Sets the iterator tag for this node.
         * @param iteratorTag the iterator tag for this node.
         */
        public void setIteratorTag(String iteratorTag);

        public String getNewFeatureTag();
        public void setNewFeatureTag(String newFeatureTag);

        public List getInputLinks();
        public Iterator iterateInputLinks();

        public List getOutputLinks();
        public Iterator iterateOutputLinks();
    }

    /**
     * <p>The <code>Chain.Link</code> interface represents the data
     * dependency links between nodes in an analysis chain.  The nodes
     * themselves are specified by the {@link Chain.Node} interface.
     *
     * @author Douglas Creager
     * @version 2.0
     * @since OME2.0
     * @see Chain.Node
     */

    public interface Link
        extends OMEObject
    {
        public Chain getChain();

        public Node getFromNode(); 
        public void setFromNode(Node fromNode);

        public Module.FormalOutput getFromOutput();
        public void setFromOutput(Module.FormalOutput fromOutput);

        public Node getToNode();
        public void setToNode(Node toNode);

        public Module.FormalInput getToInput();
        public void setToInput(Module.FormalInput toInput);
    }
}
