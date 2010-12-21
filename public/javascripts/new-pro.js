$(document).ready(function(){
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