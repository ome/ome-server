/*
 * org.openmicroscopy.Analysis
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

package org.openmicroscopy;

import java.util.List;
import java.util.Iterator;

public interface Analysis
    extends OMEObject
{
    public Module getModule();
    public void setModule(Module module);

    public Dataset getDataset();
    public void setDataset(Dataset dataset);

    public int getDependence();
    public void setDependence(int dependence);

    public String getTimestamp();
    public void setTimestamp(String timestamp);

    public String getStatus();
    public void setStatus(String status);

    public List getInputs();
    public Iterator iterateInputs();

    public interface ActualInput
        extends OMEObject
    {
        public Analysis getAnalysis();

        public Analysis getInputAnalysis();
        public void setInputAnalysis(Analysis analysis);

        public Module.FormalInput getFormalInput();
        public void setFormalInput(Module.FormalInput input);
    }
}
