/*
 * org.openmicroscopy.ds.RemoteTypes
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


package org.openmicroscopy.ds;

import java.util.Map;
import java.util.HashMap;
import org.openmicroscopy.ds.dto.*;

/**
 * <p>Stores the mapping between the Remote class name and Java
 * interface name for each core data class in OME.  (The Remote-side
 * implementations of the remote method calls require the data object
 * types to be specified by their Remote class names.)</p>
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <i>(Internal: $Revision$ $Date$)</i>
 * @since OME2.2
 */

class RemoteTypes
{
    private static Map javaClasses = new HashMap();
    private static Map remoteTypes = new HashMap();
    private static Map javaDTOs = new HashMap();

    private static void addClass(Class javaClass,
                                 String remoteType,
                                 Class dtoClass)
    {
        javaClasses.put(remoteType,javaClass);
        remoteTypes.put(javaClass,remoteType);
        javaDTOs.put(javaClass,dtoClass);
    }

    static
    {
        addClass(Project.class,"Project",
                 ProjectDTO.class);
        addClass(Dataset.class,"Dataset",
                 DatasetDTO.class);
        addClass(Image.class,"Image",
                 ImageDTO.class);
        addClass(Feature.class,"Feature",
                 FeatureDTO.class);

        addClass(DataTable.class,"DataTable",
                 DataTableDTO.class);
        addClass(DataColumn.class,"DataColumn",
                 DataColumnDTO.class);
        addClass(SemanticType.class,"SemanticType",
                 SemanticTypeDTO.class);
        addClass(SemanticElement.class,"SemanticElement",
                 SemanticElementDTO.class);
        addClass(LookupTable.class,"LookupTable",
                 LookupTableDTO.class);
        addClass(LookupTableEntry.class,"LookupTableEntry",
                 LookupTableEntryDTO.class);

        addClass(Module.class,"Module",
                 ModuleDTO.class);
        addClass(FormalInput.class,"FormalInput",
                 FormalInputDTO.class);
        addClass(FormalOutput.class,"FormalOutput",
                 FormalOutputDTO.class);
        addClass(ModuleCategory.class,"ModuleCategory",
                 ModuleCategoryDTO.class);

        addClass(AnalysisChain.class,"AnalysisChain",
                 AnalysisChainDTO.class);
        addClass(AnalysisNode.class,"AnalysisNode",
                 AnalysisNodeDTO.class);
        addClass(AnalysisLink.class,"AnalysisLink",
                 AnalysisLinkDTO.class);
        addClass(AnalysisPath.class,"AnalysisPath",
                 AnalysisPathDTO.class);
        addClass(AnalysisPathEntry.class,"AnalysisPathEntry",
                 AnalysisPathEntryDTO.class);

        addClass(ModuleExecution.class,"ModuleExecution",
                 ModuleExecutionDTO.class);
        addClass(ActualInput.class,"ActualInput",
                 ActualInputDTO.class);
        addClass(NodeExecution.class,"NodeExecution",
                 NodeExecutionDTO.class);
        addClass(ChainExecution.class,"ChainExecution",
                 ChainExecutionDTO.class);
    }

    public static String getRemoteType(Class javaClass)
    {
        String remoteType = (String) remoteTypes.get(javaClass);
        if (remoteType == null)
            throw new DataException(javaClass+" is not a DTO interface");
        return remoteType;
    }

    public static Class getJavaClass(String remoteType)
    {
        Class javaClass = (Class) javaClasses.get(remoteType);
        if (javaClass == null)
            throw new DataException(remoteType+" is not a remote type");
        return javaClass;
    }

    public static Class getDTOClass(Class javaClass)
    {
        Class dtoClass = (Class) javaDTOs.get(javaClass);
        if (dtoClass == null)
            throw new DataException(javaClass+" is not a DTO interface");
        return dtoClass;
    }

}
