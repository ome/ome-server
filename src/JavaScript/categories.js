// HSH 23 Feb 2006
// experimenting with callbacks 



RenderPage = '/perl2/serve.pl?Page=OME::Web::DBObjRender';

var xmlhttp;



function changeCategoryGroup(object) {
	 var id = object.options[object.selectedIndex].value;
         var span = document.getElementById("catSelect");	
	 span.innerHTML="";
	 if (id != "None") {
	 	 var url = RenderPage+"&ID="+id;
	 	 url += "&Mode=select&Type=@CategoryGroup";
		 xmlhttp = new XMLHttpRequest;
		 xmlhttp.onreadystatechange = updateCategory;
		 xmlhttp.open("GET",url,true);
		 xmlhttp.send(null);
        }
	else  {
	      span.innerHTML="None";
        }
}


function updateCategory() {
	    var txt = xmlhttp.responseText;
	    
	    var span = document.getElementById("catSelect");
	    span.innerHTML=txt;
}

