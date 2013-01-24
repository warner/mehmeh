
var gombot = require("gombot");

// some static keys, so tests don't have to run the KDF each time. These
// are for "andré@example.org" and "pässwörd"

var staticKeys = {masterKey: "3eea9b91cc12eb6bef05662b03e19b42f602382bc556bd4dedad8d50533b78fe",
                  authKey: "dd976ae2c2f1935d1001d52ac834b77b5d6e0a7e168596afcabb5f02a3ad21dd",
                  aesKey: "588902f716bdb942340dcd77fa9148ad13202f8398ad4e23f413a0d7fdad6f12",
                  hmacKey: "f061928e6f6b06320dda1b0fea16897289a176fce0ca21b87e41559eda8c81eb"};

exports.test_gombot = function(test) {
    var d;
    var email = "andré@example.org";
    var password = "pässwörd";
    // unicode is [U+0070 U+00e4 U+0073 U+0073 U+0077 U+00f6 U+0072 U+0064]
    // UTF-8 expansion should be 70  c3 a4  73  73  77  c3 b6  72  64
    test.assertEqual(password.length, 8); // catch WTF-8 problems
    test.assertEqual(password.charCodeAt(0), 0x70);
    test.assertEqual(password.charCodeAt(1), 0xe4);
    test.assertEqual(password.charCodeAt(2), 0x73);
    d = gombot.kdf(email, password);
    d
        .then(function(keys) {
            test.assertEqual(keys.masterKey, staticKeys.masterKey);
            test.assertEqual(keys.authKey, staticKeys.authKey);
            test.assertEqual(keys.aesKey, staticKeys.aesKey);
            test.assertEqual(keys.hmacKey, staticKeys.hmacKey);
            var data = '{"kéy": "valuë2"}';
            var data_str = JSON.stringify(data);
            var forceIV = "45fea09e3db6333762a8c6ab8ac50548";
            var d1 = gombot.encrypt(keys, data_str, forceIV);
            return d1
                .then(function(encrypted) {
                    test.assertEqual(encrypted.msgmac_b64, "aWRlbnRpdHkubW96aWxsYS5jb20vZ29tYm90L3YxL2RhdGE6Rf6gnj22MzdiqMarisUFSPSkEr5WSozzGHOu8ySdE8109d/i/Ryme3sZVoRnIXKL82UrjP5wvdVrVDAxs0+ezIKnYXy3nssFx1PBVpt1Lkk=");
                    test.assertEqual(typeof(encrypted.elapsed), "number");
                    return gombot.decrypt(keys, encrypted.msgmac_b64);
                })
                .then(function(decrypted) {
                    test.assertEqual(decrypted.plaintext, data_str);
                    test.assertEqual(JSON.parse(decrypted.plaintext), data);
                    test.assertEqual(typeof(decrypted.elapsed), "number");
                });
        })
        .then(function() { test.done(); },
              function failure(err) { test.fail(err); test.done(); }
             );

    test.waitUntilDone();
};

// run those same tests again. One early version of the multiple-worker
// scheme couldn't handle being called more than once.
exports.test_gombot2 = exports.test_gombot;

exports.test_corrupt_msg = function(test) {
    var data = '{"kéy": "valuë2"}';
    var data_str = JSON.stringify(data);
    var msgmac_b64 = "aWRlbnRpdHkubW96aWxsYS5jb20vZ29tYm90L3YxL2RhdGE6Rf6gnj22MzdiqMarisUFSPSkEr5WSozzGHOu8ySdE8109d/i/Ryme3sZVoRnIXKL82UrjP5wvdVrVDAxs0+ezIKnYXy3nssFx1PBVpt1Lkk=";
    // msgmac_b64 is ver+IV+ciphertext+MAC
    // ver: aWRlbnRpdHkubW96aWxsYS5jb20vZ29tYm90L3YxL2RhdGE6
    // iv+ct: Rf6gnj22MzdiqMarisUFS P SkEr5WSozzGHOu8ySdE8109d/i/Ryme3sZVoRnIXKL
    //  (the "P" shares bits of both iv and ciphertext)
    // mac: 82UrjP5wvdVrVDAxs0+ezIKnYXy3nssFx1PBVpt1Lkk=
    // so to corrupt just the ciphertext, let's clobber the SkEr5W part
    var corrupt = msgmac_b64.replace("SkEr5W", "skewer");
    var d = gombot.decrypt(staticKeys, corrupt);
    d.then(function(plaintext) {
        console.log("oops, not supposed to pass");
        test.fail("oops, not supposed to pass");
        test.done();
    }, function failure(err) {
        test.assertEqual(err, "Error: Corrupt encrypted data");
        test.pass();
        test.done();
    });
    test.waitUntilDone();
};

exports.test_bad_version = function(test) {
    var data = '{"kéy": "valuë2"}';
    var data_str = JSON.stringify(data);
    var msgmac_b64 = "aWRlbnRpdHkubW96aWxsYS5jb20vZ29tYm90L3YxL2RhdGE6Rf6gnj22MzdiqMarisUFSPSkEr5WSozzGHOu8ySdE8109d/i/Ryme3sZVoRnIXKL82UrjP5wvdVrVDAxs0+ezIKnYXy3nssFx1PBVpt1Lkk=";
    // msgmac_b64 is ver+IV+ciphertext+MAC
    // ver: aWRlbnRpdHkubW96aWxsYS5jb20vZ29tYm90L3YxL2RhdGE6
    // that's base64("identity.mozilla.com/gombot/v1/data:")
    // we replace it with base64("identity.mozilla.com/gombot/v0/data")
    var badVersion = msgmac_b64.replace("aWRlbnRpdHkubW96aWxsYS5jb20vZ29tYm90L3YxL2RhdGE6", "aWRlbnRpdHkubW96aWxsYS5jb20vZ29tYm90L3YwL2RhdGE6");
    var d = gombot.decrypt(staticKeys, badVersion);
    d.then(function(plaintext) {
        console.log("oops, not supposed to pass");
        test.fail("oops, not supposed to pass");
        test.done();
    }, function failure(err) {
        test.assertEqual(err, "Error: unrecognized version prefix 'identity.mozilla.com/gombot/v0/data:'");
        test.pass();
        test.done();
    });
    test.waitUntilDone();
};
