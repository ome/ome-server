/*
 * org.openmicroscopy.ChainExecution
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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




package org.openmicroscopy;

import java.util.List;
import java.util.Iterator;

/**
 * <p>Represents an execution of a {@link Chain} against a {@link
 * Dataset} of {@link Image Images}.  The {@link ChainExecution.Node}
 * class represents an execution of each node in the chain.  Each
 * actual execution of the chain is represented by exactly one
 * <code>ChainExecution</code>, and each execution of a node is
 * represented by exactly one {@link ChainExecution.Node}, even if the
 * results of a module execution are reused.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */
public interface ChainExecution
    extends OMEObject
{
    /**
     * Returns a timestamp indicating when execution occurred.
     * @return a timestamp indicating when execution occurred
     */
    public String getTimestamp();

    /**
     * Sets a timestamp indicating when execution occurred.
     * @param timestamp a timestamp indicating when execution occurred
     */
    public void setTimestamp(String timestamp);

    /**
     * Returns the analysis chain that was executed.
     * @return the analysis chain that was executed
     */
    public Chain getChain();

    /**
     * Sets the analysis chain that was executed.
     * @param chain the analysis chain that was executed
     */
    public void setChain(Chain chain);

    /**
     * Returns the dataset that the chain was executed against.
     * @return the dataset that the chain was executed against.
     */
    public Dataset getDataset();

    /**
     * Sets the dataset that the chain was executed against.
     * @param dataset the dataset that the chain was executed against.
     */
    public void setDataset(Dataset dataset);

    /**
     * Returns the experimenter who performed the execution of the
     * chain.  The {@link Attribute} returned will be of the
     * <code>Experimenter</code> semantic type.
     * @return the experimenter who performed the execution of the
     * chain
     */
    public Attribute getExperimenter();

    /**
     * Sets the experimenter who performed the execution of the chain.
     * The {@link Attribute} provided must be of the
     * <code>Experimenter</code> semantic type.
     * @param experimenter the experimenter who performed the
     * execution of the chain
     */
    public void setExperimenter(Attribute experimenter);

    /**
     * Returns a list of the node executions in this chain execution.
     * @return a {@link List} of {@link ChainExecution.Node Nodes}
     */
    public List getNodes();

    /**
     * Returns an iterator of the nodes in this chain execution.
     * @return an {@link Iterator} of {@link ChainExecution.Node Nodes}
     */
    public Iterator iterateNodes();

    /**
     * <p>Represents the execution of a node in an analysis chain.
     * There will always be exactly once instance of
     * <code>ChainExecution.Node</code> for each execution of an
     * analysis chain node.  However, if that node execution was
     * satisfied with the reused results of a previous module
     * execution, then no new instance of {@link ModuleExecution} will
     * be created.</p>
     *
     * @author Douglas Creager
     * @version 2.0
     * @since OME2.0
     */
    public interface Node
        extends OMEObject
    {
        /**
         * Returns the {@link ChainExecution} that this node execution
         * belongs to.
         * @return the {@link ChainExecution} that this node execution
         * belongs to
         */
        public ChainExecution getChainExecution();

        /**
         * Returns the {@link Chain.Node} that was exeecuted.
         * @return the {@link Chain.Node} that was exeecuted
         */
        public Chain.Node getChainNode();

        /**
         * Sets the {@link Chain.Node} that was exeecuted.
         * @param node the {@link Chain.Node} that was exeecuted
         */
        public void setChainNode(Chain.Node node);

        /**
         * Returns the {@link ModuleExecution} that satisfied this
         * node execution.
         * @return the {@link ModuleExecution} that satisfied this
         * node execution.
         */
        public ModuleExecution getModuleExecution();

        /**
         * Sets the {@link ModuleExecution} that satisfied this node
         * execution.
         * @param analysis the {@link ModuleExecution} that satisfied
         * this node execution.
         */
        public void setModuleExecution(ModuleExecution analysis);
    }
}
