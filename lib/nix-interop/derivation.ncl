let type_field = "$__organist_type" in

let nix_string = import "./nix-string.ncl" in

let predicate | doc "Various predicates used to define contracts"
  = {}
  in

let NixString = nix_string.NixString in

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
      attr_path
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
    = fun label value =>
      if std.is_string value then
        let hashPosition = (std.string.find "#" value).index in
        let value' =
          if hashPosition == -1 then
            { input = value, attr_path = [] }
          else
            {
              input = std.string.substring 0 hashPosition value,
              attr_path =
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

  NixPlaceholder
    | doc "A path to the given output resolved later in the Nix store"
    = {
      "%{type_field}" | force = "nixPlaceholder",
      output | String,
    },

  NixEnvironmentVariable
    | doc m%"
        Covers all types that are allowed in Nix derivation's environment variables:
        - strings
        - arrays of strings
        - records with string values
      "%
    = fun label value =>
      let Contract =
        if std.is_string value then
          NixString
        else if std.is_record value then
          if std.record.has_field type_field value
          || (
            std.record.has_field "tag" value
            && value.tag == 'SymbolicString
            && std.record.has_field "prefix" value
            && value.prefix == 'nix
          ) then
            NixString
          else
            { _ | NixString }
        else if std.is_array value then
          Array NixString
        else
          std.contract.blame_with_message "Must be string, array of strings or record with string values" label
      in
      std.contract.apply Contract label value,

  NixToFile
    | doc "A path to the given output resolved later in the Nix store"
    = {
      "%{type_field}" | force = "nixToFile",
      name | String,
      text | NixString,
    },
  CallNix
    | doc m%%"
      Call a raw Nix expression as a function.

      This will be interpreted as

      ```nix
      ${function} ${importFromNickel args}
      ```

      on the Nix side.

      ## Example

      ```nickel
      organist.nix.derivation.CallNix
      & {
        function = m%"
          { python }: python.withPackages (p: [p.pyyaml])
        "%,
        args = {
          python = organist.import_nix "nixpkgs#python3"
        },
      ```
    "%%
    = {
      "%{type_field}" | force = "callNix",
      function
        | doc m%"
          Plain Nix expression that will be passed verbatim to the Nix evaluator.
        "%
        | String,
      args
        | doc m%"
          Arguments that will be passed to the Nix expression.

          Can be an arbitrary serializable value.
        "%
        | Dyn,
    },
}
