
var gombot = require("./gombot.js");
var sjcl = require("./sjcl-with-cbc.js");
sjcl.random.addEntropy("seed", 8*32, "fake");

require("widget").Widget({
    id: "gombot-test-widget",
    label: "Gombot Test",
    contentURL: "http://www.mozilla.org/favicon.ico",
    onClick: function() {
        gombot.test();
    }
});

console.log("Addon is running");
