$(document).ready(function(){
	$("textarea#emails").focus();
	$("#send_email").click(function(){
		if ($("#send_email").is(':checked')){
			$("#email_text_paragraph").show();
		}
		else {
			$("#email_text_paragraph").hide();
		}
	});
});