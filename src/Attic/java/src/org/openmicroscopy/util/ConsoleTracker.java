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

import java.io.PrintStream;

/**
 * A simple progress tracker which prints to a {@link PrintStream}
 * (defaults to standard out).  Each time the value or message is
 * changed, a percentage value is printed to standard out.
 *
 * @author Douglas Creager
 * @since OME2.1
 * @version 2.1
 */

public class ConsoleTracker
    implements ProgressTracker
{
    protected long min = 0, max = 0, value = 0;
    protected String message = "";
    protected PrintStream out;

    public ConsoleTracker()
    {
        this(System.out);
    }

    public ConsoleTracker(PrintStream out)
    {
        super();
        this.out = out;
    }

    public void setRange(long min, long max)
    {
        this.min = min;
        this.max = max;
    }

    public void setProgress(long value)
    {
        this.value = value;
        printProgress();
    }

    public void setMessage(String message)
    {
        this.message = message;
        printProgress();
    }

    private int getPercentage()
    {
        long num = value-min;
        long den = max-min;
        double percent = num*100.0/den;
        return (int) percent;
    }

    private void printProgress()
    {
        int percent = getPercentage();
        String percentString = Integer.toString(percent);
        while (percentString.length() < 3)
            percentString = " "+percentString;

        if (message == null)
        {
            out.println(percent+"%");
        } else {
            out.println(percent+"% "+message);
        }
    }
}

