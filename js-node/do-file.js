
// do-file.js encrypt EMAIL PASSWORD FILENAME >FILENAME.gombotted
// do-file.js decrypt EMAIL PASSWORD FILENAME.gombotted >FILENAME

var fs = require("fs");
var gombot = require("./gombot");

if (process.argv[2] == "encrypt") {
    var fn = process.argv[5];
    var keys = gombot.gombot_kdf(process.argv[3], process.argv[4]);
    var plaintext = fs.readFileSync(fn);
    var ct_b64 = gombot.encrypt(keys, plaintext);
    fs.writeFileSync(fn+".gombotted", Buffer(ct_b64+"\n"));
    console.log("wrote ciphertext to", fn+".gombotted");
} else if (process.argv[2] == "decrypt") {
    var fn = process.argv[5];
    if (fn.slice(fn.length-".gombotted".length) != ".gombotted")
        throw new Error("filename must end in .gombotted");
    var outfn = fn.slice(0, fn.length-".gombotted".length);
    var keys = gombot.gombot_kdf(process.argv[3], process.argv[4]);
    var ciphertext_b64 = fs.readFileSync(process.argv[5]).toString();
    var plaintext = gombot.decrypt(keys, ciphertext_b64);
    fs.writeFileSync(outfn, plaintext);
    console.log("wrote plaintext to", outfn);
} else {
    console.log("do-file.js encrypt EMAIL PASSWORD FILENAME >FILENAME.gombotted");
    console.log("do-file.js decrypt EMAIL PASSWORD FILENAME.gombotted >FILENAME");
}
