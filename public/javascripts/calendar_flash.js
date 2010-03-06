$(document).ready(function(){
	addFlashCalendar = function() {
		if ($("#flash_calendar").length == 0){
			$("<div id='flash_calendar'></div>").appendTo($("div.wc-nav"));
		}
	};
});
