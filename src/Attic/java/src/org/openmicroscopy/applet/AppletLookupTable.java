/*
 * org.openmicroscopy.applet.AppletLookupTable
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

package org.openmicroscopy.applet;

import org.openmicroscopy.*;
import org.openmicroscopy.simple.*;

public class AppletLookupTable
    extends SimpleLookupTable
{
    public AppletLookupTable(AppletParameters ap, String param)
    {
        super();

        setName(ap.getStringParameter(param+"/Name",false));
        setDescription(ap.getStringParameter(param+"/Description",true));

        int numEntries = ap.getIntParameter(param+"/Entries",false);
        LookupTable.Entry  entries[] = new LookupTable.Entry[numEntries];
        for (int i = 0; i < numEntries; i++)
        {
            String entryParam = param+"/Entry"+i;
            String value = ap.getStringParameter(entryParam+"/Value",false);
            String label = ap.getStringParameter(entryParam+"/Label",false);

            entries[i] = addEntry(value,label);
        }

        ap.saveObject("LookupTable",param,this);
        for (int i = 0; i < numEntries; i++)
            ap.saveObject("LookupTable/Entry",param+"/Entry"+i,entries[i]);
    }
}
