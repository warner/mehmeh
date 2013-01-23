
console.log("main.js loading");

sjcl.random.addEntropy("seed", 8*32, "fake");

/*
addon.port.on("kdf", function(m) {
    console.log("worker do kdf", m);
    var keys = gombot_kdf(m.email, m.password);
    console.log(" worker finish do kdf emit");
    addon.port.emit("kdf-output", {keys: keys});
    console.log(" worker finish do kdf");
});
*/

function emit(text) {
    $("#output").append($("<div/>").text(text));
}

$(function() {
    $("#start-in-content").on("click", function(e) {
        console.log("starting test in-content..");
        emit("starting test..");
        setTimeout(function() {
            var r = test();
            emit("in-content test done");
            emit("elapsed: "+r.elapsed+" seconds");
        }, 1000);
    });
    $("#start-webworker").on("click", function(e) {
        console.log("starting test in web-worker..");
        setTimeout(function() {
            var w = new Worker("worker.js");
            w.onmessage = function(m) {
                emit("web-worker test done");
                emit("elapsed: "+m.data.elapsed+" seconds");
            };
            emit("starting test..");
            w.postMessage({type: "test"});
        }, 1000);
    });
    $("#start-contentscript").on("click", function(e) {
        console.log("starting test in content-script..");
        emit("starting test..");
        setTimeout(function() {
            var r = test();
            emit("test done");
            emit("elapsed: "+r.elapsed+" seconds");
        }, 1000);
    });
});

console.log("main.js loaded");
