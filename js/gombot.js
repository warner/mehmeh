

// strings are managed as sjcl.bitArray most everywhere.
// sjcl.bitArray.concat(a,b) works, but a.concat(b) does not.
// sjcl.bitArray.bitSlice(a, start, end) works, but is indexed by bit, not by
// byte.
//
//  bits = sjcl.codec.utf8String.toBits(string)
//  b64str = sjcl.codec.base64.fromBits(bits)

function assertBits(a) {
    if (!a.__prototype__ === sjcl.bitArray) {
        console.log("Hey, non-bitArray '"+a+"'");
        alert("Hey, non-bitArray '"+a+"'");
    }
}

var concatBits = sjcl.bitArray.concat;
var str2bits = sjcl.codec.utf8String.toBits;
var bits2b64 = sjcl.codec.base64.fromBits;
var bits2hex = sjcl.codec.hex.fromBits;
function sliceBits(bits, start, end) { // byte offsets
    return sjcl.bitArray.bitSlice(bits, 8*start, 8*end);
}
function logBits(name, bits) {
    console.log(name, bits2hex(bits), sjcl.bitArray.bitLength(bits));
}

function makeSalt(name_str, extra) {
    var out = str2bits("identity.mozilla.com/gombot/v1/");
    out = concatBits(out, str2bits(name_str));
    if (extra) {
        assertBits(extra);
        out = concatBits(out, str2bits(":"));
        out = concatBits(out, extra);
    }
    return out;
}

function gombot_kdf(email_str, password_str) {
    var masterSalt = makeSalt("master", str2bits(email_str));
    var secret = str2bits("");
    var masterSecret = concatBits(concatBits(secret, str2bits(":")),
                                  str2bits(password_str));
    logBits("masterSalt", masterSalt);
    logBits("masterSecret", masterSecret);
    // sjcl's PBKDF2 defaults to HMAC-SHA256
    var masterKey = sjcl.misc.pbkdf2(masterSecret, masterSalt, 250*1000, 8*32);
    logBits("masterKey", masterKey);
    var authKey = sjcl.misc.pbkdf2(masterKey, makeSalt("authentication"), 1, 8*32);
    var aesKey = sjcl.misc.pbkdf2(masterKey, makeSalt("data/AES"), 1, 8*32);
    var hmacKey = sjcl.misc.pbkdf2(masterKey, makeSalt("data/HMAC"), 1, 8*32);
    logBits("authKey", authKey);
    logBits("aesKey", aesKey);
    logBits("hmacKey", hmacKey);
    return {authKey: authKey, aesKey: aesKey, hmacKey: hmacKey};
}

// including UTF-8 in this file without declaring the charset like:
//  <script src="gombot.js" type="text/javascript" charset="UTF-8"></script>
//  causes a double-decoding (WTF-8, for those in the know). 

function test() {
    var email = "andré@example.org";
    var password = "pässwörd";
    //var email = "andr\u00e9@example.org"; // ugly workaround
    //var password = "p\u00e4ssw\u00f6rd";
    //console.log(email.charCodeAt(4), 0xe9);
    if (bits2hex(str2bits(password)) != "70c3a4737377c3b67264") {
        console.log("WTF-8 PROBLEM!");
    }
    logBits("email", str2bits(email));
    logBits("password", str2bits(password));
    var data = '{"kéy": "valuë2"}';
    var start = new Date().getTime();
    gombot_kdf(email, password);
    var end = new Date().getTime();
    console.log("elapsed", (end - start) / 1000);
}

test();
