/*
 * org.openmicroscopy.remote.RemoteModule
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

public class RemoteModule
    extends RemoteOMEObject
    implements Module
{
    static
    {
        addClass("OME::Module",RemoteModule.class);
        addClass("OME::Module::FormalInput",RemoteModule.FormalInput.class);
        addClass("OME::Module::FormalOutput",RemoteModule.FormalOutput.class);
    }

    public RemoteModule() { super(); }
    public RemoteModule(String reference) { super(reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public String getLocation()
    { return getStringElement("location"); }
    public void setLocation(String location)
    { setStringElement("location",location); }

    public String getModuleType()
    { return getStringElement("module_type"); }
    public void setModuleType(String moduleType)
    { setStringElement("module_type",moduleType); }

    public ModuleCategory getCategory()
    { return (ModuleCategory)
            getRemoteElement(getClass("OME::Module::Category"),
                             "category"); }
    public void setCategory(ModuleCategory category)
    { setRemoteElement("category",category); }

    public String getDefaultIterator()
    { return getStringElement("default_iterator"); }
    public void setDefaultIterator(String defaultIterator)
    { setStringElement("default_iterator",defaultIterator); }

    public String getNewFeatureTag()
    { return getStringElement("new_feature_tag"); }
    public void setNewFeatureTag(String newFeatureTag)
    { setStringElement("new_feature_tag",newFeatureTag); }

    public String getExecutionInstructions()
    { return getStringElement("execution_instructions"); }
    public void setExecutionInstructions(String executionInstructions)
    { setStringElement("execution_instructions",executionInstructions); }

    public List getInputs()
    { return getCachedRemoteListElement(getClass("OME::Module::FormalInput"),
                                        "inputs"); }
    public Iterator iterateInputs()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_inputs");
        i.setClass(getClass("OME::Module::FormalInput"));
        return i;
    }

    public List getOutputs()
    { return getCachedRemoteListElement(getClass("OME::Module::FormalOutput"),
                                        "outputs"); }
    public Iterator iterateOutputs()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_outputs");
        i.setClass(getClass("OME::Module::FormalOutput"));
        return i;
    }

    public List getExecutions()
    { return getRemoteListElement(getClass("OME::ModuleExecution"),
                                  "module_executions"); }
    public Iterator iterateExecutions()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_module_executions");
        i.setClass(getClass("OME::ModuleExecution"));
        return i;
    }

    public String toString() { return getName(); }

    public static class FormalParameter
        extends RemoteOMEObject
        implements Module.FormalParameter
    {
        public FormalParameter() { super(); }
        public FormalParameter(String reference) { super(reference); }

        public Module getModule()
        { return (Module)
                getRemoteElement(getClass("OME::Module"),
                                 "module"); }

        public String getParameterName()
        { return getStringElement("name"); }
        public void setParameterName(String parameterName)
        { setStringElement("name",parameterName); }

        public String getParameterDescription()
        { return getStringElement("description"); }
        public void setParameterDescription(String description)
        { setStringElement("description",description); }

        public SemanticType getSemanticType()
        { return (SemanticType) 
                getRemoteElement(getClass("OME::SemanticType"),
                                 "semantic_type"); }
        public void setSemanticType(SemanticType attributeType)
        { setRemoteElement("semantic_type",attributeType); }

        public boolean getOptional()
        { return getBooleanElement("optional"); }
        public void setOptional(boolean optional)
        { setBooleanElement("optional",optional); }

        public boolean getList()
        { return getBooleanElement("list"); }
        public void setList(boolean list)
        { setBooleanElement("list",list); }
    }

    public static class FormalInput
        extends FormalParameter
        implements Module.FormalInput
    {
        public FormalInput() { super(); }
        public FormalInput(String reference) { super(reference); }

        public LookupTable getLookupTable()
        { return (LookupTable) 
                getRemoteElement(getClass("OME::LookupTable"),
                                 "lookup_table"); }
        public void setLookupTable(LookupTable lookupTable)
        { setRemoteElement("lookup_table",lookupTable); }

        public boolean getUserDefined()
        { return getBooleanElement("user_defined"); }
        public void setUserDefined(boolean userDefined)
        { setBooleanElement("user_defined",userDefined); }
    }

    public static class FormalOutput
        extends FormalParameter
        implements Module.FormalOutput
    {
        public FormalOutput() { super(); } 
        public FormalOutput(String reference) { super(reference); }

        public String getFeatureTag()
        { return getStringElement("feature_tag"); }
        public void setFeatureTag(String featureTag)
        { setStringElement("feature_tag",featureTag); }
    }
}
