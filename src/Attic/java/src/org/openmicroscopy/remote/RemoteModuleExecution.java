/*
 * org.openmicroscopy.remote.RemoteModuleExecution
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

import org.openmicroscopy.*;
import java.util.List;
//import java.util.ArrayList;
import java.util.Iterator;

public class RemoteModuleExecution
    extends RemoteOMEObject
    implements ModuleExecution
{
    static
    {
        addClass("OME::ModuleExecution",RemoteModuleExecution.class);
        addClass("OME::ModuleExecution::ActualInput",
                 RemoteModuleExecution.ActualInput.class);
    }


    public RemoteModuleExecution() { super(); }
    public RemoteModuleExecution(String reference) { super(reference); }

    public Module getModule()
    { return (Module) getRemoteElement(getClass("OME::Module"),
                                       "module"); }
    public void setModule(Module module)
    { setRemoteElement("module",module); }

    public Dataset getDataset()
    { return (Dataset) getRemoteElement(getClass("OME::Dataset"),
                                        "dataset"); }
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
    { return getRemoteListElement(getClass("OME::ModuleExecution::ActualInput"),
                                  "inputs"); }
    public Iterator iterateInputs()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_inputs");
        i.setClass(getClass("OME::ModuleExecution::ActualInput"));
        return i;
    }

    public static class ActualInput
        extends RemoteOMEObject
        implements ModuleExecution.ActualInput
    {
        public ActualInput() { super(); }
        public ActualInput(String reference) { super(reference); }

        public ModuleExecution getModuleExecution()
        { return (ModuleExecution)
                getRemoteElement(getClass("OME::ModuleExecution"),
                                 "module_execution"); }

        public ModuleExecution getInputModuleExecution()
        { return (ModuleExecution)
                getRemoteElement(getClass("OME::ModuleExecution"),
                                 "input_module_execution"); }
        public void setInputModuleExecution(ModuleExecution inputModuleExecution)
        { setRemoteElement("input_module_execution",inputModuleExecution); }

        public Module.FormalInput getFormalInput()
        { return (Module.FormalInput)
                getRemoteElement(getClass("OME::Module::FormalInput"),
                                 "formal_input"); }
        public void setFormalInput(Module.FormalInput formalInput)
        { setRemoteElement("formal_input",formalInput); }
    }
}
