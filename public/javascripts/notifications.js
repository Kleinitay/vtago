function check_notifications() {
  $.getJSON('/notifications/count.json', function(data) {
    var counter = $('#notifications_count');

    if (data > 0) {
      counter.html(data);
      counter.show();
    } else {
      counter.hide();
    }
  });
}

function show_notifications() {
  console.log('SHOW !');
  $.get('/notifications/all', function(data) {
    var elem = $('#notifications');
    elem.html(data);
    elem.show();
  });
}

$(document).ready(function(){			
  if ($('#notifications_count').length > 0) {
    setInterval(check_notifications, 50000);
    check_notifications();
  }
  $('#notifications_count').live('click', show_notifications);
});
