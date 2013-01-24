
/* console.log is not available here */

function tostr(s) {
    if (typeof(s) == "string")
        return s;
    return JSON.stringify(s);
}

console = {log: function(m, m2) {dump(tostr(m));
                                 if (m2)
                                     dump(" "+tostr(m2));
                                 dump("\n");
                                }};
//console.log("gombot-worker1.js loading");

var worker = new Worker("gombot-worker2.js");

addon.port.on("kdf", function(m) {
    //console.log("worker do test-webworker", m);
    worker.onmessage = function(r) {
        //console.log(" worker finish test-webworker", r.data);
        var data = JSON.parse(r.data);
        addon.port.emit("kdf-done", {reqID: m.reqID,
                                     keys: data.keys,
                                     elapsed: data.elapsed});
        //console.log(" worker finish test-webworker sent response");
    };
    worker.postMessage({type: "kdf", email: m.email, password: m.password});
});

addon.port.on("encrypt", function(m) {
    var w = new Worker("gombot-worker2.js");
    worker.onmessage = function(r) {
        var data = JSON.parse(r.data);
        addon.port.emit("encrypt-done", {reqID: m.reqID,
                                         msgmac_b64: data.msgmac_b64,
                                         elapsed: data.elapsed});
    };
    worker.postMessage({type: "encrypt",
                        keys: m.keys, data: m.data, forceIV: m.forceIV});
});

addon.port.on("decrypt", function(m) {
    var w = new Worker("gombot-worker2.js");
    worker.onmessage = function(r) {
        var data = JSON.parse(r.data);
        addon.port.emit("decrypt-done", {reqID: m.reqID,
                                         plaintext: data.plaintext,
                                         elapsed: data.elapsed});
    };
    worker.postMessage({type: "decrypt",
                        keys: m.keys, msgmac_b64: m.msgmac_b64});
});
