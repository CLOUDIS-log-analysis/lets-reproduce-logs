# Install nix
https://github.com/DeterminateSystems/nix-installer

```shell
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

uninstall:
```shell
/nix/nix-installer uninstall
```

optionally, you can install direnv to run command:
```shell
direnv allow
```
but it can be replace by:
```shell
nix develop
```
