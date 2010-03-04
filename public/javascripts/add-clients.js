$(document).ready(function(){
	$("textarea#emails").focus();
	$("#send_email").click(function(){
		if ($("#send_email").is(':checked')){
			$("#email_all").show();
		}
		else {
			$("#email_all").hide();
		}
	});
});