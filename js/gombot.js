
var str2bits = sjcl.codec.utf8String.toBits;
var bits2hex = sjcl.codec.hex.fromBits;

// including UTF-8 in this file without declaring the charset like:
//  <script src="gombot.js" type="text/javascript" charset="UTF-8"></script>
//  causes a double-decoding (WTF-8, for those in the know). 

function test() {
    var start = new Date().getTime();
    var secret = str2bits("");
    var masterKey = sjcl.misc.pbkdf2(secret, secret, 250*1000, 8*32);
    console.log("masterKey", bits2hex(masterKey));
    var end = new Date().getTime();
    console.log("elapsed", (end - start) / 1000);
}

test();
