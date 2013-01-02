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
    print "%s:\n%s\n" % (which,
                         "\n".join([tohex(s)[i:i+stride]
                                    for i in range(0, len(tohex(s)), stride)
                                    ]))

version_prefix = "identity.mozilla.com/gombot/v1/data:"
def salt(name):
    return "identity.mozilla.com/gombot/v1/%s" % name

def do_kdf(email, password, secret=""):
    dump("email", email.encode("utf-8"))
    dump("password", password.encode("utf-8"))
    masterKey = PBKDF2(secret+":"+password.encode("utf-8"),
                       salt("master:" + email.encode("utf-8")),
                       250*1000, 256/8)
    dump("master", masterKey)
    authKey = PBKDF2(masterKey, salt("authentication"), 1, 256/8)
    aesKey = PBKDF2(masterKey, salt("data/AES"), 1, 256/8)
    hmacKey = PBKDF2(masterKey, salt("data/HMAC"), 1, 256/8)
    dump(" authKey ", authKey)
    dump(" aesKey", aesKey)
    dump(" hmacKey", hmacKey)
    return authKey, aesKey, hmacKey



# AES-CBC, PKCS#5. SJCL.js can do that.

assert AES.block_size == 16

def pkcs5_padding(datalen):
    needed = 16-(datalen%16)
    return chr(needed)*needed

def encrypt(email, password, data, secret="", forceIV=None):
    authKey, aesKey, hmacKey = do_kdf(email, password, secret)
    IV = forceIV or os.urandom(16)
    dump("IV", IV)
    c = AES.new(aesKey, mode=AES.MODE_CBC, IV=IV)
    padded_data = data + pkcs5_padding(len(data))
    assert len(padded_data)%AES.block_size == 0, (len(padded_data), AES.block_size)
    ct = c.encrypt(padded_data)
    msg = version_prefix+IV+ct
    # [prefix, IV, enc(PADDEDDATA), mac(prefix+IV+enc(PADDEDDATA))]
    mac = hmac.new(hmacKey, msg, hashlib.sha256).digest()
    msgmac = msg+mac
    print "enc", [tohex(version_prefix), tohex(IV), tohex(ct), tohex(mac)]
    dump("ct", ct)
    dump("mac", mac)
    dump("msgmac", msgmac, stride=32)
    return msgmac

def decrypt(email, password, msgmac, secret=""):
    # we check this before checking the MAC, since it isn't secret, and will
    # detect gross version mismatches early
    prelen = len(version_prefix)
    if not msgmac.startswith(version_prefix):
        raise ValueError("unrecognized version prefix '%s'" % msgmac[:prelen])

    authKey, aesKey, hmacKey = do_kdf(email, password, secret)
    msg,mac = msgmac[:-32], msgmac[-32:]
    # mac covers everything else: (prefix+IV+enc(data+padding))
    if mac != hmac.new(hmacKey, msg, hashlib.sha256).digest():
        raise ValueError("Corrupt encrypted data")
    prefix,IV,ct = msg[:prelen], msg[prelen:prelen+16], msg[prelen+16:]
    print "dec", [tohex(prefix), tohex(IV), tohex(ct), tohex(mac)]
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
        m = encrypt(email, password, data,
                    forceIV="45fea09e3db6333762a8c6ab8ac50548".decode("hex")
                    )
        print decrypt(email, password, m)
    two()
