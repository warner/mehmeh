# -*- encoding: utf-8 -*-

import hashlib, hmac, binascii

assert len(hmac.new("", "", hashlib.sha256).digest()) == 256/8 == 32
tohex = binascii.hexlify

def HMAC(key, msg):
    return hmac.new(key, msg, hashlib.sha256).digest()
def HKDF_PRK(XTS, SKM):
    """XTS is the extractor salt, SKM is the secret key material. If you
    really don't want a salt, use an empty string."""
    return HMAC(XTS, SKM)

def HKDF_K(PRK, length_bytes, CTXinfo):
    out = []
    k = ""
    count = 0
    generated = 0
    while generated < length_bytes:
        assert count < 256
        k = HMAC(PRK, k + CTXinfo + chr(count))
        out.append(k)
        generated += len(k)
        count += 1
    return "".join(out)[:length_bytes]

def HKDF(XTS, SKM, CTXinfo, length_bytes):
    return HKDF_K(HKDF_PRK(XTS, SKM), length_bytes, CTXinfo)

from pbkdf2 import PBKDF2

def do(email, password):
    salt = "identity.mozilla.com/gombot/v1/derivation:" + email.encode("utf-8")
    derivedKey = PBKDF2(password.encode("utf-8"), salt, 250*1000, 256/8)
    #print "derived", tohex(derivedKey)
    authKey = PBKDF2(derivedKey,
                     "identity.mozilla.com/gombot/v1/authentication",
                     1, 256/8)
    cryptKey = PBKDF2(derivedKey,
                     "identity.mozilla.com/gombot/v1/encryption",
                      1, 256/8)
    return authKey, cryptKey

if __name__ == '__main__':
    def one():
        email = u"foo@example.org"
        password = u"password"
        authKey, cryptKey = do(email, password)
        print "1 authKey :", tohex(authKey)
        print "1 cryptKey:", tohex(cryptKey)
    one()

    def two():
        email = u"andré@example.org"
        password = u"pässwörd"
        authKey, cryptKey = do(email, password)
        print "2 authKey :", tohex(authKey)
        print "2 cryptKey:", tohex(cryptKey)
    two()

