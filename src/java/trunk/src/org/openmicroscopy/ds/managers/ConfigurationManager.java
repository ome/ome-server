/*
 * org.openmicroscopy.ds.managers.ConfigurationManager
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.ds.managers;

import java.util.Map;

import org.openmicroscopy.ds.RemoteServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.FieldsSpecification;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.dto.Module;
import org.openmicroscopy.ds.dto.AnalysisChain;

/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class ConfigurationManager
    extends AbstractService
{
    protected InstantiatingCaller icaller = null;

    public ConfigurationManager() { super(); }

    public void initializeService(RemoteServices services)
    {
        super.initializeService(services);
        icaller = (InstantiatingCaller)
            services.getService(InstantiatingCaller.class);
    }

    public Module getAnnotationModule()
    {
        return (Module)
            icaller.dispatch(Module.class,
                             "configAnnotationModule",
                             null);
    }

    public Module getAnnotationModule(FieldsSpecification fs)
    {
        Map fields = fs.getFieldsWanted();
        return (Module)
            icaller.dispatch(Module.class,
                             "configAnnotationModule",
                             new Object[] { fs });
    }

    public Module getOriginalFilesModule()
    {
        return (Module)
            icaller.dispatch(Module.class,
                             "configOriginalFilesModule",
                             null);
    }

    public Module getOriginalFilesModule(FieldsSpecification fs)
    {
        Map fields = fs.getFieldsWanted();
        return (Module)
            icaller.dispatch(Module.class,
                             "configOriginalFilesModule",
                             new Object[] { fs });
    }


    public Module getGlobalImportModule()
    {
        return (Module)
            icaller.dispatch(Module.class,
                             "configGlobalImportModule",
                             null);
    }

    public Module getGlobalImportModule(FieldsSpecification fs)
    {
        Map fields = fs.getFieldsWanted();
        return (Module)
            icaller.dispatch(Module.class,
                             "configGlobalImportModule",
                             new Object[] { fs });
    }

    public Module getDatasetImportModule()
    {
        return (Module)
            icaller.dispatch(Module.class,
                             "configDatasetImportModule",
                             null);
    }

    public Module getDatasetImportModule(FieldsSpecification fs)
    {
        Map fields = fs.getFieldsWanted();
        return (Module)
            icaller.dispatch(Module.class,
                             "configDatasetImportModule",
                             new Object[] { fs });
    }

    public Module getImageImportModule()
    {
        return (Module)
            icaller.dispatch(Module.class,
                             "configImageImportModule",
                             null);
    }

    public Module getImageImportModule(FieldsSpecification fs)
    {
        Map fields = fs.getFieldsWanted();
        return (Module)
            icaller.dispatch(Module.class,
                             "configImageImportModule",
                             new Object[] { fs });
    }

    public AnalysisChain getImportChain()
    {
        return (AnalysisChain)
            icaller.dispatch(AnalysisChain.class,
                             "configImportChain",
                             null);
    }

    public AnalysisChain getImportChain(FieldsSpecification fs)
    {
        Map fields = fs.getFieldsWanted();
        return (AnalysisChain)
            icaller.dispatch(AnalysisChain.class,
                             "configImportChain",
                             new Object[] { fs });
    }

}