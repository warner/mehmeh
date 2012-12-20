# -*- encoding: utf-8 -*-

import os, hashlib, hmac, binascii
from pbkdf2 import PBKDF2
from Crypto.Cipher import AES

assert len(hmac.new("", "", hashlib.sha256).digest()) == 256/8 == 32
tohex = binascii.hexlify

def HMAC(key, msg):
    return hmac.new(key, msg, hashlib.sha256).digest()

def dump(which, s, stride=16):
    print "%s:\n%s\n" % (which,
                         "\n".join([tohex(s)[i:i+stride]
                                    for i in range(0, len(tohex(s)), stride)
                                    ]))

def salt(name):
    return "identity.mozilla.com/gombot/v1/%s" % name

def do_kdf(email, password, secret=""):
    dump("email", email.encode("utf-8"))
    dump("password", password.encode("utf-8"))
    masterKey = PBKDF2(secret+":"+password.encode("utf-8"),
                       salt("master:" + email.encode("utf-8")),
                       250*1000, 256/8)
    dump("master", masterKey)
    return
    authKey = PBKDF2(masterKey, salt("authentication"), 1, 256/8)
    aesKey = PBKDF2(masterKey, salt("data/AES"), 1, 256/8)
    hmacKey = PBKDF2(masterKey, salt("data/HMAC"), 1, 256/8)
    dump(" authKey ", authKey)
    dump(" aesKey", aesKey)
    dump(" hmacKey", hmacKey)
    return authKey, aesKey, hmacKey

email = u"andré@example.org"
password = u"pässwörd"
do_kdf(email, password)
