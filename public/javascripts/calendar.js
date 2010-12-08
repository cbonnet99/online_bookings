$(document).ready(function(){
    
    $("input#cancel_send_email").change(function(){
        if ($(this).attr("checked")) {
            $("textarea#cancel_cancellation_text").show();
        }
        else {
            $("textarea#cancel_cancellation_text").hide();            
        }
    })
    
	$("select[name='booking_type_id']").change(function(){
		var currentDiffMillis = new Date($("select[name='end']").val()).getTime() - new Date($("select[name='start']").val()).getTime();
		var booking_type_id = $("select[name='booking_type_id']").val();
	});
});
