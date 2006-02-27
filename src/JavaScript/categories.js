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
	    clearCats(cats);
	    var items = xmlhttp.responseXML.getElementsByTagName("OPTION");
	    for (var i = 0; i < items.length; i++) {
	       var item = items[i];
	       addCategory(cats,item);
            }
	 }
}

function clearCats(cats) {


    var optCount = cats.length;
    // leave default "all" value around.
    for (i = optCount-1; i > 0; i--) {
	    cats.remove(i);
    }

}


function addCategory(cats,item) {
     var value = getValue(item);
     var name = item.firstChild.nodeValue;
     // create the text node
     var node = document.createTextNode(name);
     var opt = document.createElement("option");
     opt.value = value;
     opt.appendChild(node);
     cats.appendChild(opt);

}

function getValue(item) {
   var value;
   for (var x = 0; x < item.attributes.length; x++) {
       var att = item.attributes[x];
       if (att.nodeName.toLowerCase() == 'value') {
              return att.nodeValue;
       }
   }
   return null;
}
