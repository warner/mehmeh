
var seed = Buffer(require("crypto").randomBytes(32), "binary").toString();
sjcl.random.addEntropy(seed, 8*32, "node.js/crypto/randomBytes");
if (!sjcl.random.isReady()) {
    console.log("despite adding entropy, sjcl.random is not ready");
    assert(0);
}
test();
