
var tabs = require("sdk/tabs");
var data = require("sdk/self").data;

require("widget").Widget({
    id: "gombot-test-widget",
    label: "Gombot Test",
    contentURL: "http://www.mozilla.org/favicon.ico",
    onClick: function() {
        tabs.open(data.url("main.html"));
    }
});

console.log("Addon is running");
