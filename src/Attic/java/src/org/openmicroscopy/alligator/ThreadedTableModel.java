/*
 * org.openmicroscopy.alligator.ThreadedTableModel
 *
 * Copyright (C) 2002-2003 Open Microscopy Environment, MIT
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

package org.openmicroscopy.alligator;

import javax.swing.SwingUtilities;
import javax.swing.table.*;
import java.util.List;
//import org.openmicroscopy.*;

/**
 * <p>Several pieces of the UI in OME Alligator use table models to
 * display information received from the OME Remote Server in a
 * tabular format.  This class factors out several pieces of common
 * functionality, and performs any of the interactions with the Remote
 * Framework in a separate thread.</p>
 *
 * <p>It is assumed that subclasses of this table model will cache the
 * remote objects in a {@link List} to eliminate as much of the remote
 * overhead as possible.  Subclasses must define a method which can
 * populate this list given a {@link Factory} and possibly a "parent"
 * object.  (For instance, a sementic element table model would
 * populate this list with a <code>Factory</code> and a {@link
 * SemanticType}.)</p>
 * 
 * <p>This publicly accessible method is not defined in this
 * superclass, since it is highly dependent on the particular data
 * being viewed.  However, since it must be run in a separate thread
 * (so that the remote calls do not block the UI thread), it must not
 * do the perform remote calls itself.  Rather, it should create in
 * instance of {@link Runnable}, which will retrieve the new list from
 * via the Remote Framework, and then associate the table model with
 * the list via a call to {@link #updateList}.  For an example of
 * this, see the source for {@link SemanticElementTableModel}.</p>
 *
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */

public abstract class ThreadedTableModel
    extends AbstractTableModel
{
    protected List        tableList = null;
    protected boolean     loading = false;
    protected boolean     loadImmediately = true;
    protected Controller  controller;

    public ThreadedTableModel(Controller controller)
    {
        super();
        this.controller = controller;
    }

    public boolean canLoadImmediately() { return loadImmediately; }
    public void setLoadImmediately(boolean loadImmediately)
    { this.loadImmediately = loadImmediately; }

    public void fireTableDataChangedInThread()
    {
        SwingUtilities.invokeLater(new Runnable()
            {
                public void run() { fireTableDataChanged(); }
            });
    }

    public void startProgressInThread()
    {
        SwingUtilities.invokeLater(new Runnable()
            {
                public void run() { controller.startProgress(); }
            });
    }

    public void stopProgressInThread()
    {
        SwingUtilities.invokeLater(new Runnable()
            {
                public void run() { controller.stopProgress(); }
            });
    }

    protected void startLoading()
    {
        loading = true;
        fireTableDataChangedInThread();
        startProgressInThread();
    }

    protected void finishLoading()
    {
        loading = false;
        fireTableDataChangedInThread();
        stopProgressInThread();
    }

    public void update(final List list)
    {
        new Thread(new Runnable()
            {
                public void run()
                {
                    startLoading();
                    updateList(list);
                }
            }).start();
    }

    /**
     * This method should not be called from the Swing UI thread.
     */
    protected void updateList(List tableList)
    {
        this.tableList = tableList;
        if ((tableList != null) && canLoadImmediately())
        {
            int  numRows = getRowCountFromList();
            int  numColumns = getColumnCount();
            for (int r = 0; r < numRows; r++)
                for (int c = 0; c < numColumns; c++)
                {
                    getValueAtFromList(r,c);
                }
        }

        finishLoading();
    }

    public int getRowCount()
    {
        if (loading)
        {
            return 1;
        } else if (tableList != null) {
            return getRowCountFromList();
        } else {
            return 0;
        }
    }

    public int getColumnCount()
    {
        return getColumnNamesFromList().length;
    }

    public String getColumnName(int col)
    {
        return getColumnNamesFromList()[col];
    }

    public Object getValueAt(int row, int col)
    {
        if (loading)
        {
            return (col == getDefaultColumn())? "Loading...": null;
        } else if (tableList != null) {
            return getValueAtFromList(row,col);
        } else {
            return null;
        }
    }

    public int getRowCountFromList() { return tableList.size(); }
    public int getDefaultColumn() { return 0; }
    public abstract String[] getColumnNamesFromList();
    public abstract Object getValueAtFromList(int row, int col);
}
