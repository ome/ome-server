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

import java.util.Map;
import java.util.HashMap;
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
    protected List    rootCategories;
    protected Map     categoryChildren, categoryModules;
    protected List    treeModelListeners = new ArrayList();

    public ModuleTreeModel()
    {
        updateCategories();
    }

    public void updateCategories()
    {
        updateCategories(null);
    }

    public void updateCategories(List rootCategories)
    {
        this.rootCategories = rootCategories;
        categoryChildren = new HashMap();
        categoryModules = new HashMap();
        fireTreeStructureChanged(rootNode);
    }

    /**
     * The only event raised by this model is TreeStructureChanged with the
     * root as path, i.e., the whole tree has changed.
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

    protected List getChildList(ModuleCategory category)
    {
        List  cached = (List) categoryChildren.get(category);
        if (cached == null)
        {
            cached = category.getChildren();
            categoryChildren.put(category,cached);
        }
        return cached;
    }

    protected List getModuleList(ModuleCategory category)
    {
        List  cached = (List) categoryModules.get(category);
        if (cached == null)
        {
            cached = category.getModules();
            categoryModules.put(category,cached);
        }
        return cached;
    }

    public Object getChild(Object parent, int index)
    {
        if (rootCategories == null)
            return null;

        if (parent == rootNode)
        {
            return rootCategories.get(index);
        } else if (parent instanceof ModuleCategory) {
            ModuleCategory  category = (ModuleCategory) parent;
            List  categoryList = getChildList(category);
            List  moduleList = getModuleList(category);
            if (index >= categoryList.size())
                return moduleList.get(index-categoryList.size());
            else
                return categoryList.get(index);
        } else {
            return null;
        }
    }

    public int getChildCount(Object parent)
    {
        if (rootCategories == null)
            return 0;

        if (parent == rootNode)
        {
            return rootCategories.size();
        } else if (parent instanceof ModuleCategory) {
            ModuleCategory  category = (ModuleCategory) parent;
            List  categoryList = getChildList(category);
            List  moduleList = getModuleList(category);
            return categoryList.size()+moduleList.size();
        } else {
            return 0;
        }
    }

    public int getIndexOfChild(Object parent, Object child)
    {
        if (rootCategories == null)
            return -1;

        if (parent == rootNode)
        {
            return rootCategories.indexOf(child);
        } else if (parent instanceof String) {
            ModuleCategory  category = (ModuleCategory) parent;
            List  categoryList = getChildList(category);
            List  moduleList = getModuleList(category);
            int index = categoryList.indexOf(child);
            if (index >= 0) return index;
            index = moduleList.indexOf(child);
            if (index >= 0) return index+categoryList.size();
            return -1;
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
