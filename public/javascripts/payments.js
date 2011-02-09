$(document).ready(function(){
    $("select#payment_country").change(function(){
       window.location = "/payments/country/"+$(this).val();
    });
});