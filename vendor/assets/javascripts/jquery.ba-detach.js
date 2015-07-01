/*!
 * jQuery Detach+ - v0.1pre - 5/18/2011
 * http://benalman.com/
 *
 * Copyright (c) 2011 "Cowboy" Ben Alman
 * Dual licensed under the MIT and GPL licenses.
 * http://benalman.com/about/license/
 */

(function($){
  // https://gist.github.com/938767
  var detach = $.detach = function(node, async, fn) {
    var parent = node.parentNode;
    var next = node.nextSibling;
    // No parent node? Abort!
    if ( !parent ) { return; }
    // Detach node from DOM.
    parent.removeChild(node);
    // Handle case where optional `async` argument is omitted.
    if ( typeof async != 'boolean' ) {
      fn = async;
      async = false;
    }
    // Note that if a function wasn't passed, the node won't be re-attached!
    if ( fn && async ) {
      // If async == true, reattach must be called manually.
      fn.call(node, reattach);
    } else if ( fn ) {
      // If async != true, reattach will happen automatically.
      fn.call(node);
      reattach();
    }
    // Re-attach node to DOM.
    function reattach() {
      parent.insertBefore(node, next);
    }
  };

  // Override the default .detach method to offer the new functionality.
  $.fn.detach = function(async, fn) {
    return this.each(function() {
      // Call detach for each element in the collection.
      detach(this, async, fn);
    });
  };
})(jQuery);
