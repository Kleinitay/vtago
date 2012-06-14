var segments_count = 0;


function initEditsegments(fb, segmentsNow, slider_id, video_duration) {
  segments_count = segmentsNow;
  slider_new_id = slider_id + 1
  //display the add new segments box
  $('#add_new_segment').click(function(){
    $('#new_segment').show();
    var new_segment_d = $(
      "<div id='slider-range-" + slider_new_id + "' class='time_segment'></div>" +  
                    "<span id='delete_segment'>x</span>" + 
                        "<script>" + 
                          "var video = document.getElementById('player1');" +
                            "$(function() {" +
                                "$( \"#slider-range-" + slider_new_id + "\" ).slider({" +
                                    "width: 480," +
                                    "range: true," +
                                    "min: 0," +
                                    "max: " + video_duration * 1000 +  "," +
                                    "values: [ 80, 240 ]," +
                                    "slide: function( event, ui ) {" +
                                        "$( \"#video_taggee_time_segments_attributes_" + segments_count + "_begin\" ).val( ui.values[ 0 ]);" +
                                        "$( \"#video_taggee_time_segments_attributes_" + segments_count + "_end\" ).val( ui.values[ 1 ]);" +
                                        "$( \"#player1\" ).get(0).pause();" +
                                        "video.currentTime = ui.value/1000;" +
                                    "}" +
                                "});" +
                                "$( \"#video_taggee_time_segments_attributes_" + segments_count + "_begin\"  ).val($( \"#slider-range-" + slider_new_id + "\" ).slider( \"values\", 0 ));" +
                                "$( \"#video_taggee_time_segments_attributes_" + segments_count + "_end\"  ).val($( \"#slider-range-" + slider_new_id + "\" ).slider( \"values\", 1 ));" +
                                "$( \"player1\" ).attr(\"currentTime\", $( \"#slider-range-" + slider_new_id + "\" ).slider( \"values\", 1 ));" +
                            "});" +
                        "</script>" +
                        "<br>" +
                        "<input id=\"video_taggee_time_segments_attributes_" + segments_count + "_begin\" name=\"video_taggee[time_segments_attributes][" + segments_count + "][begin]\" type=\"hidden\" value=\"80\" />" +
                        "<input id=\"video_taggee_time_segments_attributes_" + segments_count + "_end\" name=\"video_taggee[time_segments_attributes][" + segments_count + "][end]\" type=\"hidden\" value=\"240\" />" +
                        "<br>" //+
                       // "<input id=\"video_taggee_time_segments_attributes_" + segments_count + "_id\" name=\"video_taggee[time_segments_attributes][" + segments_count + "][id]\" type=\"hidden\" value=\"" + slider_new_id + "\" />"  
                        );
    
    new_segment_d.appendTo('#segment_table');
    segments_count += 1;
    slider_new_id += 1;
  });

  // Remove the appended new segment div
  $('#segment_table').on('click', '.gallery_delete',function() {
    var box = $(this).closest('.edit_box, .fb_edit_box');
    box.find('.destroy').attr("checked", true);
    box.hide();
  });

  // Remove segments with empty name
  $('#segment_table').on('change', '.contact_info', function(a, b, c) {
    var box = $(this).closest('.edit_box, .fb_edit_box');
    box.find('.destroy[real_segment=false]').attr("checked", ($(this).val().replace(/ /g,'').length == 0));
  });
}
