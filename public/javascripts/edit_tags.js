var tags_count = 0;

function render_list_item(ul, item) {
  return $("<li />")
    .data("item.autocomplete", item)
    .append("<a><img class=friends_pic src=https://graph.facebook.com/" +item.id+ "/picture/ width=23 height=23>" + item.value + "</a>")				
    .appendTo(ul);
}

function add_autocomplete(elem, friends) {
  elem.autocomplete({
    source: friends,
    minLength: 1,
    select: function(event, ui) { 
      $(this).parent().find('.fb_id').val(ui['item']['id']);
    }
  }).data("autocomplete")._renderItem = render_list_item;
}

function initEditTags(fb, friendsJSON, tagsNow) {
  tags_count = tagsNow;

  $(".contact_info").each(function() { add_autocomplete($(this), friendsJSON) } );

  $('.gallery_delete').hide();

  // Display/hide the tag remove icon
  $(".edit_box, .fb_edit_box").live({
    mouseenter:
    function() {
      $('.gallery_delete').hide();
      $(this).find('.gallery_delete').show();
    },
    mouseleave:
    function() {
      $('.gallery_delete').hide();
    }
  }
  );

  //display the add new tags box
  $('#add_new_tag, #fb_add_new_tag').click(function(){
    $('#new_tag').show();

    var new_tag_d;
    
    if (fb) { 
      new_tag_d = $(
        "<div class='fb_edit_box radious_6 edit_box_center'>" + 
          "<div id='fb_face_tag' class='ui-widget'>" + 
            "<div class='delete_div delete_box_tag'>" +
              "<img src='/images/gallery_delete.png' class='gallery_delete' style='display: none;'>" +
            "</div>" +
            "<div class='fb_image_border radious_6'>" +
              "<img class='gallary_image' src='/images/avatar.png' width='70' height='80'>" +
            "</div>" +
            "<label for='tags'>Who is this? </label>" +
            "<input class='contact_info fb_contact ui-autocomplete-input' id='video_video_taggees_attributes__" + tags_count + "contact_info' name='video[video_taggees_attributes][" + tags_count + "][contact_info]' size='30' type='text' value='' autocomplete='off' role='textbox' aria-autocomplete='list' aria-haspopup='true'>" +
            "<input type='hidden' name='video[video_taggees_attributes][" + tags_count + "][fb_id]' id='video_video_taggees_attributes_" + tags_count + "_fb_id' class='fb_id'> " +
          "</div>" +
        "</div>");
    } else { 
        new_tag_d = $(
        "<div class='edit_box edit_box_new radious_6'>"+ 
          "<div>" + 
            "<div class='left delete_box_tag'>" + 
              "<img src='/images/gallery_delete.png' class='gallery_delete'>" + 
            "</div>" + 
            "<div id='new_tag' class='avatar_border radious_6'>" + 
              "<img src='/images/avatar.png' width='55' height='60'>" + 
            "</div>" + 
            "<label class ='new_tag_label' for='tags'>Add another Vtag</label>" + 
            "<br>" + 
            "<input type='hidden' name='video[video_taggees_attributes][" + tags_count + "][fb_id]' id='video_video_taggees_attributes_" + tags_count + "_fb_id' class='fb_id'> " +
            "<input type='text' value='' size='30' name='video[video_taggees_attributes][" + tags_count + "][contact_info]' id='video_video_taggees_attributes_" + tags_count + "_contact_info' class='contact_info ui-autocomplete-input' autocomplete='off' role='textbox' aria-autocomplete='list' aria-haspopup='true'>" +
          "</div>" +
        "</div>");
    }

    new_tag_d.appendTo('#tag_table');
    add_autocomplete(new_tag_d.find('.contact_info'), friendsJSON);

    tags_count += 1;
  });

  // Remove the appended new tag div
  $('#tag_table').on('click', '.gallery_delete',function() {
    var box = $(this).closest('.edit_box, .fb_edit_box');
    box.find('.destroy').attr("checked", true);
    box.hide();
  });

  // Remove tags with empty name
  $('#tag_table').on('change', '.contact_info', function(a, b, c) {
    var box = $(this).closest('.edit_box, .fb_edit_box');
    box.find('.destroy').attr("checked", ($(this).val().length == 0));
  });
}
