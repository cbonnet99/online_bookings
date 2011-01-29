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
	
	$("a#event-fields-change-time").click(function(event){
	   $(this).hide();
       $("#event-fields-time").find(":input").each(
         function(i,e) {
           $(this).show();
         }
       );	
       $("#event-fields-time").find(".read_only_label").each(
         function(i,e) {
           $(this).hide();
         }
       );
	   event.preventDefault();
	});
});
