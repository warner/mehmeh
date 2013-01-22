
console.log("worker.js loading");

sjcl.random.addEntropy("seed", 8*32, "fake");


addon.port.on("kdf", function(m) {
    console.log("worker do kdf", m);
    var keys = gombot_kdf(m.email, m.password);
    console.log(" worker finish do kdf emit");
    addon.port.emit("kdf-output", {keys: keys});
    console.log(" worker finish do kdf");
});

console.log("worker.js loaded");
