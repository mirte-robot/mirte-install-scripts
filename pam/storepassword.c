#define PAM_SM_PASSWORD 1
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <pwd.h>

PAM_EXTERN int pam_sm_chauthtok(pam_handle_t *pamh, int flags,
                                int argc, const char **argv)
{
    if (flags == PAM_PRELIM_CHECK)
    {
        printf("Your password will be stored in plaintext, so don't make it your cats name! The web-login and the Mirte-hotspot will get the same password.");
        return PAM_SUCCESS;
    }
    char *pwd;

    int r = pam_get_item(pamh, PAM_AUTHTOK, (const void **)&pwd);
    printf("Your new password is \"%s\". Very nice!\n", pwd);
    return PAM_SUCCESS;
}
