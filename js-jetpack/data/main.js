
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

$(function() {
    $("#start").on("click", function(e) {
        console.log("starting test");
        $("#output").append($("<div/>").text("starting test.."));
        setTimeout(test, 0.1);
    });
});

console.log("main.js loaded");
