//Check if the function exists
if (typeof Element.insert !== "function") {
  //If not, hook it onto the $().append method.
  Element.insert = function (elem, ins) {
    $("#" + elem).append(ins.bottom);
  };
}// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults