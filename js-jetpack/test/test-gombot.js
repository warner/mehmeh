
var gombot = require("gombot");

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
            test.assertEqual(keys.masterKey, "3eea9b91cc12eb6bef05662b03e19b42f602382bc556bd4dedad8d50533b78fe");
            test.assertEqual(keys.authKey, "dd976ae2c2f1935d1001d52ac834b77b5d6e0a7e168596afcabb5f02a3ad21dd");
            test.assertEqual(keys.aesKey, "588902f716bdb942340dcd77fa9148ad13202f8398ad4e23f413a0d7fdad6f12");
            test.assertEqual(keys.hmacKey, "f061928e6f6b06320dda1b0fea16897289a176fce0ca21b87e41559eda8c81eb");
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
