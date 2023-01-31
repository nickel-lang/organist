# Roadmap for nickel-nix/future

1. Write a few basic package definitions, from simplest:
    1. hello world
    2. shell script calling to hello.
    3. shell script calling to hello with different greeting.
   With a function combining this into an overridable set of derivations
   (`combine`).
   Each a package has discoverable configuration options.
2. Actually build one package.
3. Use one package from Nixpkgs.
n. Having a modular replacement for stdenv. Do we want the bash? If we want to
   support Windows, probably not. Choosing the right shell is important.
