/*
 * org.openmicroscopy.managers.ChainManager
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

import org.openmicroscopy.*;

/**
 * Provides useful methods for creating and modifying analysis chains
 * without having to make the appropriate direct {@link Factory}
 * calls.
 *
 * @author Douglas Creager
 * @version 2.1
 * @since OME2.1
 */

public interface ChainManager
{
    /**
     * Returns the {@link Session} that this <code>ChainManager</code>
     * corresponds to.
     * @return the {@link Session} that this <code>ChainManager</code>
     * corresponds to.
     */
    public Session getSession();

    /**
     * Creates a new analysis chain with the given name and
     * description.  Nodes and links can be added to the new chain
     * with the {@link #addNode} and {@link #addLink} methods.  The
     * chain will be owned by the user running this manager's {@link
     * Session}.
     * @param name the name of the new chain
     * @param description the description of the new chain
     * @return the new analysis chain object
     */
    public Chain createChain(String name, String description);

    /**
     * Creates a new analysis chain with the given name, description,
     * and owner.  Nodes and links can be added to the new chain with
     * the {@link #addNode} and {@link #addLink} methods.
     * @param name the name of the new chain
     * @param description the description of the new chain
     * @param owner the owner of the new chain.  Must be an {@link
     * Attribute} of semantic type <code>Experimenter</code>
     * @return the new analysis chain object
     */
    public Chain createChain(String name, String description, Attribute owner);

    /**
     * Creates a new analysis chain which is a clone of an existing
     * chain.  The new chain will be owned by the user running this
     * manager's {@link Session}.  The new chain will be unlocked,
     * even if the old chain is locked.
     * @param chain the analysis chain to clone
     * @return the new analysis chain object
     */
    public Chain cloneChain(Chain chain);

    /**
     * Creates a new analysis chain which is a clone of an existing
     * chain.  The new chain will be owned by <code>owner</code>.  The
     * new chain will be unlocked, even if the old chain is locked.
     * @param chain the analysis chain to clone
     * @param owner the owner of the new chain.  Must be an {@link
     * Attribute} of semantic type <code>Experimenter</code>
     * @return the new analysis chain object
     */
    public Chain cloneChain(Chain chain, Attribute owner);

    /**
     * Convenience method, merely a wrapper for {@link
     * Factory#findObject}.  Returns the module in the system with the
     * given name.  If there is more than one module with that name,
     * one of them will be returned.  Which one is undefined.
     * @param name the name of the module to find
     * @return the module with the given name, if any
     */
    public Module findModule(String name);

    /**
     * Adds a node to the specified chain corresponding to
     * <code>module</code>.  Throws an exception if the chain is
     * locked.  The iterator and new feature tags of the node will be
     * taken from the module's definition.
     * @param chain the chain to create a node in
     * @param module the module that the new node should represent
     * @return the new node object
     */
    public Chain.Node addNode(Chain chain, Module module);

    /**
     * Adds a node to the specified chain corresponding to
     * <code>module</code>.  Throws an exception if the chain is
     * locked.  The iterator tag of the node is given by
     * <code>iteratorTag</code>.  (If it is <code>null</code>, it will
     * be taken from the module's definition.)  The new feature tag of
     * the node will be taken from the module's definition.
     * @param chain the chain to create a node in
     * @param module the module that the new node should represent
     * @param iteratorTag the iterator tag of the new node
     * @return the new node object
     */
    public Chain.Node addNode(Chain chain, Module module,
                              String iteratorTag);

    /**
     * Adds a node to the specified chain corresponding to
     * <code>module</code>.  Throws an exception if the chain is
     * locked.  The iterator tag of the node is given by
     * <code>iteratorTag</code>.  The new feature tag is given by
     * <code>newFeatureTag</code> (If either is <code>null</code>,
     * that tag will be taken from the module's definition.)
     * @param chain the chain to create a node in
     * @param module the module that the new node should represent
     * @param iteratorTag the iterator tag of the new node
     * @param newFeatureTag the new feature tag of the new node
     * @return the new node object
     */
    public Chain.Node addNode(Chain chain, Module module,
                              String iteratorTag, String newFeatureTag);

    /**
     * Remove the given node and all of that node's incident links
     * from <code>chain</code>.  Throws an error if the chain is
     * locked.
     * @param chain the chain to remove the node from
     * @param node the node to remove
     */
    public void removeNode(Chain chain, Chain.Node node);

    /**
     * Convenience method, merely a wrapper for {@link
     * Factory#findObject}.  Returns the node representing the module
     * of the given name in the specified analysis chain.  If there is
     * more than one module with the given name, or more than one node
     * representing the corresponding module, one of the matching
     * nodes will be returned.  Which one is undefined.
     * @param chain the chain to look in
     * @param name the module name to look for
     * @return some node in the given chain representing a module of
     * the given name
     */
    public Chain.Node getNode(Chain chain, String name);

    /**
     * Convenience method, merely a wrapper for {@link
     * Factory#findObject}.  Returns the formal input of the specified
     * name in the node of the specified analysis chain.
     * @param chain the chain to look in
     * @param node the node to look in
     * @param name the name of the input to look for
     * @return the formal input of the given node's module with the
     * given name
     */

    public Module.FormalInput getFormalInput(Chain chain, Chain.Node node,
                                             String name);

    /**
     * Adds a link to the specified chain, connecting
     * <code>from_node</code> and <code>to_node</code>.  The chain
     * must be unlocked.  Both nodes must belong to
     * <code>chain</code>.  <code>from_output</code> must belong to
     * the module represented by <code>from_node</code>, and
     * <code>to_input</code> must belong to the module represented by
     * <code>to_node</code>.  There cannot already be a link pointing
     * to <code>to_input</code> on <code>to_node</code>.  If any of
     * these conditions are not met, an exception is thrown.
     * @param chain the chain to add a link to
     * @param fromNode the source node of the link
     * @param fromOutput the source output of the link
     * @param toNode the destination node of the link
     * @param toInput the destination input of the link
     * @return the new link object
     */
    public Chain.Link addLink(Chain               chain,
                              Chain.Node          fromNode,
                              Module.FormalOutput fromOutput,
                              Chain.Node          toNode,
                              Module.FormalInput  toInput);

    /**
     * <p>Adds a link to the specified chain, connecting
     * <code>from_node</code> and <code>to_node</code>.  The chain
     * must be unlocked.  Both nodes must belong to
     * <code>chain</code>.  <code>from_output</code> must belong to
     * the module represented by <code>from_node</code>, and
     * <code>to_input</code> must belong to the module represented by
     * <code>to_node</code>.  There cannot already be a link pointing
     * to <code>to_input</code> on <code>to_node</code>.  If any of
     * these conditions are not met, an exception is thrown.</p>
     *
     * <p>This version of the <code>addLink</code> method differs only
     * in that the input and output are specified by name, not by
     * actual {@link Module#FormalParameter} objects.  If the names do
     * not refer to existing parameters, an exception is thrown.</p>
     *
     * @param chain the chain to add a link to
     * @param fromNode the source node of the link
     * @param fromOutput the source output of the link
     * @param toNode the destination node of the link
     * @param toInput the destination input of the link
     * @return the new link object
     */
    public Chain.Link addLink(Chain       chain,
                              Chain.Node  fromNode,
                              String      fromOutput,
                              Chain.Node  toNode,
                              String      toInput);

    /**
     * Removes a link from the given chain.  In this version of the
     * method, the link is specified using the same format as the
     * {@link
     * #addLink(Chain,Chain.Node,Module.FormalOutput,Chain.Node,Module.FormalInput)
     * addLink} method.  The chain must be unlocked.
     * @param chain the chain to remove a link from
     * @param fromNode the source node of the link
     * @param fromOutput the source output of the link
     * @param toNode the destination node of the link
     * @param toInput the destination input of the link
     */
    public void removeLink(Chain               chain,
                           Chain.Node          fromNode,
                           Module.FormalOutput fromOutput,
                           Chain.Node          toNode,
                           Module.FormalInput  toInput);

    /**
     * Removes a link from the given chain.  In this version of the
     * method, the link is specified using the same format as the
     * {@link #addLink(Chain,Chain.Node,String,Chain.Node,String)
     * addLink} method.  The chain must be unlocked.
     * @param chain the chain to remove a link from
     * @param fromNode the source node of the link
     * @param fromOutput the source output of the link
     * @param toNode the destination node of the link
     * @param toInput the destination input of the link
     */
    public void remoteLink(Chain       chain,
                           Chain.Node  fromNode,
                           String      fromOutput,
                           Chain.Node  toNode,
                           String      toInput);

    /**
     * Removes a link from the given chain.  In this version of the
     * method, the link is specified directly.  The chain must be
     * unlocked.
     * @param chain the chain to remove a link from
     * @param link the link to remove
     */
    public void removeLink(Chain chain, Chain.Link link);

    /**
     * Returns a {@link List} of {@link FreeInput} objects,
     * corresponding to the free inputs of an analysis chain.  Free
     * inputs are those with no inbound data links.  Each free input
     * must be satisfied at execution time either by a {@link
     * ModuleExecution} or by a {@link List} of {@link Attribute
     * Attributes}.  The output {@link List} will be ordered by node.
     * @param chain the chain to get the free inputs of
     * @return a {@link List} of {@link FreeInput} objects
     */
    public List getFreeInputs(Chain chain);

    /**
     * Represents one free input in an analysis chain.  The accessors
     * of this class can be used to retrieve the information about the
     * free input.  Free inputs are those with no inbound data links.
     * Each free input must be satisfied at execution time either by a
     * {@link ModuleExecution} or by a {@link List} of {@link
     * Attribute Attributes}.
     *
     * @author Douglas Creager
     * @version 2.1
     * @since OME2.1
     */
    public interface FreeInput
    {
        /**
         * Returns the node that this free input belongs to.
         * @return the node that this free input belongs to.
         */
        public Chain.Node getNode();

        /**
         * Returns the module that the node represents.
         * <pre>freeInput.getModule()</pre>
         * will return the same as
         * <pre>freeInput.getNode().getModule()</pre>
         * @return the module that the node represents.
         */
        public Module getModule();

        /**
         * Returns the formal input that this free input corresponds to.
         * @return the formal input that this free input corresponds to.
         */
        public Module.FormalInput getFormalInput();

        /**
         * Returns the semantic type of this free input.
         * <pre>freeInput.getSemanticType()</pre>
         * will return the same as
         * <pre>freeInput.getFormalInput().getSemanticType()</pre>
         * @return the semantic type of this free input.
         */
        public SemanticType getSemanticType();
    }
}
