/*
 * org.openmicroscopy.util.IntProgressTracker;
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
 * <p>Provides the logic for scaling down the <code>long</code>
 * progress value required by the {@link ProgressTracker} interface
 * into the <code>int</code> values which are required by the standard
 * Swing progress meters.</p>
 *
 * @author Douglas Creager
 * @since OME2.1
 * @version 2.1
 */

public abstract class IntProgressTracker
    implements ProgressTracker
{
    protected long fudgeFactor = 1;

    public IntProgressTracker() { super(); }

    protected void setFudge(long max)
    {
        // If the maximum value won't overflow, then no fudge is
        // necessary
        if (max <= Integer.MAX_VALUE)
        {
            fudgeFactor = 1;
        } else {
            // This should be the minimum divisor which brings the
            // maximum value into the range of an int.

            long newFudge = (max/Integer.MAX_VALUE);
            while (max/newFudge > Integer.MAX_VALUE) newFudge++;

            fudgeFactor = newFudge;
        }
    }

    protected int fudgeLong(long value)
    {
        return (int) (value/fudgeFactor);
    }

    public void setRange(long min, long max)
    {
        setFudge(max);
        setRange(fudgeLong(min),fudgeLong(max));
    }

    public void setProgress(long value)
    {
        setProgress(fudgeLong(value));
    }

    public abstract void setRange(int min, int max);
    public abstract void setProgress(int value);
    public abstract void setMessage(String message);
}
