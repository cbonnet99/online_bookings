$(document).ready(function(){
    window.setTimeout(function() {
     $("#step2").show();
    }, 10000);
    window.setTimeout(function() {
     $("#step3").show();
    }, 20000);
    $.post("/practitioners/create_sample_data", function(){
        var old_location = window.location.href;
        var new_location = old_location.replace(/waiting_sample_data/, '');
        window.location.replace(new_location);
    });
    
});