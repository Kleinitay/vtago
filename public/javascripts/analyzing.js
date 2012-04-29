/**
 * Created by JetBrains RubyMine.
 * User: itay
 * Date: 4/29/12
 * Time: 4:54 PM
 * To change this template use File | Settings | File Templates.
 */
 var analyzing = function () {
 return {

   update: function(num){
     if (num > 0)
       $('#analyzing').show();
     else
       $('#analyzing').hide();
   },

   show: function() {
     $('#analyzing').show();
   },

   hide: function() {
     $('#analyzing').hide();
   },

   check: function(){
     $.getJSON('/video/pending_count.json', analyzing.update);
   },

   init: function(){
     setInterval(analyzing.check, 20000);
     analyzing.check();
   }
 }
}();
