/*
 * org.openmicroscopy.vis.chains.ome.Modules
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
 * Written by:    Andrea Falconi <a.falconi@dundee.ac.uk>
 *
 */
 
package org.openmicroscopy.vis.ome;

import java.io.BufferedInputStream;
import java.io.PrintWriter;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import javax.swing.ImageIcon;
import java.awt.Image;


/** 
 * As of Dec. '03, the OME Remote Framework does not support provision of 
 * image thumbnails over XMLRPC. This is a hack-ish workaround to get those
 * thumbnails via a web interface to OME, presumably running on the same
 * host as the remote framework server.
 * 
 * This should be eliminated and replaced with RemoteFramework calls for 
 * generating thumbnails as soon as possible...
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class ThumbnailAgent {
    
	private String      host;
	private String      username;
	private String      password;
	private String      sessionKey;
  
  
	public ThumbnailAgent(String host, String username, String password) {

		this.host = host;
		this.username = username;
		this.password = password;
	}
  
	public void initialize() throws Exception {
		URL     webUI = new URL("http://"+host+
					"/perl2/serve.pl?Page=OME::Web::Login");

		URLConnection   conn = webUI.openConnection();  //set up connection

		conn.setDoOutput(true);  //allow to send data
    
		//build POST request to do login
		PrintWriter     loginRequest = new PrintWriter(conn.getOutputStream());

		loginRequest.println("username="+URLEncoder.encode(username, "US-ASCII")+
							"&password="+URLEncoder.encode(password, "US-ASCII")+
							"&execute=1");
		loginRequest.close();
    
		//extract session key from response
		String  s = conn.getHeaderField("Set-Cookie");
		s = s.trim();
		sessionKey = s.substring(0, s.indexOf(';'));  //"SESSION_KEY=blahblah"
		System.err.println(" session key is "+sessionKey);

	}
  
	public Image getThumbnail(int id) throws Exception {
		URL     thumbURL = new URL("http://"+host+
					"/perl2/serve.pl?Page=OME::Web::ThumbWrite&ImageID="+id);
		URLConnection   conn = thumbURL.openConnection();
		//set session key (HTTP header)
		conn.setRequestProperty("Cookie", sessionKey); 

		//send request and get response stream
		BufferedInputStream     
			response = new BufferedInputStream(conn.getInputStream()); 
    
		//read response as stream of bytes
		byte[]      buf = new byte[4096]; //4Kb
		int i  =0 ;
		for(int value=0; (value=response.read()) != -1; ++i) {
			buf[i] = (byte)(value&0xFF);
			if( i == buf.length-1 ) {
			//	System.err.println("read 4096 bytes. copying..");
				byte[]  tmp = new byte[buf.length+1024];
				System.arraycopy(buf, 0, tmp, 0, buf.length);
				buf = tmp;
			}
		}
		//System.err.println("read "+i+" image bytes");
		response.close();
		//build image from data (will work for jpeg and gif only)
		ImageIcon res = new ImageIcon(buf);
		return res.getImage(); 
	}
}
