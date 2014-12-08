/*!
 * jQuery.sortChildren
 *
 * Version: 1.0.0
 *
 * Author: Rodney Rehm
 * Web: http://rodneyrehm.de/
 * See: http://blog.rodneyrehm.de/archives/14-Sorting-Were-Doing-It-Wrong.html
 *
 * @license
 *   MIT License http://www.opensource.org/licenses/mit-license
 *   GPL v3 http://opensource.org/licenses/GPL-3.0
 *
 */
(function($, undefined){

$.fn.sortChildren = function(map, compare) {
    return this.each(function() {
        var $this = $(this),
            $children = $this.children(),
            _map = [],
            length = $children.length,
            i;
    
        for (i = 0; i < length ; i++) {
            _map.push({
                index: i, 
                value: (map || $.sortChildren.map)($children[i])
            });
        }
                
        _map.sort(compare || $.sortChildren.compare);

        for (i = 0; i < length ; i++) {
            this.appendChild($children[_map[i].index]);
        }
    });
};

$.sortChildren = {
    // default comparison function using String.localeCompare if possible
    compare: function(a, b) {
        if ($.isArray(a.value)) {
            return $.sortChildren.compareList(a.value, b.value);
        }
        return $.sortChildren.compareValues(a.value, b.value);
    },
    
    compareValues: function(a, b) {
        if (typeof a === "string" && "".localeCompare) {
            return a.localeCompare(b);
        }

        return a === b ? 0 : a > b ? 1 : -1;
    },

    // default comparison function for DESC
    reverse: function(a, b) {
        return -1 * $.sortChildren.compare(a, b);
    },

    // default mapping function returning the elements' lower-cased innerTEXT
    map: function(elem) {
        return $(elem).text().toLowerCase();
    },

    // default comparison function for lists (e.g. table columns)
    compareList: function(a, b) {
        var i = 1,
            length = a.length,
            res = $.sortChildren.compareValues(a[0], b[0]);

        while (res === 0 && i < length) {
            res = $.sortChildren.compareValues(a[i], b[i]);
            i++;
        }

        return res;
    }
};

})(jQuery);
