/*
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
package org.openmicroscopy.ds.tests;

import java.net.MalformedURLException;
import java.util.Iterator;
import java.util.List;

import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.DataServer;
import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.ServerVersion;
import org.openmicroscopy.ds.dto.ActualInput;
import org.openmicroscopy.ds.dto.ChainExecution;
import org.openmicroscopy.ds.dto.ModuleExecution;
import org.openmicroscopy.ds.dto.Module;
import org.openmicroscopy.ds.dto.FormalInput;
import org.openmicroscopy.ds.dto.FormalOutput;
import org.openmicroscopy.ds.dto.SemanticType;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.managers.HistoryManager;
/**
 * 
 *
 * @author <br>Harry Hochheiser &nbsp;&nbsp;&nbsp;
 * 	<A HREF="mailto:hsh@nih.gov">hsh@nih.gov</A>
 *
 *  @version 2.2
 * <small>
 * </small>
 * @since OME2.2
 */
public class HistoryTest {

	/** 
	 * Update the following variables as appropriate for your local installation.
	 */
	private static final String SHOOLA_URL="http://hsh-tibook.local/shoola";
	private static final String USER ="hsh";
	private static final String PASS = "foobar";
	
	private static final int MEX_ID=4211;
	private static final int CHEX_ID=36;
	
	private DataServices services;
	private HistoryManager historyManager;
	private DataFactory factory;
	
	public HistoryTest() {
		super();
		
		try {
			// construct connection to omeds
			services = DataServer.getDefaultServices(SHOOLA_URL);
			// doe the basic login
			initializeHistoryManager(services);
			if (historyManager != null) {
				getMexData();
				getHistory();
				
			}
		}
		catch (MalformedURLException e) {
			System.err.println("Improperly specified Shoola URL: "+SHOOLA_URL);
			System.exit(0);
		}	
	}
	
	private void initializeHistoryManager(DataServices services) {
		System.err.println("trying to get data...");
		//  login 
		RemoteCaller remote = services.getRemoteCaller();
		remote.login(USER,PASS);
		// test with server version
		ServerVersion ver = remote.getServerVersion();
		System.err.println("Server Version "+ ver);
		
		// retrieve the HistoryManager which is used for data requests
		historyManager =  (HistoryManager) services.getService(HistoryManager.class);
		factory =  (DataFactory) services.getService(DataFactory.class);
	}
	
	
	private void getHistory() {
		
		Integer mexID = new Integer(MEX_ID);
		
		List history = historyManager.getMexDataHistory(mexID);
		
		System.err.println("dumping MEX history for "+mexID);
		dumpHistoryList(history);
		
		Integer chexID = new Integer(CHEX_ID);
		history = historyManager.getChainDataHistory(chexID);
		
		System.err.println("dumping chain history for chain exec "+chexID);
		dumpHistoryList(history);
		
		
	}
	
	private void dumpHistoryList(List history) {
		Iterator iter = history.iterator();
		while (iter.hasNext()) {
			ModuleExecution mex = (ModuleExecution)iter.next();
			dumpHistory(mex);
		}
	}
	
	private void dumpHistory(ModuleExecution mex) {
		System.err.println("\n\nmex... "+mex.getID()+", module . "+
				mex.getModule().getID()+", "+mex.getModule().getName());
		List inputs = mex.getInputs();
		Iterator iter = inputs.iterator();
		while (iter.hasNext()) {
			ActualInput inp = (ActualInput) iter.next();
			dumpInput(inp);
		}
	}
	
	private void dumpInput(ActualInput inp) {
		System.err.println("input.. "+inp.getID()+", mex is "+inp.getModuleExecution().getID());
		System.err.println("input mex is "+inp.getInputMEX().getID());
		FormalInput fin =  inp.getFormalInput();
		System.err.println("formal input.."+fin.getID()+","+fin.getName());
		SemanticType st = fin.getSemanticType();
		System.err.println("semantic type..."+st.getID()+","+st.getName());
		FormalOutput fout = inp.getFormalOutput();
		if (fout != null) {
			System.err.println("formal output.."+fout.getID()+","+fout.getName());
			st = fout.getSemanticType();
			if (st != null)
				System.err.println("semantic type..."+st.getID()+","+st.getName());
			else 
				System.err.println("untyped..");
		}
		else 
			System.err.println("no formal output available");
		
	}
	
	public void getMexData() {
		Criteria c = new Criteria();
		c.addWantedField("id");
		c.addWantedField("module");
		c.addWantedField("module","name");
		c.addWantedField("predecessors");
		c.addWantedField("predecessors","id");
		c.addWantedField("predecessors","module");
		c.addWantedField("predecessors.module","name");
		
		c.addWantedField("successors");
		c.addWantedField("successors","id");
		c.addWantedField("successors","module");
		c.addWantedField("successors.module","name");
		
		c.addWantedField("inputs");
		c.addWantedField("inputs","id");
		c.addWantedField("inputs","input_module_execution");
		c.addWantedField("inputs.input_module_execution","id");
		
		c.addWantedField("consumed_outputs");
		c.addWantedField("consumed_outputs","id");
		c.addWantedField("consumed_outputs","module_execution");
		c.addWantedField("consumed_outputs.module_execution","id");
		
		c.addWantedField("chain_executions");
		c.addWantedField("chain_executions","id");
		c.addWantedField("chain_executions","analysis_chain");
		c.addWantedField("chain_executions.analysis_chain","id");
		c.addWantedField("chain_executions.analysis_chain","name");
		// this value might needto be changed for other installations.
		c.addFilter(	"id", new Integer(MEX_ID));
		
		// Standard DataFactory call for retrieving object of a given class,
		// according to certain criteria
		ModuleExecution mex = (ModuleExecution) factory.retrieve(ModuleExecution.class,c);
		Module mod = mex.getModule();
		
		System.err.println("Module execution: "+mex.getID());
		System.err.println("Module "+mod.getID()+", "+mod.getName());
		
		System.err.println("Predecessor count : "+mex.countPredecessors());
		List preds = mex.getPredecessors();
		Iterator iter = preds.iterator();
		while (iter.hasNext()) {
			ModuleExecution pred = (ModuleExecution) iter.next();
			System.err.println(pred.getID()+", "+pred.getModule().getName());
		}
		
		System.err.println("Sucessor count : "+mex.countSuccessors());
		List succs = mex.getSuccessors();
		iter = succs.iterator();
		while (iter.hasNext()) {
			ModuleExecution succ = (ModuleExecution) iter.next();
			System.err.println(succ.getID()+", "+succ.getModule().getName());
		}
		
		System.err.println("input count... "+mex.countInputs());
		List inputs = mex.getInputs();
		iter = inputs.iterator();
		while (iter.hasNext()) {
			ActualInput inp = (ActualInput) iter.next();
			System.err.println(inp.getID()+", "+inp.getInputMEX().getID());
		}
		
		System.err.println("output count... "+mex.countConsumedOutputs());
		List outputs = mex.getConsumedOutputs();
		iter = outputs.iterator();
		while (iter.hasNext()) {
			ActualInput outp = (ActualInput) iter.next();
			System.err.println(outp.getID()+", "+outp.getModuleExecution().getID());
		}
		
		System.err.println("chex count... "+mex.countChainExecutions());
		List chexes = mex.getChainExecutions();
		iter = chexes.iterator();
		while (iter.hasNext()) {
			ChainExecution chex = (ChainExecution) iter.next();
			System.err.println(chex.getID()+", "+chex.getChain().getName());
		}
	}
	

	public static void main(String[] args) {
		new HistoryTest();
	}
}