var video_id = null;
var video_fb_id = null;

function incrementViewsCounter() {
  $.ajax({
    type: 'POST',
  url: '/video/' + video_fb_id + '/views',
  success: function(data) { 
    $('#views-count').html(data);
  },
  dataType: 'json'
  });
}

function updateViewsCounter() {
  $.getJSON('/video/' + video_fb_id + '/views', function(data) {
    $('#views-count').html(data);
  });
}

function eventPlay(e) { 
  incrementViewsCounter();
}

function enable_video(id, fb_id) {
  video_id = id;
  video_fb_id = fb_id;

  $('video').mediaelementplayer({
    features: ['playpause','volume','cuts','current','progress','duration','fullscreen'],
  success: function (mediaElement, domObject) {
    mediaElement.addEventListener('play', eventPlay, false);
  },
  error :
    function() {
      console.log('error');
    }
  });

  // hide the confirm box
  $("#delete_cancel").click(function(){
    $("#confirm_delete_box").hide();//remove box
    $('#delete_overlay').remove();//remove mask
  });

  //display the confirm box
  $("#delete_" + video_id).click(function(){
    //display mask
    $("<div id='delete_overlay'></div>")
    .css('height', $(document).height())
    .css('opacity','0')
    .animate({'opacity':'0.3'}, 'fast')
    .appendTo('body');
  //set the confirm box position
  var delete_element = $("#delete_" + video_id);
  var offset = delete_element.offset();
  var top=offset.top-200;
  var left=offset.left-150;
  $("#confirm_delete_box").show().appendTo('body');
  $('#confirm_delete_box').css('top',top);
  $('#confirm_delete_box').css('left',left);
  $('#confirm_delete_box').addClass('radious_6')	
  });			

  updateViewsCounter();
}

