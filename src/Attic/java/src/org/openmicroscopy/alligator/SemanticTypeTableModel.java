/*
 * org.openmicroscopy.alligator.SemanticTypeTableModel
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

import javax.swing.table.*;
import java.util.List;
import org.openmicroscopy.*;

public class SemanticTypeTableModel
    extends ThreadedTableModel
{
    public SemanticTypeTableModel(Controller controller) { super(controller); }

    public void update(final Factory factory)
    {
        new Thread(new Runnable()
            {
                public void run()
                {
                    startLoading();
                    updateList(factory.findObjects("OME::SemanticType",null));
                }
            }).start();
    }

    public SemanticType getSemanticType(int index)
    {
        return (SemanticType) tableList.get(index);
    }

    private static String[] COLUMN_NAMES =
    {""};

    public String[] getColumnNamesFromList() { return COLUMN_NAMES; }

    public Object getValueAtFromList(int row, int col)
    {
        SemanticType  type = getSemanticType(row);

        if (col == 0)
            return type.getName();
        else
            return null;
    }
}
