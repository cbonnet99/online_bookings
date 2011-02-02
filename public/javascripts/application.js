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
	
	var get_explanation_id_from_link = function(explanation_link_id){
	    var str_to_remove = "_link";
	    var explanation_id = explanation_link_id.substring(0, explanation_link_id.length-str_to_remove.length)
	    return explanation_id	    
	};
	
	var get_explanation_id_from_close = function(explanation_close_id){
	    var str_to_remove = "_close";
	    var explanation_id = explanation_close_id.substring(0, explanation_close_id.length-str_to_remove.length)
	    return explanation_id	    
	};
	
	$('.explanation').hide();
	$('.explanation_link').click(function(event){
	    var explanation_link_id = $(this).attr("id");
	    var explanation_id = get_explanation_id_from_link(explanation_link_id);
	    $("#"+explanation_id).show();
	});
	
	$('.explanation_link').click(function(event){
	    var explanation_link_id = $(this).attr("id");
	    var explanation_id = get_explanation_id_from_link(explanation_link_id);
	    $("#"+explanation_id).slideDown("slow");
	});
	
	$('.explanation_close').click(function(event){
	    var explanation_close_id = $(this).attr("id");
	    var explanation_id = get_explanation_id_from_close(explanation_close_id);
	    $("#"+explanation_id).slideUp("slow");
	});
	
    // $(':input').keydown(function(e) {
    //  if (e.keyCode == 13) {
    //      $("form").submit();
    //  }
    // });
});