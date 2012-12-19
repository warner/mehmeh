
var crypto = require("crypto");
var kdf = require("./gombot-kdf.js").gombot_kdf;
var makeSalt = require("./gombot-kdf.js").makeSalt;
var pbkdf2_sha256_sync = require("./gombot-kdf.js").pbkdf2_sha256_sync;

function encrypt(email, password, data) {
    return kdf(email, password)
        .spread(function(authKey, cryptKey) {return cryptKey;})
        .then(function(cryptKey) {
            var aesKey = pbkdf2_sha256_sync(cryptKey, makeSalt("data/AES"), 1, 32);
            //console.log("aesKey", aesKey.toString("hex"));
            var hmacKey = pbkdf2_sha256_sync(cryptKey, makeSalt("data/HMAC"), 1, 32);
            var IV = Buffer(crypto.randomBytes(16), "binary");
            var c = crypto.createCipheriv("aes256", aesKey.toString("binary"), IV);
            var ct = Buffer.concat([IV, 
                                    Buffer(c.update(data), "binary"), 
                                    Buffer(c.final(), "binary")]);
            var h = crypto.createHmac("sha256", hmacKey.toString("binary"));
            h.update(ct.toString("binary"));
            var mac = Buffer(h.digest(), "binary");
            //console.log([IV.toString("hex"), ct.toString("hex"), mac.toString("hex")]);
            return Buffer.concat([ct, mac]);
        })
    ;
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

function decrypt(email, password, msgmac) {
    return kdf(email, password)
        .spread(function(authKey, cryptKey) {return cryptKey;})
        .then(function(cryptKey) {
            var aesKey = pbkdf2_sha256_sync(cryptKey, makeSalt("data/AES"), 1, 32);
            //console.log("aesKey", aesKey.toString("hex"));
            var hmacKey = pbkdf2_sha256_sync(cryptKey, makeSalt("data/HMAC"), 1, 32);
            var h = crypto.createHmac("sha256", hmacKey.toString("binary"));
            h.update(msgmac.slice(0, msgmac.length-32).toString("binary"));
            var expectedHmac = Buffer(h.digest(), "binary");
            var gotHmac = msgmac.slice(msgmac.length-32, msgmac.length);
            if (!compare(expectedHmac, gotHmac))
                throw Error("Corrupt encrypted data");
            var IV = msgmac.slice(0, 16);
            var msg = msgmac.slice(16, msgmac.length-32);
            var c = crypto.createDecipheriv("aes256", aesKey.toString("binary"), IV);
            var data = Buffer.concat([Buffer(c.update(msg.toString("binary")), "binary"), 
                                      Buffer(c.final(), "binary")]);
            return data;
        })
    ;
}
exports.decrypt = decrypt;

function test_one() {
    encrypt("foo@example.org", "password", "data")
        .then(function(msgmac) {console.log(msgmac.toString("hex"));
                                return decrypt("foo@example.org", "password", 
                                               msgmac);})
        .then(function(data) {console.log("data:", data.toString("hex"));
                              if (data.toString("ascii") == "data")
                                  console.log("ok");
                              else
                                  console.log("NOT OK");
                              })
        .then(null, console.log)
    ;
}

function test_one_a() {
    decrypt("foo@example.org", "password",
            Buffer("266cb972c2b403031d960074978f1c59c3700021b18f772883dd9abee880ecb27b8545d608257b5e44466abcc0a499de551b60a61e9ff25abe03108f08e2a1fb", "hex"))
        .then(function(data) {console.log("data:", data.toString("hex"));
                              if (data.toString("ascii") == "data")
                                  console.log("ok");
                              else
                                  console.log("NOT OK");
                              })
        .then(null, console.log)
    ;
}

test_one_a();
