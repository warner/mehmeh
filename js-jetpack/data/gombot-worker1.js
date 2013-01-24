
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
console.log("gombot-worker1.js loading");

addon.port.on("kdf", function(m) {
    console.log("worker do test-webworker", m);
    var w = new Worker("gombot-worker2.js");
    w.onmessage = function(r) {
        //console.log(" worker finish test-webworker", r.data);
        var data = JSON.parse(r.data);
        addon.port.emit("kdf-done", {keys: r.data.keys
                                     elapsed: r.data.elapsed});
        console.log(" worker finish test-webworker sent response");
    };
    w.postMessage({type: "kdf", email: m.email, password: m.password});
});

console.log("worker.js loaded");
