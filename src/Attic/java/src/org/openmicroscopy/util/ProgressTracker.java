/*
 * org.openmicroscopy.util.ProgressTracker;
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

/**
 * <p>Provides provides a single interface for progress trackers.
 * This allows an operation class to provide the ability to monitor
 * its progress without being tied to a single progress tracker, such
 * as {@link javax.swing.JProgressBar} or {@link
 * javax.swing.ProgressMonitor}.</p>
 *
 * <p><b>Please note</b> that the standard Swing progress meters
 * expect <code>int</code>s for their inputs, whereas this interface
 * defines them to be <code>long</code>s.  The {@link
 * IntProgressTracker} abstract class contains the necessary logic to
 * scale the <code>long</code>s down to <code>int</code>s if they
 * would cause an overflow.</p>
 *
 * @author Douglas Creager
 * @since OME2.1
 * @version 2.1
 */

public interface ProgressTracker
{
    public void setRange(long min, long max);
    public void setProgress(long value);
    public void setMessage(String message);
}
