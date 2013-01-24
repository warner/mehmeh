
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
console.log("worker.js loading");

sjcl.random.addEntropy("seed", 8*32, "fake");


addon.port.on("kdf", function(m) {
    //console.log("worker do kdf", m);
    var keys = gombot_kdf(m.email, m.password);
    //console.log(" worker finish do kdf emit");
    addon.port.emit("kdf-done", {keys: keys});
    //console.log(" worker finish do kdf");
});

addon.port.on("test-webworker", function(m) {
    console.log("worker do test-webworker", m);
    var w = new Worker("worker2.js");
    w.onmessage = function(r) {
        //console.log(" worker finish test-webworker", r.data);
        var data = JSON.parse(r.data);
        addon.port.emit("test-webworker-done", {elapsed: data.elapsed});
        console.log(" worker finish test-webworker sent response");
    };
    w.postMessage({type: "test"});
});

console.log("worker.js loaded");
