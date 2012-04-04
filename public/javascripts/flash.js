(function( $, undefined ) {
  $.notification = function(options) {
    var opts = $.extend({}, {type: 'notice', time: 3000}, options);
    var o    = opts;

    timeout          = setTimeout('$.notification.removebar()', o.time);
    var message_span = $('<span />').addClass('jbar-content').html(o.message);
    var wrap_bar     = $('<div />').addClass('jbar jbar-top').css("cursor", "pointer");

    if (o.type == 'error') {
      wrap_bar.css({"color": "#D8000C"})
    };

    wrap_bar.click(function(){
      $.notification.removebar()
    });

    wrap_bar.append(message_span).hide()
  .insertBefore($('.container')).fadeIn('fast');
  };


  var timeout;
  $.notification.removebar    = function(txt) {
    if($('.jbar').length){
      clearTimeout(timeout);

      $('.jbar').fadeOut('fast',function(){
        $(this).remove();
      });
    }   
  };


})(jQuery);

