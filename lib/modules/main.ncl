# A library defining some kind of module system for Nickel
{
  T
    | doc m%"
      The type of a module.
    "%
    = {
      config | Schema = {},
      Schema
        | { .. }
        | not_exported
        = {},
      "$__organist_type" | force = "module",
    },

  submodules
    | { _ : T } -> T
    | doc m%"
      Joins all the given modules into a single one, prefixing all the keys of
      their options with the key of the corresponding module.

      ```nickel
      submodules {
          mod1 = { Schema.foo | Number, config.foo = 1 },
          mod2 = { Schema.foo | String, config.foo = "bar" },
        }

        => {
          Schema = { mod1.foo | Number, mod2.foo | String },
          config = { mod1.foo = 1, mod2.bar = "bar" }
        }
      ```
    "%
    = fun modules =>
      let configs = modules |> std.record.map (fun k v => v.config) in
      let schemas = modules |> std.record.map (fun k v => v.Schema) in
      {
        Schema = schemas,
        config | Schema = configs,
      } | T,
}
