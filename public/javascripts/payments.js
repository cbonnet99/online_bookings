$(document).ready(function(){
    $("select#payment_country").change(function(){
       window.location = "/payments/"+$(this).val();
    });
});