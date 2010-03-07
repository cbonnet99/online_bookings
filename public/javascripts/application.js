$(document).ready(function() {
	$('a.selected').corners('top');
	$('.rounded').corners();
	$(':input').keydown(function(e) {
		if (e.keyCode == 13) {
			$("form").submit();
		}
	});
});