# Future-revival work TODOS

- [x] Next session: build a simple hello world project in C
- [ ] Restore the contract check in `lib.nix` for parameters passed to Nickel
- [ ] Find a way to import any kind of source tree inside the Nickel part.
      Ideas:
        - Use a special placeholder on the Nickel side, that the Nix part
          interpret and substitute for actual store paths
        - Have them be just other inputs, and let the Nixel Nix library do the
          work (determine which source trees are coming directly from Nix, and
          which one are coming from other Nickel package definitions)
- [ ] In the future: something like `mkShell` (but simpler?)
