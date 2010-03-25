$(document).ready(function(){
	$("select[name='booking_type_id']").change(function(){
		var currentDiffMillis = new Date($("select[name='end']").val()).getTime() - new Date($("select[name='start']").val()).getTime();
		var booking_type_id = $("select[name='booking_type_id']").val();
	});
	addFlashCalendar = function() {
		if ($("#flash_calendar").length == 0){
			$("<div id='flash_calendar'></div>").appendTo($("div.wc-nav"));
		}
	};
});
