$(document).ready(function(){
    $("#new_payment input.submit").click(function(){
       $("#waiting_black_small").show();
       $(this).hide();
    });
    
    $(".payment-plan").click(function(){
        var div_id = $(this).attr("id");
        var array_from_div_id = div_id.split("-");
        var plan_id = array_from_div_id[array_from_div_id.length-1];
        $("select#payment_payment_plan_id").val(plan_id);
        $(".payment-plan").each(function(){
            $(this).removeClass("selected-payment-plan");
        });
        $(this).removeClass("roll-payment-plan");
        $(this).addClass("selected-payment-plan");
        
    });
    
    $(".payment-plan").hover(function(){
       if (!$(this).hasClass("selected-payment-plan")) {
         $(this).addClass("roll-payment-plan");
       }
    },
    function(){
        $(this).removeClass("roll-payment-plan");        
    });
});