// HSH 23 Feb 2006
// experimenting with callbacks 



RenderPage = '/perl2/serve.pl?Page=OME::Web::DBObjRender';

var xmlhttp;



function changeCategoryGroup(object) {
	 var id = object.options[object.selectedIndex].value;
	 var url = RenderPage+"&ID="+id;
	 url += "&Mode=list_of_options&Type=@CategoryGroup";
	 url += "&Accessor=Category&Output=XML";

	 xmlhttp = new XMLHttpRequest;
	 xmlhttp.onreadystatechange = updateCategory;
	 xmlhttp.open("GET",url,true);
	 xmlhttp.send(null);
}


function updateCategory() {
	 if (xmlhttp.readyState == 4) {
	    var cats = document.getElementById("Category");
	    var optCount = cats.length;

	    for (i = optCount-1; i > 0; i--) {
   		    cats.remove(i);
	    }

	    var serializer = new XMLSerializer();
	    var txt = xmlhttp.responseText;

	    // do the items
            var select = buildSelect();
	    var selectString = serializer.serializeToString(select);
	    
	    var span = document.getElementById("catSelect");
	    span.innerHTML="";
	    span.innerHTML=selectString;
     }
}

function buildSelect() {

	 var select = document.createElement("select");
	 // set name
	 setNodeAttribute(select,"name","Category");
	 // set id
	 setNodeAttribute(select,"id","Category");

	 // add "all"
	 var opt = document.createElement("option");
	 var node = document.createTextNode("All");
	 opt.value = "All";
	 opt.appendChild(node);
	 select.appendChild(opt);
	 
	 

	 // add the rest
         var items = xmlhttp.responseXML.getElementsByTagName("OPTION");
	 for (var i =0; i < items.length;i++) {
	   var item = items[i];
	   var valueNode = item.getAttributeNode("VALUE");
	   if (valueNode) {
	      var value = valueNode.nodeValue;
	      var name = item.firstChild.nodeValue;	
	      // create the text node
	      node = document.createTextNode(name);
	      opt = document.createElement("option");
	      opt.value = value;
	      opt.appendChild(node);
	      select.appendChild(opt);
	   }
	}
	return select;
}

function showCat(object) {
    var id = object.options[object.selectedIndex].value;
    alert("selected cat "+id);
}

function setNodeAttribute(node,attName,value) {
	node.setAttributeNode(document.createAttribute(attName));
	node.setAttribute(attName,value);
}