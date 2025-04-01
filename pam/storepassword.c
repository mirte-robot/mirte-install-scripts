#define PAM_SM_PASSWORD 1
#include "mirte_pam.h"
#include <ctype.h>
#include <locale.h>
PAM_EXTERN int pam_sm_chauthtok(pam_handle_t *pamh, int flags, int argc,
                                const char **argv) {
  if (flags & PAM_PRELIM_CHECK) {
    return PAM_SUCCESS;
  }
  char *pwd;
  char *user;
  int r = pam_get_item(pamh, PAM_AUTHTOK, (const void **)&pwd);
  pam_get_item(pamh, PAM_USER, (const void **)&user);
  savePassword(user, pwd);
  return PAM_SUCCESS;
}

void savePassword(char *username, char *passwd) {
  // Don't show anything when it is not the mirte user
  if (strcmp(username, mirte_username) != 0) {
    return;
  }
  // filter out string with non-ASCII characters, only allow a-zA-Z0-9
  // and some special characters
  char *new_passwd = (char *)malloc(strlen(passwd) + 1);
  if (new_passwd == NULL) {
    printf(RED "Mirte:\t" RESET "Memory allocation failed.\n");
    return;
  }
  int new_passwd_i = 0;
  for (int i = 0; i < strlen(passwd); i++) {
    if (isalpha(passwd[i]) || isdigit(passwd[i]) || passwd[i] == '-' ||
        passwd[i] == '_') {
      new_passwd[new_passwd_i] = passwd[i];
      new_passwd_i++;
    }
  }
  new_passwd[new_passwd_i] = '\0';
  if (new_passwd_i < 8) {
    printf(RED "Mirte:\t" RESET "Password is too short, not storing "
               "password for Wi-Fi.\n");
    free(new_passwd);
    return;
  }
  printf(GRN
         "Mirte:\t" RESET "The new password for \"%s\" is \"%s\".\n" GRN
         "Mirte:\t" RESET "The password will be updated for the webpages.\n" GRN
         "Mirte:\t" RESET "The Wi-Fi password will be updated at next boot!\n",
         username, passwd);
  if (strlen(new_passwd) != strlen(passwd)) {
    printf(RED "Mirte:\t" RESET
               "Original password contained non-ASCII characters, they are "
               "removed from the Wi-Fi password.\n" RED "Mirte:\t" RESET
               "New Wi-Fi password is \"%s\".\n",
           new_passwd);
    free(new_passwd);
    return;
  }
  if (!checkDirectory()) {
    printf(RED "Mirte:\t" RESET
               "Mirte home directory does not exist, not storing "
               "password for Wi-Fi.\n");
    return;
  }
  FILE *file = fopen(wifi_filename, "w");
  fprintf(file, "%s", new_passwd);
  fclose(file);
}

int checkDirectory() {
  DIR *dir = opendir(wifi_password_folder);
  if (dir) {
    /* Directory exists. */
    closedir(dir);
    return 1;
  } else // ENOENT or any other value
  {
    return 0;
  }
}