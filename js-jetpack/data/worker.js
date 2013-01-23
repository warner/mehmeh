
/* inside a web-worker, we can use importScripts(); */

console = {log: function(m) {dump(m+"\n");}};

console.log("worker.js loading");

importScripts("sjcl-with-cbc.js");
importScripts("gombot-content.js");


sjcl.random.addEntropy("seed", 8*32, "fake");

self.onmessage = function(m) {
    console.log("onmessage");
    console.log(m.data);
    if (m.data.type == "test") {
        console.log("worker do kdf", m);
        var r = test();
        console.log(" worker finish do kdf emit");
        self.postMessage({type: "test-done", elapsed: r.elapsed});
        console.log(" worker finish do kdf");
    }
};

console.log("worker.js loaded");
