# Constraints

What needs to be in Nickel to be usable for Nix.

- string context

## Primitive / effect

- derivation. JSON interchange. Loose of lazyness. Not a problem for the
  direction Nickel -> Nix because it morally takes JSON.
- Nickel-specific
- Module system OS

Transpiling Nix to Nickel. String context.

Simply add a way of nix builtins. Look at what other implementations of Nix lang
do. `rnix`, `hnix` parser e.g. `rnix-lsp`.

Transpiling Nix on the fly, or sync Nixpkgs. In any case the transpiler could be
separate, so that you can importFromDerivation when needed without polluting the
interpreter.

Other possibilities: FFI Nickel with Nix. Idea: using the same system for
caching flakes in Nix. Each Nix record is converted to a Nickel record, where
each field is a builtin effect to get the Nix value.

Is lazyness important for this kind of call this function ? Not sure, but in
general can't be ruled out.

And transpiling Nickel to Nix? Complex: contracts, merging.

## String context

G-exp. Or just special delimiters to do that. We would have to reimplement basic
operators on string. And the symbolic representation of a string.

Context could also be metadata. And basic operator would be able to see that and
merge the context.
