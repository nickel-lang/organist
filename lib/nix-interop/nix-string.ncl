let type_field = "$__organist_type" in

let predicate = {
  is_nix_string = fun value =>
    std.is_record value
    && std.record.has_field type_field value
    && value."%{type_field}" == "nixString",
  is_nix_path = fun x =>
    std.is_record x
    && std.record.has_field type_field x
    && x."%{type_field}" == "nixPath",
  is_nix_placeholder = fun x =>
    std.is_record x
    && std.record.has_field type_field x
    && x."%{type_field}" == "nixPlaceholder",
  is_nix_to_file = fun x =>
    std.is_record x
    && std.record.has_field type_field x
    && x."%{type_field}" == "nixToFile",
  is_nix_input = fun x =>
    std.is_record x
    && std.record.has_field type_field x
    && x."%{type_field}" == "nixInput",
  is_nickel_derivation = fun x =>
    std.is_record x
    && std.record.has_field type_field x
    && x."%{type_field}" == "nickelDerivation",
  is_derivation = fun x =>
    is_nickel_derivation x
    || is_nix_input x,
  is_nix_call = fun value =>
    std.is_record value
    && std.record.has_field type_field value
    && value."%{type_field}" == "callNix",
  is_string_fragment = fun x =>
    is_derivation x
    || std.is_string x
    || is_nix_path x
    || is_nix_placeholder x
    || is_nix_to_file x
    || is_nix_call x
}
in

let mk_nix_string = fun fs =>
  {
    "%{type_field}" = "nixString",
    fragments = fs,
  }
in
{

  NixStringFragment | doc "A fragment of a Nix string (or a string with context). See `NixString`"
    = std.contract.from_predicate predicate.is_string_fragment,

  NixSymbolicString
    | doc m%"
      A symbolic string with the `'nix` prefix, as output by the Nickel
      parser. Used as a subcontract for `NixString`.
      "%
    = {
      prefix | [| 'nix |],
      tag | [| 'SymbolicString |],
      fragments | Array NixString,
    },

  NixString
    | doc m%%"
      Nix string with a
      [context](https://shealevy.com/blog/2018/08/05/understanding-nixs-string-context/)
      tracking the dependencies that need to be built before the string can make
      sense.

      Anything expecting a `NixString` accepts a pure Nickel string as well. A
      `NixString` also accepts a Nix string fragment, which can be a Nickel
      derivation, a Nickel derivation, a Nix path (built from `lib.import_file`), pure
      Nickel strings, and maybe more in the future.

      A `NixString` accepts any sequence of Nix string fragment as well.

      A `NixString` is best constructed using the symbolic string syntax. See
      the Nickel example below.

      # Nix string context

      In Nix, when one writes:

      ```nix
      shellHook = ''
        echo "Development shell"
        ${pkgs.hello}/bin/hello
      ''
      ```

      Nix automatically deduces that this shell depends on the `hello`
      package. Nickel doesn't have string contexts, and given the way values
      are passed from and to Nix, this dependency information is just lost when
      using bare strings.

      Sometimes, you may not need the context: if `hello` is explicitly part
      of the inputs, you can use a plain string in a Nickel
      expression as well:

      ```nickel
      shellHook = m%"
        echo "Development shell"
        %{pkgs.hello.outputPath}/bin/hello
      "%
      ```

      # Example

      However, if you need the dependency to `hello` to be automatically
      deduced, you can use symbolic strings whenever a field has a `NixString`
      contract attached. The result will be elaborated as a richer structure,
      carrying the context, and will be reconstructed on the Nix side.

      To do so, juste use the multiline string syntax, but with an `s` prefix
      instead (**Warning**: the `s` prefix is as of now temporary, and subject
      to change in the future):

      ```nickel
      shellHook = nix-s%"
        echo "Development shell"
        %{pkgs.hello}/bin/hello
      "%
      ```

      Note that:
        - we've used the symbolic string syntax `nix-s%"`
        - instead of `hello.outputPath`, we've interpolated `hello` directly,
          which is a derivation, and not a string

      Within a `NixString`, you can interpolate a Nix String, or a Nix string
      fragment, that is a Nix derivation, a Nickel derivation, a Nix path (built from
      `lib.import_file`), pure Nickel strings, and maybe more in the future.
    "%%
    = fun label value =>
      # A contract must always be idempotent (be a no-op if applied a second
      # time), so we accept something that is already a NixString
      if predicate.is_nix_string value then
        value
        # We accept a single string fragment (a plain string, a derivation or a
        # Nix path). We normalize it by wrapping it as a one-element array
      else if predicate.is_string_fragment value then
        mk_nix_string [value]
      else
        let { fragments, .. } = std.contract.apply NixSymbolicString label value in
        mk_nix_string
          (
            std.array.flat_map
              (fun elt => elt.fragments)
              fragments
          ),

  join | NixString -> Array NixString -> NixString
    = fun sep strings =>
      mk_nix_string
        (
          std.array.map
            (fun elt => elt.fragments)
            strings
          |> std.array.intersperse sep.fragments
          |> std.array.flatten
        ),
}
