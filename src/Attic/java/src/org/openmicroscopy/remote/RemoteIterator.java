/*
 * org.openmicroscopy.remote.RemoteIterator;
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




package org.openmicroscopy.remote;

//import org.openmicroscopy.*;
import java.util.Iterator;
import java.util.NoSuchElementException;

public class RemoteIterator
    extends RemoteObject
    implements Iterator, RemoteConstants
{
    static
    {
        RemoteObjectCache.addClass("OME::Factory::Iterator",RemoteIterator.class);
    }

    protected String perlClass;
    protected String nextReference;
    protected boolean haveNextReference = false;

    public RemoteIterator() { super(); }

    public RemoteIterator(RemoteSession session, String reference)
    {
        super(session,reference);
        this.perlClass = null;
    }

    public RemoteIterator(String perlClass) 
    { 
        super();
        this.perlClass = perlClass;
    }

    public RemoteIterator(String perlClass,
                          RemoteSession session,
                          String reference)
    {
        super(session,reference);
        this.perlClass = perlClass;
    }

    public void setClass(String perlClass) { this.perlClass = perlClass; }

    protected void cacheNextReference()
    {
        if (haveNextReference)
            return;

        nextReference = ((String) caller.dispatch(this,"next"));

        haveNextReference = true;
    }

    public boolean hasNext()
    {
        cacheNextReference();
        return ((nextReference != null) && (!nextReference.equals("")) &&
		(!nextReference.equals(NULL_REFERENCE)));
    }

    public Object next()
    {
        if (hasNext())
        {
            RemoteObject retval = getRemoteSession().getObjectCache().
                getObject(perlClass,nextReference);
            nextReference = null;
            haveNextReference = false;
            return retval;
        } else {
            throw new NoSuchElementException("No more elements");
        }
    }

    public void remove()
    {
        throw new UnsupportedOperationException("Cannot remove from a RemoteIterator");
    }
}
