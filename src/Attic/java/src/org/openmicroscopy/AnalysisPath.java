/*
 * org.openmicroscopy.AnalysisPath
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




package org.openmicroscopy;

import java.util.List;
import java.util.Iterator;

/**
 * <p>Represents a single, linear data path through an analysis chain.
 * Each chain has one <i>data path</i> for each linear path from a
 * root node to a leaf node.  (A root node contains no inputs; a leaf
 * node contains no outputs.  Since analysis chains are acyclic, there
 * must be at least one of each in any chain.)</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */

public interface AnalysisPath
    extends OMEObject
{
    /** 
     * Returns the number of nodes along this analysis path.
     * @return the number of nodes along this analysis path
     */
    public int getPathLength();

    /**
     * Sets the number of nodes along this analysis path.
     * @param length the number of nodes along this analysis path
     */
    public void setPathLength(int length);

    /**
     * Returns the analysis chain that this path belongs to.
     * @return the analysis chain that this path belongs to.
     */
    public Chain getChain();

    /**
     * Sets the analysis chain that this path belongs to.
     * @param chain the analysis chain that this path belongs to.
     */
    public void setChain(Chain chain);

    /**
     * Returns a list of the nodes in this path.
     * @return a {@link List} of {@link AnalysisPath.Node Nodes}
     */
    public List getPathNodes();

    /**
     * Returns an iterator of the nodes in this path.
     * @return an {@link Iterator} of {@link AnalysisPath.Node Nodes}
     */
    public Iterator iteratePathNodes();

    /**
     * <p>Represents each element in an analysis path.  It corresponds
     * to one of the nodes in the analysis chain.</p>
     *
     * @author Douglas Creager
     * @version 2.0
     * @since OME2.0
     */

    public interface Node
        extends OMEObject
    {
        /**
         * Returns the position along the analysis path of this entry.
         * The position is indexed from 1.
         * @return the position along the analyis path of this entry
         */
        public int getPathOrder();

        /**
         * Sets the position along the analysis path of this entry.
         * The position is indexed from 1.
         * @param order the position along the analyis path of this
         * entry
         */
        public void setPathOrder(int order);

        /**
         * Returns the analysis path that this entry belongs to.
         * @return the analysis path that this entry belongs to.
         */
        public AnalysisPath getAnalysisPath();

        /**
         * Returns the chain node that this entry correspons to.
         * @return the chain node that this entry correspons to.
         */
        public Chain.Node getChainNode();

        /**
         * Sets the chain node that this entry correspons to.
         * @param node the chain node that this entry correspons to.
         */
        public void setChainNode(Chain.Node node);
    }
}
