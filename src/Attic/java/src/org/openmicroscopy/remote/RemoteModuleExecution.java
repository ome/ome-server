/*
 * org.openmicroscopy.remote.RemoteAnalysis
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

package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteAnalysis
    extends RemoteOMEObject
    implements Analysis
{
    static { RemoteObject.addClass("OME::Analysis",
                                   RemoteAnalysis.class); }

    public RemoteAnalysis() { super(); }
    public RemoteAnalysis(String reference) { super(reference); }

    public Module getModule()
    { return (Module) getRemoteElement(RemoteModule.class,"program"); }
    public void setModule(Module module)
    { setRemoteElement("program",module); }

    public Dataset getDataset()
    { return (Dataset) getRemoteElement(RemoteDataset.class,"dataset"); }
    public void setDataset(Dataset dataset)
    { setRemoteElement("dataset",dataset); }

    public int getDependence()
    {
        String dependence = getStringElement("dependence");
        if (dependence.equals("G"))
            return Dependence.GLOBAL;
        else if (dependence.equals("D"))
            return Dependence.DATASET;
        else if (dependence.equals("I"))
            return Dependence.IMAGE;
        else
            throw new IllegalArgumentException("Got a bad dependence");
    }
    public void setDependence(int dependence)
    {
        if (dependence == Dependence.GLOBAL)
            setStringElement("dependence","G");
        else if (dependence == Dependence.DATASET)
            setStringElement("dependence","D");
        else if (dependence == Dependence.IMAGE)
            setStringElement("dependence","I");
        else
            throw new IllegalArgumentException("Got a bad dependence");
    }

    public String getTimestamp()
    { return getStringElement("timestamp"); }
    public void setTimestamp(String timestamp)
    { setStringElement("timestamp",timestamp); }

    public String getStatus()
    { return getStringElement("status"); }
    public void setStatus(String status)
    { setStringElement("status",status); }

    public List getInputs()
    { return getRemoteListElement(ActualInput.class,"inputs"); }
    public Iterator iterateInputs()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_inputs");
        i.setClass(ActualInput.class);
        return i;
    }

    public static class ActualInput
        extends RemoteOMEObject
        implements Analysis.ActualInput
    {
        static { RemoteObject.addClass("OME::Analysis::ActualInput",
                                       RemoteAnalysis.ActualInput.class); }

        public ActualInput() { super(); }
        public ActualInput(String reference) { super(reference); }

        public Analysis getAnalysis()
        { return (Analysis)
              getRemoteElement(RemoteAnalysis.class,"analysis"); }

        public Analysis getInputAnalysis()
        { return (Analysis)
              getRemoteElement(RemoteAnalysis.class,"input_analysis"); }
        public void setInputAnalysis(Analysis inputAnalysis)
        { setRemoteElement("input_analysis",inputAnalysis); }

        public Module.FormalInput getFormalInput()
        { return (Module.FormalInput)
              getRemoteElement(RemoteModule.FormalInput.class,"formal_input"); }
        public void setFormalInput(Module.FormalInput formalInput)
        { setRemoteElement("formal_input",formalInput); }
    }
}
