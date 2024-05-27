{
  escape_drv_name
    : String -> String
    | doc m%"
      Escape the given string to make it an allowed derivation name
    "%
    = fun str =>
      if std.string.is_match "^\\." str then
        "-" ++ str
      else
        str,
  set_defaults
  # The real type should be something like:
  # `(forall a. (String -> a) -> { _: a } -> { _: a })`
  # but that doesn't work atm because
  # 1. the first argument has some undefined fields, and that isn't expressible
  # 2. Polymorphic types and contracts don't work well together, so the type
  # variable is generally not instanciated to the right thing
    | (String -> Dyn) -> { .. } -> { _ : Dyn }
    | doc m%"
      `set_defaults def_builder r` sets `def_builder field` as the
      default value for each declared field `field` in `r`.

      ## Example

      ```nickel
      set_default (fun x => x) { foo, bar = "baz" }
        => { foo = "foo", bar = "baz" }
      ```

    "%
    = fun def r =>
      let defaults_records =
        r
        |> std.record.fields
        |> std.array.map (fun f => { "%{f}" | default = def f })
        |> std.record.merge_all
      in
      (r & defaults_records),

  WithDefaultValues
    | (String -> Dyn) -> Dyn
    | doc m%"
      `WithDefaultValues def_builder` is a contract that sets a default value
      for each declared field in a record.
    "%
    = fun def label value =>
      std.contract.apply { .. } label value
      |> set_defaults def,
}
