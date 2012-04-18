var notifications = function() { 
  return { 
    update_counter: function(data) { 
      var counter = $('#notifications_count');

      // Remove notification counter from title
      document.title = document.title.replace(/^\(\d+\)\s*/g, '')

        if (data > 0) {
          counter.html(data).show();
          document.title = "(" + data + ") " + document.title;
        } else {
          counter.hide();
        }
    },

    check: function() {
      $.getJSON('/notifications/count.json', notifications.update_counter);
    },

    hide: function() {
      $('#notifications').hide();
    },

    show: function() { 
      $.get('/notifications/all', function(data) {
        var elem = $('#notifications');
        elem.html(data);
        elem.show();
      });
    },

    toggle: function(event) {
      if ($('#notifications').is(':visible')) {
        notifications.hide();
      } else {
        notifications.show();
      }
      event.stopPropagation();
    },

    init: function() {
      $('#notifications_count').click(notifications.toggle);

      // Catch clicks outside notifications bar
      $('html').click(function() {
        notifications.hide();
      });

      // Catch clicks on notifications bar
      $('#notifications').click(function(event){
        event.stopPropagation();
      });

      // Catch ESC 
      $(document).keyup(function(e) {
        if (e.keyCode == 27) { notifications.hide(); }
      });

      setInterval(notifications.check, 30000);
      notifications.check();
    },
  }
}();

$(document).ready(function(){			
  if ($('#notifications_count').length > 0) {
    notifications.init();
  }
});
