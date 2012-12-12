
import os, hashlib, hmac, binascii, struct
from pbkdf2 import PBKDF2
from Crypto.Cipher import AES

from gombot_kdf import do as do_kdf

tohex = binascii.hexlify

# AES-CBC, PKCS#5. SJCL.js can do that.

assert AES.block_size == 16

def pkcs5_padding(datalen):
    needed = 16-(datalen%16)
    return chr(needed)*needed

def encrypt(email, password, data):
    authKey, cryptKey = do_kdf(email, password)
    aesKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/AES", 1, 32)
    hmacKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/HMAC", 1, 32)
    IV = os.urandom(16)
    c = AES.new(aesKey, mode=AES.MODE_CBC, IV=IV)
    padded_data = data + pkcs5_padding(len(data))
    assert len(padded_data)%AES.block_size == 0, (len(padded_data), AES.block_size)
    ct = c.encrypt(padded_data)
    msg = IV+ct
    # [IV, enc(PADDEDDATA), mac(IV+enc(PADDEDDATA))]
    mac = hmac.new(hmacKey, msg, hashlib.sha256).digest()
    #print "enc", [tohex(IV), tohex(ct), tohex(mac)]
    msgmac = msg+mac
    return msgmac

def decrypt(email, password, msgmac):
    authKey, cryptKey = do_kdf(email, password)
    aesKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/AES", 1, 32)
    hmacKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/HMAC", 1, 32)
    msg,mac = msgmac[:-32], msgmac[-32:]
    # mac covers everything else: (IV+enc(data+padding))
    if mac != hmac.new(hmacKey, msg, hashlib.sha256).digest():
        raise ValueError("Corrupt encrypted data")
    IV,ct = msg[:16], msg[16:]
    #print "dec", [tohex(IV), tohex(ct), tohex(mac)]
    c = AES.new(aesKey, mode=AES.MODE_CBC, IV=IV)
    padded_data = c.decrypt(ct)
    pad = ord(padded_data[-1])
    data = padded_data[:-pad]
    return data

msgmac = encrypt(u"foo@example.org", u"password", "data")
print "msgmac is", tohex(msgmac)
print decrypt(u"foo@example.org", u"password", msgmac)
