/*
 * org.openmicroscopy.ModuleExecution
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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




package org.openmicroscopy;

import java.util.List;
import java.util.Iterator;

/**
 * <p>Represents an execution of an OME analysis module against a
 * dataset of images.  Each actual execution of a module is
 * represented by exactly one <code>ModuleExecution</code>.  If the
 * results of a module execution are reused during the future
 * execution of an analysis chain, no new <code>ModuleExecution</code>
 * is created (although a new {@link ChainExecution} is created).</p>
 *
 * <p><code>Analyses</code> have a notion of <i>dependence</i> which
 * help the analysis engine determine when analysis results are
 * eligible for reuse.  Each <code>ModuleExecution</code> has a dependence of
 * Global, Dataset, or Image.</p>
 *
 * <p>An dependence of Image signifies that the results produced by an
 * analysis module for a given image are independent of which other
 * images are in the dataset being analyzed.  This allows the results
 * of this <code>ModuleExecution</code> to be reused, even if the dataset
 * being executed in the future is different.</p>
 *
 * <p>A dependence of Dataset, on the other hand, signifies that the
 * results are not independent on a per-image basis.  Attributes
 * created by a dataset-dependent <code>ModuleExecution</code> could only be
 * reused if the future analysis is being performed against the exact
 * same dataset.</p>
 *
 * <p>A dependence of Global is rarely seen, and is only possible if
 * the module generates global outputs.  In this case, the distinction
 * between image- and dataset-dependence has no meaning.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */

public interface ModuleExecution
    extends OMEObject
{
    /**
     * Returns the analysis module that was executed.
     * @return the analysis module that was executed.
     */
    public Module getModule();

    /**
     * Sets the analysis module that was executed.
     * @param module the analysis module that was executed.
     */
    public void setModule(Module module);

    /**
     * Returns the dataset that was analyzed.
     * @return the dataset that was analyzed.
     */
    public Dataset getDataset();

    /**
     * Sets the dataset that was analyzed.
     * @param dataset the dataset that was analyzed.
     */
    public void setDataset(Dataset dataset);

    /**
     * Returns the dependence of this analysis.  This will be one of
     * the values defined in {@link Dependence}.
     *
     * @return the dependence of this analysis.
     */
    public int getDependence();

    /**
     * Sets the dependence of this analysis.  <code>dependence</code>
     * must be one of the values defined in {@link Dependence}.
     *
     * @param dependence the dependence of this analysis.
     * @throws IllegalArgumentException if <code>dependence</code> is
     * not one of the values in {@link Dependence}
     */
    public void setDependence(int dependence);

    /**
     * Returns when the analysis was completed.
     * @return when the analysis was completed.
     */
    public String getTimestamp();

    /**
     * Sets when the analysis was completed.
     * @param timestamp when the analysis was completed.
     */
    public void setTimestamp(String timestamp);

    /**
     * Returns the analysis's status.  Current possible values are:
     * <ul>
     * <li><code>RUNNING</code> - The module is still executing.</li>
     * <li><code>FINISHED</code> - The module has finished, and all
     * results are in the database.</li>
     * <li>Anything else - There was an error executing the module.
     * The return value is the error string generated.</li>
     * </ul>
     * @return the analysis's status
     */
    public String getStatus();

    /**
     * Sets the analysis's status.
     * @param status the analyis's status
     */
    public void setStatus(String status);

    /**
     * Returns a list of all of the {@link ModuleExecution.ActualInput
     * ActualInputs} associated with this analysis.
     * @return a {@link List} of {@link ModuleExecution.ActualInput
     * ActualInputs}
     */
    public List getInputs();

    /**
     * Returns an iterator of all of the {@link ModuleExecution.ActualInput
     * ActualInputs} associated with this analysis.
     * @return an {@link Iterator} of {@link ModuleExecution.ActualInput
     * ActualInputs}
     */
    public Iterator iterateInputs();

    /**
     * <p>Specifies where the values for an analysis module's inputs
     * came from.  Each of the module's formal inputs has a single
     * <code>ActualInput</code> for each execution of the module.</p>
     *
     * <p>The module's input is specified by the <code>ModuleExecution</code>
     * that "feeds" it.  All of the attributes of the formal input's
     * semantic type generated by the input analysis are collected and
     * presented as input to the current analysis.</p>
     *
     * @author Douglas Creager
     * @version 2.0
     * @since OME2.0
     */

    public interface ActualInput
        extends OMEObject
    {
        /**
         * Returns the analysis that this actual input is associated
         * with.
         * @return the analysis that this actual input is associated
         * with.
         */
        public ModuleExecution getModuleExecution();

        /**
         * Returns the analysis that provides this actual input with
         * data.
         * @return the analysis that provides this actual input with
         * data.
         */
        public ModuleExecution getInputModuleExecution();

        /**
         * Sets the analysis that provides this actual input with
         * data.
         * @param analysis the analysis that provides this actual
         * input with data.
         */
        public void setInputModuleExecution(ModuleExecution analysis);

        /**
         * Returns the formal input that this actual input provides
         * data for.
         * @return the formal input that this actual input provides
         * data for.
         */
        public Module.FormalInput getFormalInput();

        /**
         * Sets the formal input that this actual input provides data
         * for.
         * @param input the formal input that this actual input
         * provides data for.
         */
        public void setFormalInput(Module.FormalInput input);
    }
}
