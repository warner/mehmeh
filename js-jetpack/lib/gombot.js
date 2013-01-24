
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
//console.log("page-worker created");


exports.kdf = function(email, password) {
    // returns a Deferred
    var d = defer();
    //console.log("asking worker to kdf");
    worker.port.on("kdf-done", function(m) {
        // note: doesn't handle concurrent requests, probably leaky too
        //console.log("gombot.js kdf-done", JSON.stringify(m));
        d.resolve(m.keys);
    });
    worker.port.emit("kdf", {email: email, password: password});
    //console.log("asked worker to kdf");
    return d.promise;
};


exports.encrypt = function(keys, data, forceIV) {
    if (typeof(data) != "string") {
        console.log("gombot.encrypt data= must be a string");
        throw new Error("gombot.encrypt data= must be a string");
    }
    // forceIV is only for testing. In normal use, leave it undefined.

    var d = defer();
    //console.log("asking worker to kdf");
    worker.port.on("encrypt-done", function(m) {
        console.log("gombot.js encrypt-done", m.msgmac_b64);
        console.log("gombot.js encrypt-done took", m.elapsed);
        d.resolve(m);
    });
    worker.port.emit("encrypt", {keys: keys, data: data, forceIV: forceIV});
    return d.promise;
};

exports.decrypt = function(keys, msgmac_b64) {
    if (typeof(msgmac_b64) != "string") {
        console.log("gombot.decrypt msgmac_b64= must be a string");
        throw new Error("gombot.decrypt msgmac_b64= must be a string");
    }
    function delay(ms, value) {
        let { promise, resolve } = defer();
        require("timer").setTimeout(resolve, ms, value);
        return promise;
    }
    //return delay(1000, {plaintext: "abc", elapsed: 1.0});
    var d = defer();
    worker.port.on("decrypt-done", function(m) {
        console.log("gombot.js encrypt-done", m.plaintext);
        console.log("gombot.js encrypt-done took", m.elapsed);
        d.resolve(m);
    });
    worker.port.emit("decrypt", {keys: keys, msgmac_b64: msgmac_b64});
    return d.promise;
};

