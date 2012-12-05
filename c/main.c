#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sha256.h"

static unsigned const char *saltDerive = "identity.mozilla.com/gombot/v1/derivation:";
static unsigned const char * saltAuth = "identity.mozilla.com/gombot/v1/authentication";
static unsigned const char * saltCrypt = "identity.mozilla.com/gombot/v1/encryption";

void kdf(int which, const char *email, const char *passwd) {
    unsigned char * salt;
    unsigned char dkey[32];
    unsigned char akey[32];
    unsigned char ckey[32];
    int i;

    salt = malloc(strlen(saltDerive) + strlen(passwd) + 1);
    memcpy(salt, saltDerive, strlen(saltDerive));
    memcpy(salt+strlen(saltDerive), email, strlen(email)+1); // include NUL

    s_PBKDF2_SHA256(passwd, strlen(passwd), salt, strlen(salt), 250000, dkey, sizeof(dkey));
    s_PBKDF2_SHA256(dkey, sizeof(dkey), saltAuth, strlen(saltAuth), 1, akey, sizeof(akey));
    s_PBKDF2_SHA256(dkey, sizeof(dkey), saltCrypt, strlen(saltCrypt), 1, ckey, sizeof(ckey));
    free(salt);

    printf("%d authKey : ", which);
    for (i=0; i<sizeof(akey); i++) {
        printf("%02x", akey[i]);
    }
    printf("\n");

    printf("%d cryptKey: ", which);
    for (i=0; i<sizeof(ckey); i++) {
        printf("%02x", ckey[i]);
    }
    printf("\n");
}


int main()
{
    kdf(1, "foo@example.org", "password");
    kdf(2, "andr\xc3\xa9@example.org", "p\xc3\xa4ssw\xc3\xb6rd");
    return 0;
}
