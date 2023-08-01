let type_field = "$__nixel_type" in

let predicate | doc "Various predicates used to define contracts"
  = {
    is_nix_path = fun x =>
      std.is_record x
      && std.record.has_field type_field x
      && x."%{type_field}" == "nixPath",
    is_nix_input = fun x =>
      std.is_record x
      && std.record.has_field type_field x
      && x."%{type_field}" == "nixInput",
    is_nix_string = fun value =>
      std.is_record value
      && std.record.has_field type_field value
      && value."%{type_field}" == "nixString",
    is_nickel_derivation = fun x =>
      std.is_record x
      && std.record.has_field type_field x
      && x."%{type_field}" == "nickelDerivation",
    is_derivation = fun x =>
      is_nickel_derivation x
      || is_nix_input x,
    is_string_fragment = fun x =>
      is_derivation x
      || std.is_string x
      || is_nix_path x
  }
  in

let mk_nix_string = fun fs =>
  {
    "%{type_field}" = "nixString",
    fragments = fs,
  }
in

{
  # Nix may require name, version, etc. to have a certain format, but we're not sure.
  # TODO: refine those contracts
  Name = String,
  Version = String,
  # TODO: For now, we use String, but should we have enums tags for arch and os
  # instead?
  System = { arch | String, os | String },

  NullOr
    | doc "Make a contract nullable"
    = fun contract label value =>
    if value == null then value else std.contract.apply contract label value,

  # TODO: more precise contract
  Derivation
    | doc m%"
        Contract representing either a Nix derivation (evaluated and imported
from the Nix world) or a derivation defined in Nickel.
      "%
    = Dyn,

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
        mk_nix_string [std.contract.apply NixStringFragment label value]
      else
        # TODO: it's for debugging, but we should remove the serializing at some
        # point.
        let label = std.contract.label.append_note (std.serialize 'Json value) label in
        let { fragments, .. } = std.contract.apply NixSymbolicString label value in
        mk_nix_string fragments,

  NixDerivation
    | doc m%"
        The basic, low-level interface for a symbolic derivation. A
        NixDerivations is intended to be passed (exported) to the Nix side,
        which will take care of actually building it.

        The fields directly map to the corresponding
        [builtins.derivation](https://nixos.org/manual/nix/stable/language/derivations.html)
        attribute on the Nix side
      "%
    = {
      name | Name,
      builder | NixString,
      args | Array NixString,
      system | NullOr String,
      outputs | Array String | optional,
      "__structuredAttrs" | Bool | default = true,
      ..
    },

  NickelDerivation
    | doc m%"
    The representation of a symbolic derivation on the Nickel side.
    This record is extensible as the different layers involved might add new attributes to this derivation.
    The important part eventually is the `nix_drv` field which is computed from the rest and sent to Nix
"%
    = {
      "%{type_field}" | force = "nickelDerivation",
      nix_drv
        | doc "The raw derivation sent to Nix"
        | NixDerivation
        =
          let _name = name in
          let _system = system in
          let _version = version in
          {
            name = _name,
            system = _system,
            version = _version,
            builder = build_command.cmd,
            args = build_command.args
          },
      name
        | doc "The name of the package."
        | Name,
      version
        | doc "The version of the package."
        | optional
        | Version,
      system
        | doc "The system to build the package on. Defaults to the system used by importNcl."
        | NullOr System
        | default
        = null,
      build_command
        | doc "The build command to execute."
        | {
          cmd | NixString,
          args | Array NixString
        },
      ..
    },

  Params | doc "The parameters provided to the Nickel expression"
    = {
      system | System,
    },

  InputPath
    | doc " The path of a package in an input (usually nixpkgs)"
    = Array String,

  NixInput
    | doc m%"
      The specification of a Nix input in a Nickel expression.
    "%
    = {
        "%{type_field}" | force = "nixInput",
        input
          | doc "The flake input from which we'll resolve this input"
          | String
          | default
          = "nixpkgs",
        attrPath
          | doc m%"
            The path to look for in the given flake input.

            This follows the same search rules as the `nix build` cli, namely
            that the library will consider the first valid values within:
            - InputPath
            - "packages".system.InputPath
            - "legacyPackages".system.InputPath
            "%
          | InputPath
          | optional,
      },

    NixInputSugar
      | doc m%"
        Syntactic sugar for defining a `NixInput` to allow writing inputs
        directly as strings of the form `{inputName}#{path}`
      "%
      =
      fun label value =>
        if std.is_string value then
          let hashPosition = (std.string.find "#" value).index in
          let value' =
            if hashPosition == -1 then
              { input = value, attrPath = [] }
            else
              {
                input = std.string.substring 0 hashPosition value,
                attrPath =
                  std.string.split
                    "."
                    (
                      std.string.substring
                        (hashPosition + 1)
                        (std.string.length value)
                        value
                    ),
              }
          in
          value' |> std.contract.apply NixInput label
        else
          std.contract.apply NixInput label value,

  NixPath
    | doc "A path to be imported in the Nix store"
    = {
    "%{type_field}" | force = "nixPath",
    path | String,
  },

  # TODO: have the actual contract for the result of an expression. It's pretty
  # open (could be an integer, a derivation, a record of derivations, etc.) but
  # it still obeys some rules: if the `type` field is set to a known predefined
  # value, then the record must have a certain shape.
  #
  # The contract must be: what the Nix side of the code can "parse" without
  # erroring out.
  NixelExpression = Dyn,

}
