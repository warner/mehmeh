
var crypto = require("crypto");
var Q = require("q"); // run "npm install q" first

function HMAC(key, msg) {
    var h = crypto.createHmac("sha256", key.toString("binary"));
    h.update(msg.toString("binary"));
    return Buffer(h.digest("base64"), "base64");
}

function HKDF_PRK(XTS, SKM) {
    /* XTS is the extractor salt, SKM is the secret key material. If you
    really don't want a salt, use an empty string. */
    return HMAC(XTS, SKM);
}

function HKDF_K(PRK, length_bytes, CTXinfo) {
    var out = [];
    var k = Buffer("");
    var count = 0;
    var generated = 0;
    while (generated < length_bytes) {
        k = HMAC(PRK, Buffer.concat([k, CTXinfo, Buffer([count])]));
        out.push(k);
        generated += k.length;
        count += 1;
    }
    return Buffer.concat(out).slice(0, length_bytes);
}

function HKDF(XTS, SKM, CTXinfo, length_bytes) {
    return HKDF_K(HKDF_PRK(XTS, SKM), length_bytes, CTXinfo);
}

function pbkdf2_sha1(password, salt, iterations, keylen) {
    // Buffer-ify and Promise-ify it
    // crypto.pbkdf2 is HMAC-SHA1.
    return Q.nfcall(crypto.pbkdf2,
                    password.toString("binary"), salt.toString("binary"),
                    iterations, keylen)
        .then(function(keyString) {return Buffer(keyString, "binary");});
}

var xor = require("./util").xor;
function pbkdf2_sha256_sync(password, salt, iterations, keylen) {
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
exports.pbkdf2_sha256_sync = pbkdf2_sha256_sync;

function pbkdf2_sha256(password, salt, iterations, keylen) {
    return Q.resolve(pbkdf2_sha256_sync(password, salt, iterations, keylen));
}

function makeSalt(name, extra) {
    var append = Buffer("");
    if (extra)
        append = Buffer.concat([Buffer(":"), extra]);
    return Buffer.concat([Buffer("identity.mozilla.com/gombot/v1/"),
                          Buffer(name),
                          append]);
}
exports.makeSalt = makeSalt;

function gombot_kdf(email, password) {
    var masterSalt = makeSalt("master", Buffer(email, "utf-8"));
    var secret = Buffer([]); // empty for now
    var masterKey_d = pbkdf2_sha256(Buffer.concat([secret,
                                                   Buffer(":"),
                                                   Buffer(password, "utf-8")]),
                                     masterSalt, 250*1000, 32);
    return masterKey_d
        .then(function(masterKey) {
            console.log("master", masterKey.toString("hex"));
            var authKey = pbkdf2_sha256_sync(masterKey, makeSalt("authentication"), 1, 32);
            var aesKey = pbkdf2_sha256_sync(masterKey, makeSalt("data/AES"), 1, 32);
            var hmacKey = pbkdf2_sha256_sync(masterKey, makeSalt("data/HMAC"), 1, 32);
            return {authKey: authKey, aesKey: aesKey, hmacKey: hmacKey};
        });
}
exports.gombot_kdf = gombot_kdf;

function test_one() {
    gombot_kdf("andré@example.org", "pässwörd")
        .then(function(keys) {
            console.log("authKey :", keys.authKey.toString("hex"));
            console.log("aesKey  :", keys.aesKey.toString("hex"));
            console.log("hmacKey :", keys.hmacKey.toString("hex"));
        })
        .then(null, function(err) {
            console.log("ERROR", err);
        });
}

exports.run_tests = function() {
    test_one();
    //console.log("'"+pbkdf2_sha256(Buffer("password"), Buffer("salt"), 100, 200).toString("hex")+"'");
}

if (require.main === module)
    exports.run_tests();
