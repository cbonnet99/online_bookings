$(document).ready(function(){
    
    var automaticRedirect = function(){
        var old_location = window.location.href;
        var new_location = old_location.replace(/waiting_sample_data/, '');
        window.location.replace(new_location);        
    }
    
    window.setTimeout(function() {
     $("#step2").show();
    }, 10000);
    window.setTimeout(function() {
     $("#step3").show();
    }, 20000);
    window.setTimeout(function() {
        //if we have waited 60s, let's move on
        automaticRedirect();
    }, 60000);
    $.post("/practitioners/create_sample_data", function(){
        automaticRedirect();
    });
    
});