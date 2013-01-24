
var data = require("self").data;
const {defer} = require("sdk/core/promise");

// we create a long-running page-worker that does the KDF work inside a
// web-worker, to get around a JS/jetpack performance bug. You must include
// the following files in data/ :
//   data/gombot-worker1.html
//   data/gombot-worker1.js
//   data/gombot-worker2.js
//   data/sjcl-with-cbc.js
//   data/gombot-content.js


var worker = require("page-worker").Page({
    contentURL: data.url("gombot-worker1.html")
});
console.log("page-worker created");


exports.kdf = function(email, password) {
    // returns a Deferred
    var d = defer();
    console.log("asking worker to kdf");
    worker.port.on("kdf-done", function(m) {
        // note: doesn't handle concurrent requests, probably leaky too
        d.resolve(m.keys);
    });
    worker.port.emit("kdf", {email: email, password: password});
    console.log("asked worker to kdf");
    return d.promise;
}

