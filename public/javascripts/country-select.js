$(document).ready(function(){
	$("#current_country_code").change(function(){
		var old_pathname = window.location.pathname;
		window.location = "http://"+$("#current_country_code").val().toLowerCase()+".localhost.com:3000"+old_pathname;
	});
});