/*
 * org.openmicroscopy.applet.AppletAttributeType
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

public class AppletAttributeType
    extends SimpleAttributeType
{
    public AppletAttributeType(AppletParameters ap, String param)
    {
        super();

        id = ap.getIntParameter(param+"/ID",true,-1);

        setName(ap.getStringParameter(param+"/Name",false));
        setDescription(ap.getStringParameter(param+"/Description",true));

        String g = ap.getStringParameter(param+"/Granularity");
        if (g.equalsIgnoreCase("G"))
        {
            setGranularity(Granularity.GLOBAL);
        } else if (g.equalsIgnoreCase("D")) {
            setGranularity(Granularity.DATASET);
        } else if (g.equalsIgnoreCase("I")) {
            setGranularity(Granularity.IMAGE);
        } else if (g.equalsIgnoreCase("F")) {
            setGranularity(Granularity.FEATURE);
        } else {
            throw new IllegalArgumentException("Illegal granularity: "+param);
        }

        int numColumns = ap.getIntParameter(param+"/Columns",false);
        AttributeType.Column  columns[] = new AttributeType.Column[numColumns];
        for (int i = 0; i < numColumns; i++)
        {
            String colParam = param+"/Column"+i;
            int    id = ap.getIntParameter(colParam+"/ID",true,-1);
            String name = ap.getStringParameter(colParam+"/Name",false);
            String description = ap.getStringParameter(colParam+"/Description",
                                                       true);
            DataTable.Column  dColumn = (DataTable.Column)
                ap.getObjectParameter("DataTable/Column",
                                      colParam+"/DataColumn",
                                      false);

            columns[i] = addColumn(id,name,description,dColumn);
        }

        ap.saveObject("AttributeType",param,this);
        for (int i = 0; i < numColumns; i++)
            ap.saveObject("AttributeType/Column",param+"/Column"+i,columns[i]);
    }
}
