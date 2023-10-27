## Using without flakes

While Organist is focused on usage with flakes, you can use it without them like this:

```nix
# shell.nix
let
  pkgs = import <nixpkgs> {};
  organistSrc = builtins.fetchTarball "https://github.com/nickel-lang/organist/archive/main.tar.gz";
  organist = pkgs.callPackage "${organistSrc}/lib/lib.nix" {inherit organistSrc;};
in
  (organist.importNcl {baseDir = ./.;}).shells.default
```

And then use `nix develop -f shell.nix` as usual. Note that this will not use nixpkgs and Nickel from Organist's flake.lock.
You can use flake-compat to use them:

```nix
# shell.nix
let
  flake-compat = builtins.fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
  organistSrc = builtins.fetchTarball "https://github.com/nickel-lang/organist/archive/main.tar.gz";
  organist = ((import flake-compat) {src = organistSrc;}).defaultNix.lib.${builtins.currentSystem};
in
  (organist.importNcl {baseDir = ./.;}).shells.default
```
