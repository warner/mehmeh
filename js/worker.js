
importScripts("./sjcl.js");

var str2bits = sjcl.codec.utf8String.toBits;
var bits2hex = sjcl.codec.hex.fromBits;

function test() {
    var start = new Date().getTime();
    var secret = str2bits("");
    var masterKey = sjcl.misc.pbkdf2(secret, secret, 250*1000, 8*32);
    //console.log("masterKey", bits2hex(masterKey));
    var end = new Date().getTime();
    //console.log("elapsed", (end - start) / 1000);
    return bits2hex(masterKey);
}

function messageHandler(event) {
  //console.log("command", event.data.command);
  var masterKey = test();
  this.postMessage({masterKey: masterKey});
}

this.addEventListener("message", messageHandler, false);  
