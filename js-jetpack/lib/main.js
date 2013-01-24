
var data = require("self").data;
var gombot = require("./gombot");

require("widget").Widget({
    id: "gombot-test-widget",
    label: "Gombot Test",
    contentURL: "http://www.mozilla.org/favicon.ico",
    onClick: function() {
        var start = new Date().getTime();
        console.log("asking worker to kdf");
        gombot.kdf("andré@example.org", "pässwörd").then(function(keys) {
            console.log("keys are", JSON.stringify(keys));
        });
    }
});

console.log("Addon is running");
