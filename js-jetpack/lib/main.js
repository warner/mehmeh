
//var gombot = require("./gombot.js");
//var sjcl = require("./sjcl-with-cbc.js");
//sjcl.random.addEntropy("seed", 8*32, "fake");
var data = require("self").data;

console.log("creating page-worker");
var worker = require("page-worker").Page({
    contentURL: data.url("worker.html")
    // that uses <script> tags to pull in SJCL and the gombot KDF code. We
    // use worker.port.emit(type,data) to send requests, and get back
    // responses with worker.on(type, f(data)) . The worker code uses
    // addon.port.on() to receive requests and addon.port.emit() to send
    // responses
});
console.log("page-worker created");


require("widget").Widget({
    id: "gombot-test-widget",
    label: "Gombot Test",
    contentURL: "http://www.mozilla.org/favicon.ico",
    onClick: function() {
        console.log("asking worker to kdf");
        var start = new Date().getTime();
        worker.port.on("kdf-done", function(m) {
            var end = new Date().getTime();
            console.log("elapsed", (end-start)/1000);
            console.log("keys", JSON.stringify(m.keys));
        });
        worker.port.emit("kdf", { email: "andré@example.org",
                                  password: "pässwörd" });
        console.log("asked worker to kdf");
    }
});

console.log("Addon is running");
