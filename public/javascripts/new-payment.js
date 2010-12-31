$(document).ready(function(){
    $("#new_payment input.submit").click(function(){
       $("#waiting_black_small").show();
       $(this).hide();
    });
});