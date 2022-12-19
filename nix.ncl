let predicate | doc "Various predicates used to define contracts"
  = { is_plain_string = builtin.is_str

    , is_nix_path
        = fun x => builtin.is_record x &&
                   record.has_field "type" x &&
                   x.type == `nixPath

    , is_nix_derivation
        = fun x => builtin.is_record x &&
                   record.has_field "type" x &&
                   x.type == "nixDerivation"

    , is_nickel_derivation = fun x =>
      builtin.is_record x &&
      record.has_field "type" x &&
      is_derivation_type x.type

    , is_derivation = fun x =>
      is_nickel_derivation x ||
      is_nix_derivation x

    , is_string_fragment = fun x =>
      is_derivation x ||
      is_plain_string x ||
      is_nix_path x

    , is_derivation_type = fun x =>
      x == `nickelPackage || x == `nickelShell
  } in

let contracts = {
  NixStringFragment | doc "A fragment of a Nix String"
    = contract.from_predicate predicate.is_string_fragment,

  NixString | doc "A Nix string (from which a context will be deduced)"
    =
    {
      type = "nixString",
      fragments | Array NixStringFragment,
    },

  NickelDerivationType | doc m%"
      A string value to represent the type of a nickel derivation.
    "%
    = contract.from_predicate predicate.is_derivation_type,

  HasDerivationType = {
    type | NickelDerivationType,
    ..
  },

  # NickelDerivation | doc "A package or a shell natively specified in Nickel."
  #   = fun label value =>
  #   let value_checked = contract.apply
  #     HasDerivationType
  #     (contract.tag "missing or incorrect derivation type (field `type`)" label)
  #     value in
  #   if value_checked.type == "nickelPackage" then
  #     contract.apply NickelPackage label value
  #   else
  #     contract.apply NickelShell label value,

  NickelDerivationBase = {
    name | doc "The package name."
         | Str,
    type | NickelDerivationType
         | doc m%"
            The type of derivation. Should not be set directly, but rather set by
            contract annotations.
          "%,
  },

  NickelPackage = NickelDerivationBase & {
    builder
      | doc "The executable building the derivation"
      | NixString,

    args
      | doc "The args passed to the builder"
      | Array NixString
      | default = [],

    system
      | doc "The system to build this derivation on"
      | Str,

    type = "nickelPackage",
    ..
  },

  NickelShell = NickelDerivationBase & {
    packages | Array NixDerivation
             | default = [],

    type = "nickelShell",
    ..
  },

  Shell | doc m%"
      Apply this contract to a Nickel expression to indicate that it should be
      considered as defining a shell. Applying this contract is similar to
      calling `mkShell` in the Nix world.
    "%
    = {type = "nickelShell", ..},

  NixDerivation | doc "A derivation coming from the Nix world"
    = {
    drvPath | Str,
    outputName | Str,
    type = "nixDerivation",
  },

  Params | doc "The parameters provided to the Nickel expression"
    = {
    system | Str,
    inputs | {_: Dyn},
    nix | {..},
  },

  NickelInput | doc "The specification of an input in a Nickel expression"
  = {
    input | Str
          | default = "nixpkgs",
    # TODO: precise contract. We want to allow a path if input == "sources"
    ..
  },

  # TODO: have the actual contract for the result of an expression. It's pretty
  # open (could be an integer, a derivation, a record of derivations, etc.) but
  # still obey some rules: if the `type` field is set to a known predefined
  # value, then the record must have a certain shape.
  # The contract must be: what the Nix side of the code can "parse" without
  # erroring out.
  NickelExpressionResult = Dyn,
  NickelExpression | doc "A Nickel expression"
    = {
    inputs_spec | {_ : NickelInput},
    output | Params -> NickelExpressionResult,
  },

  NixPath = {
    type | force = `nixPath,
    path | Str,
  }
} in

let constructors
  = {
  import_file
    | Str -> contracts.NixPath
    = fun filepath => {path = filepath},
  nix_string_hack
    | Array contracts.NixStringFragment -> contracts.NixString
    | doc m%%"
        Nickel doesn't have a mechanism like Nix
        [string contexts](https://shealevy.com/blog/2018/08/05/understanding-nixs-string-context/) yet.

        If you rely on string contexts to automatically deduce
        inputs for you, you must use this function to build a Nix string as
        a list of fragments. A fragment is either a plain Nickel string or a
        derivation coming from Nix. Those fragments will be eventually
        contatenated on the Nix side.

        # Example

        In Nix, when one writes:

        ```nix
        shellHook = ''
          echo "Development shell"
          ${pkgs.hello}/bin/hello
        ''
        ```

        Nix automatically deduces that this shell depends on the `hello`
        package. Nickel doesn't have string contexts, and given the way values
        are passed from and to Nix, this dependency information is just lost.
        Sometimes, you may not need the context: if `hello` is explicitly part
        of the inputs, you can use a plain string in a Nickel
        expression as well:

        ```nickel
        shellHook = m%"
          echo "Development shell"
          %{pkgs.hello}/bin/hello
        "%m
        ```

        However, if you need the dependency to `hello` to be automatically
        deduced, you can use this function `nix_string_hack` to preserve the
        dependency information. To do so, cut the string in question into
        fragments to get rid of the string interpolation. One
        fragment needs to be `pkgs.hello`. In this case, the remaining fragments
        can just be the whole strings before and after `%{pkgs.hello}`, because
        they are static strings without interpolations of other Nix derivations:

        ```nickel
        shellHook = nickel_string_hack [
          m%"echo "Development shell""%m,
          pkgs.hello,
          "/bin/hello"
        ]
        ```

        In the future, we will hopefully have a native mechanism similar or subsuming
        string contexts in Nickel.
    "%%
  = fun f =>
    { type = "nixString", fragments = f },
} in

{
  Shell = contracts.Shell,
  Derivation = contracts.NickelDerivation,
  NickelExpression = contracts.NickelExpression,
  NixStringFragment = contracts.NixStringFragment,
  ImportedFile = contracts.ImportedFile,
  lib = constructors,
  builders = import "builders.ncl",
}
# | doc m%"
#     Nickel library for Nickel-Nix interoperability. Provide contracts used to
#     serialize Nix inputs to Nickel, to define a Nickel expression, and helpers
#     to build strings which preserves Nix string contexts.
#   "%
