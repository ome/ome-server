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
 * Written by:    Andrea Falconi <a.falconi@dundee.ac.uk> & 
 * 				  Harry Hochheiser <hsh@nih.gov>
 *
 */
 
package org.openmicroscopy.vis.ome;

import java.io.BufferedInputStream;
import java.io.PrintWriter;
import java.io.File;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;


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
    
    private static final String CACHE_DIR="/.ome-vis-cache/";
    private static final String IMAGE_DIR="/images";
    
	private String      host;
	private String      username;
	private String      password;
	private String      sessionKey;
  
  	private File cacheDirFile;
  
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
		
		// create cache if it doesn't exist.
		String dir = System.getProperty("user.dir");
		String cacheDir = new String(dir+CACHE_DIR+host+IMAGE_DIR);
		System.err.println("cache dir is "+cacheDir);
		// make it if it doesn't exist
		cacheDirFile = new File(cacheDir); 
		cacheDirFile.mkdirs();
		
	}
  
	public BufferedImage getThumbnail(int id) throws Exception {
		URL     thumbURL = new URL("http://"+host+
					"/perl2/serve.pl?Page=OME::Web::ThumbWrite&ImageID="+id);
		// get file name
		String imageFileName = new String("thumb-"+id+".jpg");
		File imageFile = new File(cacheDirFile,imageFileName);
		BufferedImage bufImage;
		
		if (!imageFile.exists()) { 
			// if it doesn't exist, grab it.
			System.err.println("getting image from network");
			URLConnection   conn = thumbURL.openConnection();
			//set session key (HTTP header)
			conn.setRequestProperty("Cookie", sessionKey); 

			//send request and get response stream
			BufferedInputStream     
				response = new BufferedInputStream(conn.getInputStream()); 
    
		
			bufImage = ImageIO.read(response);
			response.close();
			
			// write it
			ImageIO.write(bufImage,"jpg",imageFile);
		}
		else { // get it from cache.
			System.err.println("getting cached image");
			bufImage = ImageIO.read(imageFile);
		}
		return bufImage;
	}
}
