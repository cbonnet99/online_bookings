$(document).ready(function() {
    var round_selected = function() {
        var top_settings = {
                tl: { radius: 15 },
                tr: { radius: 15 },
                bl: { radius: 0 },
                br: { radius: 0 },
                antiAlias: true,
            }

        $('a.selected-tab').corner(top_settings);        
    };
    
    round_selected();

	$('.rounded').corner();
    // $(':input').keydown(function(e) {
    //  if (e.keyCode == 13) {
    //      $("form").submit();
    //  }
    // });
});