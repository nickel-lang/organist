{
  Store = { _ : Dyn },
  HashConsed = { value : Dyn, store : Store },
  hashCons2
    | Store -> Dyn -> HashConsed
    | doc m%"Hash-cons the given value, appending the shared elements to the given store"%
    = fun store value =>
      if std.is_record value then
        if std.record.has_field "value_hash" value then
          let _value = value in
          let _store = store in
          {
            value.value_hash = _value.value_hash,
            store = _store & { "%{value.value_hash}" = _value.value },
          }
        else
          let hashConsedFields =
            value
            |> std.record.map (fun k v => hashCons2 store v)
          in
          let sub_stores =
            hashConsedFields
            |> std.record.to_array
            |> std.array.map (fun { value = { store, .. }, .. } => store)
          in
          {
            value = std.record.map (fun k v => v.value) hashConsedFields,
            store = std.record.merge_all sub_stores,
          }
      else
        let store_ = store in
        let value_ = value in
        {
          value = value_,
          store = store_,
        },

  hashCons | Dyn -> HashConsed = hashCons2 {},

  add_hash : forall a. a -> { value_hash : String, value : a } = fun val =>
    let hash = std.hash 'Sha256 (std.serialize 'Json (val | Dyn)) in
    { value_hash = hash, value = val },

  tests = [
    hashCons 1 | std.contract.Equal { value = 1, store = {} },
    hashCons { x = 1, } | std.contract.Equal { value = { x = 1 }, store = {} },
    hashCons { x.value_hash = "foo", x.value.foo = 1, }
      | std.contract.Equal
        {
          value = { x.value_hash = "foo" },
          store = { foo = { foo = 1 } }
        },
    let _x = add_hash 123 in
    let _y = add_hash (122 + 1) in

    hashCons { x = _x, y = _y }
      | std.contract.Equal
        {
          value = { x.value_hash = _x.value_hash, y.value_hash = _x.value_hash },
          store = { "%{_x.value_hash}" = 123 }
        },
    let _x = { value = 123, value_hash = "foo" } in
    let _y = { value = 122 + 1, value_hash = "foo" } in

    hashCons { foo.x = _x, bar.y = _y }
      | std.contract.Equal
        {
          value = { foo.x.value_hash = "foo", bar.y.value_hash = "foo" },
          store = { foo = 123 }
        },
  ]
}
