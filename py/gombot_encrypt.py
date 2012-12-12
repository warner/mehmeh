
import os, hashlib, hmac, binascii, struct
from pbkdf2 import PBKDF2
from Crypto.Cipher import AES

from gombot_kdf import do as do_kdf

tohex = binascii.hexlify

def padding_needed(datalen):
    needed = 0
    while (datalen+needed) % 16 != 0:
        needed += 1
    return needed

def encrypt(email, password, data):
    authKey, cryptKey = do_kdf(email, password)
    aesKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/AES", 1, 32)
    hmacKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/HMAC", 1, 32)
    IV = os.urandom(16)
    c = AES.new(aesKey, mode=AES.MODE_CBC, IV=IV)
    assert AES.block_size == 16
    padded_data = data + "\x00" * padding_needed(len(data))
    data_len = struct.pack(">Q", len(data))
    assert len(data_len) == 8
    ct = c.encrypt(padded_data)
    msg = data_len+IV+ct
    # [DATALEN, IV, enc(PADDEDDATA), mac(DATALEN+IV+enc(PADDEDDATA))]
    mac = hmac.new(hmacKey, msg, hashlib.sha256).digest()
    #print "enc", [tohex(data_len), tohex(IV), tohex(ct), tohex(mac)]
    msgmac = msg+mac
    return msgmac

def decrypt(email, password, msgmac):
    authKey, cryptKey = do_kdf(email, password)
    aesKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/AES", 1, 32)
    hmacKey = PBKDF2(cryptKey, "identity.mozilla.com/gombot/v1/data/HMAC", 1, 32)
    msg = msgmac[:-32]
    mac = msgmac[-32:] # covers everything else: (DATALEN, IV, enc())
    if mac != hmac.new(hmacKey, msg, hashlib.sha256).digest():
        raise ValueError("Corrupt encrypted data")
    (datalen,) = struct.unpack(">Q", msg[:8])
    IV = msg[8:8+16]
    ct = msg[8+16:]
    #print "dec", [datalen, tohex(msg[:8]), tohex(IV), tohex(ct), tohex(mac)]
    c = AES.new(aesKey, mode=AES.MODE_CBC, IV=IV)
    padded_data = c.decrypt(ct)
    data = padded_data[:datalen]
    return data

msgmac = encrypt(u"foo@example.org", u"password", "data")
print "msgmac is", tohex(msgmac)
print decrypt(u"foo@example.org", u"password", msgmac)
