/*
 * org.openmicroscopy.Module
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

public interface Module
    extends OMEObject
{
    public String getName();
    public void setName(String name);

    public String getDescription();
    public void setDescription(String description);

    public String getLocation();
    public void setLocation(String location);

    public String getModuleType();
    public void setModuleType(String moduleType);

    public String getCategory();
    public void setCategory(String category);

    public String getDefaultIterator();
    public void setDefaultIterator(String defaultIterator);

    public String getNewFeatureTag();
    public void setNewFeatureTag(String newFeatureTag);

    public String getExecutionInstructions();
    public void setExecutionInstructions(String executionInstructions);

    public List getInputs();
    public Iterator iterateInputs();

    public List getOutputs();
    public Iterator iterateOutputs();

    public List getAnalyses();
    public Iterator iterateAnalyses();

    public interface FormalParameter
        extends OMEObject
    {
        public Module getModule();

        public String getParameterName();
        public void setParameterName(String parameterName);

        public String getParameterDescription();
        public void setParameterDescription(String parameterDescription);

        public SemanticType getSemanticType();
        public void setSemanticType(SemanticType attributeType);

        public boolean getOptional();
        public void setOptional(boolean optional);

        public boolean getList();
        public void setList(boolean list);
    }
        

    public interface FormalInput extends FormalParameter
    {
        public LookupTable getLookupTable();
        public void setLookupTable(LookupTable table);

        public boolean getUserDefined();
        public void setUserDefined(boolean userDefined);
    }


    public interface FormalOutput extends FormalParameter
    {
        public String getFeatureTag();
        public void setFeatureTag(String featureTag);
    }

}
