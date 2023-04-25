let type_field = "$__nixel_type" in

let predicate | doc "Various predicates used to define contracts"
  = {
    is_nix_path
        = fun x => std.is_record x &&
                   std.record.has_field type_field x &&
                   x."%{type_field}" == "nixPath"

    , is_nix_derivation
        = fun x => std.is_record x &&
                   std.record.has_field type_field x &&
                   x."%{type_field}" == "nixDerivation"

    , is_nix_string
      = fun value => std.is_record value &&
        std.record.has_field type_field value &&
        value."%{type_field}" == "nixString"

    , is_nickel_derivation = fun x =>
      std.is_record x &&
      std.record.has_field type_field x &&
      x."%{type_field}" == "nickelDerivation"

    , is_derivation = fun x =>
      is_nickel_derivation x ||
      is_nix_derivation x

    , is_string_fragment = fun x =>
      is_derivation x ||
      std.is_string x ||
      is_nix_path x
  } in

let mk_nix_string = fun fs => {
  "%{type_field}" = "nixString",
  fragments = fs,
} in

{
  # Nix may require name, version, etc. to have a certain format, but we're not sure.
  # TODO: refine those contracts
  Name = String,
  Version = String,
  # TODO: For now, we use String, but should we have enums tags for arch and os
  # instead?
  System = {arch | String, os | String},

  # TODO: more precise contract
  Derivation
    | doc m%"
        Contract representing either a Nix derivation (evaluated and imported
from the Nix world) or a derivation defined in Nickel.
      "%
    = Dyn,

  NixStringFragment
    | doc "A fragment of a Nix string (or a string with context). See `NixString`"
    = std.contract.from_predicate predicate.is_string_fragment,

  NixSymbolicString
    | doc m%"
      A symbolic string with the `` `nix `` prefix, as output by the Nickel
      parser. Used as a subcontract for `NixString`.
      "%
    = {
    prefix | [| `nix |],
    tag | [| `SymbolicString |],
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
      if predicate.is_nix_string value then value
      # We accept a single string fragment (a plain string, a derivation or a
      # Nix path). We normalize it by wrapping it as a one-element array
      else if predicate.is_string_fragment value then
        mk_nix_string [std.contract.apply NixStringFragment label value]
      else
        # TODO: it's for debugging, but we should remove the serializing at some
        # point.
        let label = std.contract.label.append_note (std.serialize `Json value) label in
        let {fragments, ..} = std.contract.apply NixSymbolicString label value in
        mk_nix_string fragments,

  NixDerivation | doc "A derivation coming from the Nix world"
    = {
    drvPath | String,
    outputName | String,
    "%{type_field}" | force = "nixDerivation",
  },

  NickelDerivation
    | doc m%"
        The basic, low-level interface for a symbolic derivation. A
        NickelDerivation is intenteded to be passed (exported) to the Nix side,
        which will take care of actually building it.
      "%
    = {
      name
        | doc "The name of the package."
        | Name,
      # in Nix, the version isn't actually strictly required by the interface of
      # derivation. But we probably want to impose it if we are to redefine the
      # API on the Nickel side.
      version
        | doc "The version of the package."
        | optional
        | Version,
      dependencies
        | doc "The dependencies of the package."
        | Array Derivation
        | default = [],
      system
        | doc "The system to build the package on. Defaults to the system used by importNcl."
        | System
        | optional,
      build_command
        | doc "The build command to execute."
        | {
          cmd | NixString,
          args | Array NixString
        },
      structured_env
        | doc m%%%"
            Set additional environment variables for the builder.

            `structured_env` is usually preferred over `env`, as the former is
            easier to merge and to override.


            # Format

            `structured_env` is a record whose fields are environment variables
            (`PATH`, `CLASSPATH`, `LD_PRELOAD`, etc.). The values are records
            themselves, which represents _named pieces_ that are joined together
            to form the final value of the variable.

            For example:

            ```nickel
            structured_env.PATH = {
              bash = nix-s%"%{inputs.bash}/bin"%,
              curl = nix-s%"%{inputs.curl}/bin"%,
            }
            ```

            This structured environment corresponds to a variable `PATH` with
            value `"%{inputs.bash}/bin:%{inputs.curl}/bin"`. Note that the order
            isn't preserved. The `bash` and `curl` names don't appear in the
            final value, but they are used for composability and overriding.

            ## Combining

            For example, imagine defining a shell in two different records, that
            are merged together: `builder1 & builder2`. `builder1` defines the
            structured environment given in the example above. Because
            `structured_env.PATH` is a recod, you can simply write in
            `builder2.ncl`:

            ```nickel
            structured_env.PATH.other-package = nix-s"%{inputs.other-package}/bin"%,
            ```

            The final result will be a path with all three subpaths separated by
            `:`.

            ## Overriding

            Because pieces are named (`bash`, `curl`, `other-package`), you can
            override them specifically using merging:

            ```nickel
            structured_env.PATH.bash | force = nix-s"%{inputs.special-bash}/bin"%,
            ```

            # Interaction with `env`

            Usually, you should only work with `structured_env`. The default
            value of `env` is built from `structured_env` automatically. If you
            override `env` directly, be aware that **`structured_env` will then
            be potentially completly ignored**.
          "%%%
        | {_: {_: NixString}}
        | default = {},
      env
        | doc m%"
          Set additional environment variables for the builder.

          By default, `env` should computed from `structured_env`, and
          `structured_env` should be used preferably. Ultimately, `env` is the actual
          source of truth being passed to Nix when building the derivation. See the
          documentation of `structured_env` for more details.
          "%
        | {_: NixString}
        # TODO: should we compute `env` from `structured_env` directly here? Or
        # let each builder do that by itself?
        #
        # Some parameters, like the separator, may vary. For now we have no
        # choice anyway, because of merging not being idempotent on complex
        # values, and because the `NickelDerivation` contract is applied several
        # times, we have to move the computing logic to builders.
        | default = {},
      "%{type_field}" | force = "nickelDerivation",
  },

  Params | doc "The parameters provided to the Nickel expression"
    = {
    system | System,
    inputs | {_: Derivation},
    nix | {..},
  },

  InputPath
    | doc m%"
        The path of a package in an input (usually nixpkgs). Can be either a
        single attribute, represented as a string, or an array of string,
        representing a composed path.

        If a single attribute is provided (a `String`), this contract normalizes the
        result by splitting it around dots to obtain an array:

        # Examples

        ```nickel
        "gcc" | InputPath
          => ["gcc"]
          => Pass the contract
        "nodePackages.markdownlint-cli" | InputPath
          => ["nodePackages", "markdownlint-cli"]
          => Pass the contract
        ["nodePackages", "markdownlint-cli"] | InputPath
          => Pass the contract
        ```
    "%
    = fun label value =>
    if std.is_string value then
      std.string.split "." value
    else
      value
      |> std.contract.apply (Array String) label,

  NickelInputSpec | doc "The specification of an input in a Nickel expression"
  = {
    input
      | String
      | default = "nixpkgs",
    path
      | InputPath
      | optional,
    # TODO: precise contract. We want to allow a path if input == "sources"
    ..
  },

  # TODO: have the actual contract for the result of an expression. It's pretty
  # open (could be an integer, a derivation, a record of derivations, etc.) but
  # it still obeys some rules: if the `type` field is set to a known predefined
  # value, then the record must have a certain shape.
  #
  # The contract must be: what the Nix side of the code can "parse" without
  # erroring out.
  NickelExpressionResult = Dyn,

  NickelExpression | doc "A Nickel expression"
    = {
    inputs_spec | {_ : NickelInputSpec},
    output | NickelExpressionResult,
    ..
  },

  NixPath = {
    "%{type_field}" | force = "nixPath",
    path | String,
  }
}
