$(document).ready(function() {
    var close_to_remove = "_close";
    var link_to_remove = "_link";
    var top_settings = {
            tl: { radius: 15 },
            tr: { radius: 15 },
            bl: { radius: 0 },
            br: { radius: 0 },
            antiAlias: true,
        };
    
    var round_selected = function() {
                
        $('a.selected-tab').corner(top_settings);        
    };
    
	var get_explanation_id_from_link = function(explanation_link_id){
	    var explanation_id = explanation_link_id.substring(0, explanation_link_id.length-link_to_remove.length);
	    return explanation_id;
	};
	
	var get_explanation_id_from_close = function(explanation_close_id){
	    var explanation_id = explanation_close_id.substring(0, explanation_close_id.length-close_to_remove.length);
	    return explanation_id;	    
	};
	
	$('.explanation').hide();
	
	$('.explanation_link').click(function(event){
	    var explanation_link_id = $(this).attr("id");
	    var link_padding_height = $(this).attr("padding_height");
	    if ((link_padding_height === '') || (link_padding_height=== null)){
	        link_padding_height = "0px";
	    }
	    else {
	        link_padding_height += "px";
	    };
	    var explanation_id = get_explanation_id_from_link(explanation_link_id);
	    $("#"+explanation_link_id).css("cursor", "auto").css("text-decoration", "none").css("background", "#FF9").css("color", "black").css("border", "solid 1px #C00").css("padding", "5px 5px "+link_padding_height).corner(top_settings);
	    $("#"+explanation_id).show();
	});
	
	$('.explanation_close').click(function(event){
	    var explanation_close_id = $(this).attr("id");
	    var explanation_id = get_explanation_id_from_close(explanation_close_id);
	    $("#"+explanation_id+link_to_remove).css("cursor", "pointer").css("text-decoration", "underline").css("background", "").css("color", "lightgrey").css("border", "").css("padding", "");
	    $("#"+explanation_id).slideUp("slow");
	});
    if (!$.browser.msie){
        round_selected();
    	$('.rounded').corner();
	};
	
    // $(':input').keydown(function(e) {
    //  if (e.keyCode == 13) {
    //      $("form").submit();
    //  }
    // });
});