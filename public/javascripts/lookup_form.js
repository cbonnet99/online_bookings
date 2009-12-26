$(document).ready(function(){
	$("input#client_email").focus();
	
	$("form#client_email_selection input").keypress(function (e) {  
	        if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {  
	            $('button[type=submit] .default').click();  
	            return false;  
	        } else {  
	            return true;  
	        }  
	    });
});