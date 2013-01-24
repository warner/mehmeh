
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

addon.port.on("kdf", function(m) {
    //console.log("worker do test-webworker", m);
    var w = new Worker("gombot-worker2.js");
    w.onmessage = function(r) {
        //console.log(" worker finish test-webworker", r.data);
        var data = JSON.parse(r.data);
        addon.port.emit("kdf-done", {keys: data.keys,
                                     elapsed: data.elapsed});
        //console.log(" worker finish test-webworker sent response");
    };
    w.postMessage({type: "kdf", email: m.email, password: m.password});
});

addon.port.on("encrypt", function(m) {
    var w = new Worker("gombot-worker2.js");
    w.onmessage = function(r) {
        var data = JSON.parse(r.data);
        addon.port.emit("encrypt-done", {msgmac_b64: data.msgmac_b64,
                                         elapsed: data.elapsed});
    };
    w.postMessage({type: "encrypt",
                   keys: m.keys, data: m.data, forceIV: m.forceIV});
});

addon.port.on("decrypt", function(m) {
    var w = new Worker("gombot-worker2.js");
    w.onmessage = function(r) {
        var data = JSON.parse(r.data);
        addon.port.emit("decrypt-done", {plaintext: data.plaintext,
                                         elapsed: data.elapsed});
    };
    w.postMessage({type: "decrypt",
                   keys: m.keys, msgmac_b64: m.msgmac_b64});
});
