function getMode() {
	var theMode = getParm(document.cookie, 'mode', ';');
	return ((theMode == "Floating") || (theMode == "NoFrames")) ? theMode : "Frames";
}
function smOnError (msg, url, lno) {
	self.onerror = oldErrorHandler;
	if (confirm(smSecurityMsg)) {
		savePage = false;
		setTimeout('menuClosed();', 100);
	} else {
		if (getMode() != 'Floating') {document.cookie = 'mode=Floating; path=/';}
		openMenu(index1);
	}
	return true;
}
function menuClosed() {
	var currentMode = getMode();
	if (currentMode == 'Floating') {
		document.cookie = 'mode=Frames; path=/';
		currentMode = getMode();
		if (currentMode != 'Frames') {
			alert(smCookieMsg);
			openMenu(index1);
		}
	}
	if (currentMode == 'Floating') {
		openMenu(index1);
	} else {
		var dest = '';
		var okToGo = true;
		if (savePage) {
			if (canOnError) {
				oldErrorHandler = self.onerror;
				self.onerror = smOnError;
			}
			var l = contentWin.location;
			var p = l.pathname;
			if (canOnError) {self.onerror = oldErrorHandler;}
			if (p) {
				dest = fixPath(p) + l.search;
			} else {
				if (!confirm(smSecurityMsg)) {okToGo = false;}
			}
		}
		if (okToGo) {
			if (currentMode == 'NoFrames') {
				dest = (index3 == '') ? ((dest == '') ? '/' : dest) : index3;
			} else {
				dest = index1 + ((dest == '') ? '' : '&content=' + escape(dest));
			}
			theMenu = theBrowser = imgStore = JoustMenu = null;
			setTimeout('self.location.href = "' + dest + '";', 10);
		}
	}
}
function closeMenu() {
	if (JoustMenu != null) {
		if (JoustMenu.myOpener) {JoustMenu.myOpener = null;}
		if (JoustMenu.theMenu) {JoustMenu.close();}
	}
}
function setGlobals() {
	if ((JoustMenu != null) && pageLoaded) {
		theMenu = JoustMenu.theMenu;
		theBrowser = JoustMenu.theBrowser;
		imgStore = JoustMenu.imgStore;
		savePage = theMenu.savePage;
		contentWin = eval('self.' + theMenu.contentFrame);
		canOnError = theBrowser.canOnError;
		smCookieMsg = JoustMenu.smCookieMsg;
		smSecurityMsg = JoustMenu.smSecurityMsg;
		jsErrorMsg = JoustMenu.jsErrorMsg;
		if (canOnError) {self.onerror = defOnError;}
	} else {
		setTimeout('setGlobals();', 100);
	}
}
function loaded() {
	pageLoaded = true;
}
function setStatus(theText) {
	self.status = theText;
	if (theBrowser.canOnMouseOut == false) {
		clearTimeout(statusTimeout);
		statusTimeout = setTimeout('clearStatus()', 5000);}
	return true;
}
function clearStatus() {
	self.status = '';
}
function fixPath(p) {
	if (p.substring(0,2) == '/:') {p = p.substring(p.indexOf('/', 2), p.length);}
	var i = p.indexOf('\\', 0);
	while (i >= 0) {
		p = p.substring(0,i) + '/' + p.substring(i+1,p.length);
		i = p.indexOf('\\', i);
	}
	return p;
}
function getParm(string, parm, delim) {
     // returns value of parm from string
     if (string.length == 0) {return '';}
	 var sPos = string.indexOf(parm + "=");
     if (sPos == -1) {return '';}
     sPos = sPos + parm.length + 1;
     var ePos = string.indexOf(delim, sPos);
     if (ePos == -1) {ePos = string.length;}
     return unescape(string.substring(sPos, ePos));
}
function pageFromSearch(def, selIt) {
	var s = self.location.search;
	if ((s == null) || (s.length < 1)) {return def;}
	var p = getParm(s, 'page', '&');
	p = (p != '') ? fixPath(p) : def;
	return p;
}
function openMenu(url, features) {
	if (features) {menuWinFeatures = features;}
	JoustMenu = window.open(url, "JoustMenu", menuWinFeatures);
	if (JoustMenu.opener == null) {
		JoustMenu.opener = self;
	}
	JoustMenu.focus();
}
function defOnError(msg, url, lno) {
	if (jsErrorMsg == '') {
		return false;
	} else {
		alert(jsErrorMsg + '.\n\nError: ' + msg + '\nPage: ' + url + '\nLine: ' + lno + '\nBrowser: ' + navigator.userAgent);
		return true;
	}
}

var JoustMenu;
var theMenu;
var theBrowser;
var imgStore;
var contentWin;
var savePage = true;
var pageLoaded = false;
var JoustFrameset = true;
var menuWinFeatures = '';
var canOnError = false;
var oldErrorHandler;
var smCookieMsg = '';
var smSecurityMsg = '';
var jsErrorMsg = '';

if (getMode() != 'Floating') {document.cookie = 'mode=Floating; path=/';}

//	############################   End of Joust   ############################

self.defaultStatus = "";

index1 = '/perl2/serve.pl?Page=OME::Web::Home';
index2 = '/perl2/serve.pl?Page=OME::Web::Home&Float=true';
index3 = '/html/noOp.html';

// Break out of any frames.
if (top.location != location) {
	top.location.href = document.location.href ;
}

function updatePage(page) {
	if(page == null) 
		page = '/html/noOp.html';
	var thePage = pageFromSearch(page, true);
	self.text.location.href = thePage;
}
