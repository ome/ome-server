/*
 * org.openmicroscopy.applet.AppletDataTable
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




package org.openmicroscopy.applet;

import org.openmicroscopy.*;
import org.openmicroscopy.simple.*;

public class AppletDataTable
    extends SimpleDataTable
{
    public AppletDataTable(AppletParameters ap, String param)
    {
        super();

        id = ap.getIntParameter(param+"/ID",true,-1);
        setTableName(ap.getStringParameter(param+"/TableName",false));
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
        DataTable.Column  columns[] = new DataTable.Column[numColumns];
        for (int i = 0; i < numColumns; i++)
        {
            String colParam = param+"/Column"+i;
            int id = ap.getIntParameter(colParam+"/ID",true,-1);
            String name = ap.getStringParameter(colParam+"/Name",false);
            String description = ap.getStringParameter(colParam+"/Description",
                                                       true);
            String sqlType = ap.getStringParameter(colParam+"/SQLType",
                                                   true);

            columns[i] = addColumn(id,name,description,sqlType);
        }

        ap.saveObject("DataTable",param,this);
        for (int i = 0; i < numColumns; i++)
            ap.saveObject("DataTable/Column",param+"/Column"+i,columns[i]);
    }
}
