
var crypto = require("crypto");

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
    var masterSecret = Buffer.concat([secret,
                                      Buffer(":"),
                                      Buffer(password, "utf-8")]);
    console.log("masterSalt", masterSalt.toString("hex"));
    console.log("masterSecret", masterSecret.toString("hex"));
    var masterKey = pbkdf2_sha256_sync(masterSecret, masterSalt, 250*1000, 32);
    console.log("master", masterKey.toString("hex"));
    var authKey = pbkdf2_sha256_sync(masterKey, makeSalt("authentication"), 1, 32);
    var aesKey = pbkdf2_sha256_sync(masterKey, makeSalt("data/AES"), 1, 32);
    var hmacKey = pbkdf2_sha256_sync(masterKey, makeSalt("data/HMAC"), 1, 32);
    console.log("authKey", authKey.toString("hex"));
    console.log("aesKey", aesKey.toString("hex"));
    console.log("hmacKey", hmacKey.toString("hex"));
    return {authKey: authKey, aesKey: aesKey, hmacKey: hmacKey};
}
exports.gombot_kdf = gombot_kdf;

function test_keys() {
    var keys = gombot_kdf("andré@example.org", "pässwörd");
    console.log("authKey :", keys.authKey.toString("hex"));
    console.log("aesKey  :", keys.aesKey.toString("hex"));
    console.log("hmacKey :", keys.hmacKey.toString("hex"));
}

var version_prefix = Buffer("identity.mozilla.com/gombot/v1/data:");

function encrypt(keys, data, forceIV) {
    var IV = Buffer(crypto.randomBytes(16), "binary");
    if (forceIV)
        IV = forceIV;
    var c = crypto.createCipheriv("aes256", keys.aesKey.toString("binary"), IV);
    var msg = Buffer.concat([version_prefix,
                             IV,
                             Buffer(c.update(data), "binary"),
                             Buffer(c.final(), "binary")]);
    var h = crypto.createHmac("sha256", keys.hmacKey.toString("binary"));
    h.update(msg.toString("binary"));
    var mac = Buffer(h.digest(), "binary");
    //console.log([IV.toString("hex"), msg.toString("hex"), mac.toString("hex")]);
    return Buffer.concat([msg, mac]).toString("base64");
}
exports.encrypt = encrypt;

function compare(a, b) { // vaguely constant-time
    if (a.length != b.length)
        return false;
    var reduction = 0;
    for (var i=0; i < a.length; i++)
        reduction |= (a[i] ^ b[i]);
    return reduction == 0;
}
exports.compare = compare;

function decrypt(keys, msgmac_b64) {
    var msgmac = new Buffer(msgmac_b64, "base64");
    console.log("msgmac", msgmac.toString("hex"));
    var prelen = version_prefix.length;
    var gotPrefix = msgmac.slice(0, prelen);
    if (gotPrefix.toString("hex") != version_prefix.toString("hex"))
        throw Error("Unrecognized version prefix '"+gotPrefix+"'");
    var h = crypto.createHmac("sha256", keys.hmacKey.toString("binary"));
    h.update(msgmac.slice(0, msgmac.length-32).toString("binary"));
    var expectedHmac = Buffer(h.digest(), "binary");
    var gotHmac = msgmac.slice(msgmac.length-32, msgmac.length);
    if (!compare(expectedHmac, gotHmac))
        throw Error("Corrupt encrypted data");
    var IV = msgmac.slice(prelen, prelen+16);
    var msg = msgmac.slice(prelen+16, msgmac.length-32);
    var c = crypto.createDecipheriv("aes256", keys.aesKey.toString("binary"), IV);
    var data = Buffer.concat([Buffer(c.update(msg.toString("binary")), "binary"),
                              Buffer(c.final(), "binary")]);
    return data;
}
exports.decrypt = decrypt;

function test_one() {
    var data = Buffer('{"kéy": "valuë2"}');
    var keys = gombot_kdf("andré@example.org", "pässwörd");
    var m = encrypt(keys, data
                    //,Buffer("45fea09e3db6333762a8c6ab8ac50548", "hex")
                   );
    console.log("m", m.toString("hex"));
    var data2 = decrypt(keys, m);
    console.log("data:", data2.toString("hex"));
    if (data.toString("hex") == data2.toString("hex"))
        console.log("ok");
    else
        console.log("NOT OK");
}

exports.run_tests = function() {
    //test_keys();
    test_one();
}

if (require.main === module)
    exports.run_tests();
