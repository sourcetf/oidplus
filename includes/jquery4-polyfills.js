/*!
 * jQuery 4 compatibility layer for legacy jQuery 1.x/2.x/3.x plugins
 * Only restores APIs that were removed but are easy to emulate.
 */

(function ($) {

    if (!$) {
        throw new Error("jQuery must be loaded before jquery4-polyfills.js");
    }

    // -------------------------------------------------------------------------
    // Utility functions
    // -------------------------------------------------------------------------

    if (!$.now) {
        $.now = Date.now;
    }

    if (!$.trim) {
        $.trim = function (str) {
            return String(str).trim();
        };
    }

    if (!$.isArray) {
        $.isArray = Array.isArray;
    }

    if (!$.isFunction) {
        $.isFunction = function (obj) {
            return typeof obj === "function";
        };
    }

    if (!$.isWindow) {
        $.isWindow = function (obj) {
            return obj != null && obj === obj.window;
        };
    }

    if (!$.isNumeric) {
        $.isNumeric = function (obj) {
            return (
                (typeof obj === "number" || typeof obj === "string") &&
                obj !== "" &&
                !isNaN(obj) &&
                !isNaN(parseFloat(obj))
            );
        };
    }

    if (!$.unique && $.uniqueSort) {
        $.unique = $.uniqueSort;
    }

    // -------------------------------------------------------------------------
    // Deprecated jQuery instance methods
    // -------------------------------------------------------------------------

    if (!$.fn.size) {
        $.fn.size = function () {
            return this.length;
        };
    }

    if (!$.fn.andSelf && $.fn.addBack) {
        $.fn.andSelf = $.fn.addBack;
    }

})(jQuery);

