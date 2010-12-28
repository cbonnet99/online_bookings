$(document).ready(function(){
    
    $("#practitioner_country_id").change(function(){
        var country_id = $("#practitioner_country_id").val();
        var options = $("#practitioner_phone_prefix");
        options.find("option").remove();
        options.append($("<option />"));
        $.getJSON("/countries/mobile_phone_prefixes/"+country_id, function(result) {
            //don't forget error handling!
            $.each(result, function() {
                options.append($("<option class='mobile'/>").val(""+this).text(""+this));
                console.log("Adding mobile "+this)
            });
        });
        $.getJSON("/countries/landline_phone_prefixes/"+country_id, function(result) {
            //don't forget error handling!
            $.each(result, function() {
                options.append($("<option />").val(""+this).text(""+this));
                console.log("Adding landline "+this)
            });
        });
    });
    
    $("#practitioner_first_name").focus();
    if ($("#practitioner_lunch_break").is(':checked')) {
        $("#pro-extra-times").show();
    }
    else {
        $("#pro-extra-times").hide();
    }
    $("#practitioner_lunch_break").click(function(){
        $("#pro-extra-times").toggle();
    });
});