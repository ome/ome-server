/*
 * org.openmicroscopy.alligator.SemanticElementTableModel
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




package org.openmicroscopy.alligator;

//import javax.swing.table.*;
//import java.util.List;
import org.openmicroscopy.*;

public class SemanticElementTableModel
    extends ThreadedTableModel
{
    public SemanticElementTableModel(Controller controller) { super(controller); }

    public void update(final SemanticType type)
    {
        new Thread(new Runnable()
            {
                public void run()
                {
                    startLoading();
                    updateList(type.getElements());
                }
            }).start();
    }

    public SemanticType.Element getSemanticElement(int index)
    {
        return (SemanticType.Element) tableList.get(index);
    }

    private static String[] COLUMN_NAMES =
    {"Element","Data Type","Data Column"};

    public String[] getColumnNamesFromList() { return COLUMN_NAMES; }

    public Object getValueAtFromList(int row, int col)
    {
        SemanticType.Element  element = getSemanticElement(row);

        if (col == 0)
        {
            return element.getElementName();
        } else if (col == 1) {
            DataTable.Column  column = element.getDataColumn();
            String sqlType = column.getSQLType();
            if (sqlType.equals("reference"))
                return column.getReferenceType().getName();
            else
                return sqlType;
        } else if (col == 2) {
            DataTable.Column  column = element.getDataColumn();
            DataTable table = column.getDataTable();
            return table.getTableName()+"."+column.getColumnName();
        } else {
            return null;
        }
    }
}
