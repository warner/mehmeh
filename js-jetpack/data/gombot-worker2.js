
/* inside a web-worker, we can use importScripts(); */

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

console.log("worker2.js loading");

importScripts("sjcl-with-cbc.js");
importScripts("gombot-content.js");

sjcl.random.addEntropy("seed", 8*32, "fake");

self.onmessage = function(m) {
    console.log("onmessage");
    console.log(m.data);
    if (m.data.type == "kdf") {
        console.log("worker do kdf", m.data);
        var start = new Date().getTime();
        var keys = gombot_kdf(m.data.email, m.data.password);
        console.log(" worker finish do kdf emit");
        var end = new Date().getTime();
        self.postMessage(JSON.stringify({type: "kdf-done",
                                         keys: keys,
                                         elapsed: (end-start)/1000}));
        console.log(" worker finish do kdf");
    }
};

console.log("worker.js loaded");
