/*
 * org.openmicroscopy.analysis.ui.ModuleTreeModel
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

package org.openmicroscopy.analysis.ui;

import java.util.SortedSet;
import java.util.SortedMap;
import java.util.Set;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import javax.swing.tree.TreeModel;
import javax.swing.tree.TreePath;
import javax.swing.event.TreeModelListener;
import javax.swing.event.TreeModelEvent;

import org.openmicroscopy.*;

public class ModuleTreeModel
    implements TreeModel
{
    protected String  rootNode = "Categories";
    protected List    categories;
    protected List    treeModelListeners = new ArrayList();

    public ModuleTreeModel()
    {
        updateCategories();
    }

    public void updateCategories()
    {
        SortedMap  categoryMap = CategorizedModules.getCategories();
        Set        keys = categoryMap.keySet();

        categories = new ArrayList(keys);
    }

    /**
     * The only event raised by this model is TreeStructureChanged with the
     * root as path, i.e. the whole tree has changed.
     */
    protected void fireTreeStructureChanged(Object oldRoot)
    {
        TreeModelEvent e = new TreeModelEvent(this, 
                                              new Object[] {oldRoot});
        Iterator listeners = treeModelListeners.iterator();

        while (listeners.hasNext())
            ((TreeModelListener) listeners.next()).treeStructureChanged(e);
    }

    public void addTreeModelListener(TreeModelListener l)
    {
        treeModelListeners.add(l);
    }

    public Object getChild(Object parent, int index)
    {
        if (parent == rootNode)
        {
            return categories.get(index);
        } else if (parent instanceof String) {
            // SOOO SLOW
            SortedSet categorySet = (SortedSet) CategorizedModules.getCategories().get(parent);
            List      categoryList = new ArrayList(categorySet);
            return categoryList.get(index);
        } else {
            return null;
        }
    }

    public int getChildCount(Object parent)
    {
        if (parent == rootNode)
        {
            return categories.size();
        } else if (parent instanceof String) {
            // SOOO SLOW
            SortedSet categorySet = (SortedSet) CategorizedModules.getCategories().get(parent);
            List      categoryList = new ArrayList(categorySet);
            return categoryList.size();
        } else {
            return 0;
        }
    }

    public int getIndexOfChild(Object parent, Object child)
    {
        if (parent == rootNode)
        {
            return categories.indexOf(child);
        } else if (parent instanceof String) {
            // SOOO SLOW
            SortedSet categorySet = (SortedSet) CategorizedModules.getCategories().get(parent);
            List      categoryList = new ArrayList(categorySet);
            return categoryList.indexOf(child);
        } else {
            return -1;
        }
    }

    public Object getRoot()
    {
        return rootNode;
    }

    public boolean isLeaf(Object node)
    {
        return (node instanceof Module);
    }

    /**
     * Removes a listener previously added with addTreeModelListener().
     */
    public void removeTreeModelListener(TreeModelListener l)
    {
        treeModelListeners.remove(l);
    }

    /**
     * Messaged when the user has altered the value for the item
     * identified by path to newValue.  Not used by this model.
     */
    public void valueForPathChanged(TreePath path, Object newValue) 
    {
        System.out.println("*** valueForPathChanged : "
                           + path + " --> " + newValue);
    }

}
