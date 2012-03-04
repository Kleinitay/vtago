$(document).ready(function(){
// hide the menual signup display
$('#manual_signup_wrapper').hide();
$('#manual_signup').hide();
	$('#manual_signup_link').click(function(){
		$('#manual_signup').slideToggle('slow');
	});
});