/*
 * org.openmicroscopy.util.ProgressMonitorTracker;
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

package org.openmicroscopy.util;

import javax.swing.ProgressMonitor;

/**
 * <p>Wrapper class for {@link ProgressMonitor}, making it conform to
 * the {@link ProgressTracker} interface.</p>
 *
 * @author Douglas Creager
 * @since OME2.1
 * @version 2.1
 */

public class ProgressMonitorTracker
    extends IntProgressTracker
{
    protected ProgressMonitor monitor;

    public ProgressMonitorTracker() { super(); }

    public ProgressMonitorTracker(ProgressMonitor monitor)
    {
        super();
        this.monitor = monitor;
    }

    public ProgressMonitor getProgressMonitor() { return monitor; }
    public void setProgressMonitor(ProgressMonitor monitor)
    { this.monitor = monitor; }

    public void setRange(int min, int max)
    {
        monitor.setMinimum(min);
        monitor.setMaximum(max);
    }

    public void setProgress(int value) { monitor.setProgress(value); }

    public void setMessage(String message) { monitor.setNote(message); }
}
