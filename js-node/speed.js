
var crypto = require("crypto");

function HMAC(key, msg) {
    var h = crypto.createHmac("sha256", key.toString("binary"));
    h.update(msg.toString("binary"));
    return Buffer(h.digest("base64"), "base64");
}

var xor = require("./util").xor;
function pbkdf2_sha256(password, salt, iterations, keylen) {
    // roll our own
    function PRF(data) {
        return HMAC(password, data);
    }
    var u, ui, i, j;
    var output = [];
    var generated = 0;
    for (i=0; generated<keylen; i++) {
        var count = Buffer(4); count.writeUInt32BE(i+1, 0);
        u = ui = PRF(Buffer.concat([salt, count]));
        for (j=0; j<iterations-1; j++) {
            ui = PRF(ui);
            u = xor(u, ui);
        }
        output.push(u);
        generated += u.length;
    }
    return Buffer.concat(output).slice(0, keylen);
}

function makeSalt(name, extra) {
    var append = Buffer("");
    if (extra)
        append = Buffer.concat([Buffer(":"), extra]);
    return Buffer.concat([Buffer("identity.mozilla.com/gombot/v1/"),
                          Buffer(name),
                          append]);
}

function gombot_kdf(email, password) {
    var masterSalt = makeSalt("master", Buffer(email, "utf-8"));
    var secret = Buffer([]); // empty for now
    var masterSecret = Buffer.concat([secret,
                                      Buffer(":"),
                                      Buffer(password, "utf-8")]);
    console.log("masterSalt", masterSalt.toString("hex"));
    console.log("masterSecret", masterSecret.toString("hex"));
    var masterKey = pbkdf2_sha256(masterSecret, masterSalt, 250*1000, 32);
    console.log("master", masterKey.toString("hex"));
    return;
    var authKey = pbkdf2_sha256(masterKey, makeSalt("authentication"), 1, 32);
    var aesKey = pbkdf2_sha256(masterKey, makeSalt("data/AES"), 1, 32);
    var hmacKey = pbkdf2_sha256(masterKey, makeSalt("data/HMAC"), 1, 32);
    console.log("authKey", authKey.toString("hex"));
    console.log("aesKey", aesKey.toString("hex"));
    console.log("hmacKey", hmacKey.toString("hex"));
    return {authKey: authKey, aesKey: aesKey, hmacKey: hmacKey};
}

gombot_kdf("andré@example.org", "pässwörd");
