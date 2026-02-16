# mirte-install-scripts

These scripts will install all the software needed for the MIRTE OS. This
can be run when creating an image, or on the robot itself.

## Install

You can install this by running the main script:

```
./install_mirte.sh
```

## Checks

To contribute to this repository the code needs to pass the shell
[style checks]().

- [shfmt](https://github.com/mvdan/sh): styling (whitespace) of all shell scripts


  To check this locally before you commit/push:
  ```sh
  curl -sS https://webi.sh/shfmt | sh
  find . -type f -name "*.sh" -print0 | xargs -0 shfmt -d
  # Fix by using:
  find . -type f -name "*.sh" -print0 | xargs -0 shfmt -w
  ```

- [ShellCheck](https://github.com/koalaman/shellcheck): static analysis to find
  (possible) bugs. Only errors and warnings are enabled.

  To check this locally before you commit/push:
  ```sh
  curl -sS https://webi.sh/shellcheck | sh
  find . -type f -name "*.sh" -print0 | xargs -0 shellcheck --severity=warning
  # Fix manually
  ```

## License

This work is licensed under a Apache-2.0 OSS license.
