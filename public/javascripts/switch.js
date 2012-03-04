// JavaScript Document
$(document).ready(function(){
 Cufon.replace('h5',{
	hover:true		   
	});
  Cufon.replace('h1',{
	hover:true		   
	});
   Cufon.replace('h2',{
	hover:true		   
	});
      Cufon.replace('h3',{
	hover:true		   
	});
	$("li.show-grid").toggle(function(){
	  $(this).addClass("active"); 
	  $("div.wrapper_list_view").fadeOut("fast", function() {
	  	$(this).fadeIn("fast").addClass("thumb_view"); 
		 });
	  }, function () {
      $(this).removeClass("active");
	  $("div.wrapper_list_view").fadeOut("fast", function() {
	  	$(this).fadeIn("fast").removeClass("thumb_view");
		});
	}); 

/*$(".video-category").hide(); //Hide all content
$("#nav-slider ul li:first").addClass("active").show(); //Activate first tab
$(".video-category:first").show(); //Show first tab content
//On Click Event
$("#nav-slider ul li").click(function() {
$("#nav-slider ul li").removeClass("active"); //Remove any "active" class
$(this).addClass("active"); //Add "active" class to selected tab
$(".video-category").hide(); //Hide all tab content
var activeTab = $(this).find("a").attr("href"); //Find the rel attribute value to identify the active tab + content
$(activeTab).fadeIn(); //Fade in the active content
return false;
});
*/

//ACCORDION BUTTON ACTION (ON CLICK DO THE FOLLOWING)
	$('.accordionButton').click(function() {

		//REMOVE THE ON CLASS FROM ALL BUTTONS
		$('.accordionButton').removeClass('on');
		  
		//NO MATTER WHAT WE CLOSE ALL OPEN SLIDES
	 	$('.accordionContent').slideUp(200);
   
		//IF THE NEXT SLIDE WASN'T OPEN THEN OPEN IT
		if($(this).next().is(':hidden') == true) {
			
			//ADD THE ON CLASS TO THE BUTTON
			$(this).addClass('on');
			  
			//OPEN THE SLIDE
			$(this).next().slideDown(200);
		 } 
		  
	 });

	
	
	/********************************************************************************************************************
	CLOSES ALL S ON PAGE LOAD
	********************************************************************************************************************/	
	$('.accordionContent').hide();
	$('.accordionContent:first').show();

$('.accordionButton:first').addClass('on');



});