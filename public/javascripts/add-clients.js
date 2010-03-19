$(document).ready(function(){
	var setSendEmail = function(){
		if ($("#send_email").is(':checked')){
			$("#email_all").show();
		}
		else {
			$("#email_all").hide();
		}		
	};
	setSendEmail();
	$("textarea#emails").focus();
	$("#send_email").click(function(){
		setSendEmail();
	});
	$(':input').unbind('keydown');
});