# -*- encoding: utf-8 -*-

import os, hashlib, hmac, binascii
from pbkdf2 import PBKDF2
from Crypto.Cipher import AES

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

def dump(which, s, stride=16):
    print "%s: %s" % (which, "\n".join([tohex(s)[i:i+stride]
                                        for i in range(0, len(tohex(s)), stride)
                                        ]))

version_prefix = "identity.mozilla.com/gombot/v1:"
def salt(name):
    return "identity.mozilla.com/gombot/v1/%s" % name

def do_kdf(email, password, secret=""):
    dump("email", email.encode("utf-8"))
    dump("password", password.encode("utf-8"))
    derivedKey = PBKDF2(secret+password.encode("utf-8"),
                        salt("derivation:" + email.encode("utf-8")),
                        250*1000, 256/8)
    dump("master", derivedKey)
    authKey = PBKDF2(derivedKey, salt("authentication"), 1, 256/8)
    cryptKey = PBKDF2(derivedKey, salt("encryption"), 1, 256/8)
    dump(" authKey ", authKey)
    dump(" cryptKey", cryptKey)
    return authKey, cryptKey



# AES-CBC, PKCS#5. SJCL.js can do that.

assert AES.block_size == 16

def pkcs5_padding(datalen):
    needed = 16-(datalen%16)
    return chr(needed)*needed

def encrypt(email, password, data, secret=""):
    authKey, cryptKey = do_kdf(email, password, secret)
    aesKey = PBKDF2(cryptKey, salt("data/AES"), 1, 32)
    hmacKey = PBKDF2(cryptKey, salt("data/HMAC"), 1, 32)
    dump("aesKey", aesKey)
    dump("hmacKey", hmacKey)
    IV = os.urandom(16)
    dump("IV", IV)
    c = AES.new(aesKey, mode=AES.MODE_CBC, IV=IV)
    padded_data = data + pkcs5_padding(len(data))
    assert len(padded_data)%AES.block_size == 0, (len(padded_data), AES.block_size)
    ct = c.encrypt(padded_data)
    msg = IV+ct
    # [IV, enc(PADDEDDATA), mac(IV+enc(PADDEDDATA))]
    mac = hmac.new(hmacKey, msg, hashlib.sha256).digest()
    print "enc", [tohex(IV), tohex(ct), tohex(mac)]
    dump("ct", ct)
    versioned_msgmac = version_prefix+msg+mac
    dump("versioned_msgmac", versioned_msgmac, stride=32)
    return versioned_msgmac

def decrypt(email, password, versioned_msgmac, secret=""):
    assert versioned_msgmac.startswith(version_prefix)
    msgmac = versioned_msgmac[len(version_prefix):]
    authKey, cryptKey = do_kdf(email, password, secret)
    aesKey = PBKDF2(cryptKey, salt("data/AES"), 1, 32)
    dump("aesKey", aesKey)
    hmacKey = PBKDF2(cryptKey, salt("data/HMAC"), 1, 32)
    msg,mac = msgmac[:-32], msgmac[-32:]
    # mac covers everything else: (IV+enc(data+padding))
    if mac != hmac.new(hmacKey, msg, hashlib.sha256).digest():
        raise ValueError("Corrupt encrypted data")
    IV,ct = msg[:16], msg[16:]
    print "dec", [tohex(IV), tohex(ct), tohex(mac)]
    c = AES.new(aesKey, mode=AES.MODE_CBC, IV=IV)
    padded_data = c.decrypt(ct)
    print "padded data", tohex(padded_data)
    pad = ord(padded_data[-1])
    data = padded_data[:-pad]
    return data



if __name__ == '__main__':
    def one():
        email = u"foo@example.org"
        password = u"password"
        authKey, cryptKey = do_kdf(email, password)
        print "1 authKey :", tohex(authKey)
        print "1 cryptKey:", tohex(cryptKey)
    #one()

    def two():
        email = u"andré@example.org"
        password = u"pässwörd"
        data = '{"kéy": "valuë2"}'
        m = encrypt(email, password, data)
    two()
