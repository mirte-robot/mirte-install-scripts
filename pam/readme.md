# password module
requires 
sudo apt-get install libpam0g-dev

# Build
```sh
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
make install # requires sudo privileges
```

This will build the Mirte pam modules(warning and storepassword), install them to `/lib/security/limbirte_pam_xxx.so` and add the required lines to `/etc/pam.d/passwd`.

# passwd
The resulting `/etc/pam.d/passwd` should look like:
```
#
# The PAM configuration file for the Shadow `passwd' service
#
password required /lib/security/libmirte_pam_warn.so
@include common-password
password required /lib/security/libmirte_pam_storepassword.so
```
