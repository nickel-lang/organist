let builders = import "builders.ncl" in
let { drv_builder, Effect, Unit, Derivation, .. } = builders in
let PackageDef = builders.PackageDef in

# Can't implement this function in a satisfying way (i.e. that preserves
# recursive fields and all). Binding everything like a brute for now
let record =
  record
  & {
    project = fun sub_record r =>
      sub_record
      |> record.fields
      |> array.foldl (fun acc field => record.insert field r."%{field}" acc) {}
  }
in

{
  get_all_defs | Effect (Array PackageDef) = [ import "pkgs/hello-world.ncl"],
  defs_with_name | Array PackageDef -> { _ : PackageDef } = fun _pkgs =>
      {
        hello-world = import "pkgs/hello-world.ncl",
      },
  combine | { _ : PackageDef } -> { _ : Package } = fun pkgs =>
      # Bind the derivation field to the others. Using merging and not a contract
      # to avoid redoing the computation again and again
      let base = record.map (fun _k pkg => pkgs & drv_builder) in

      # bind the inputs and build_inputs
      let rec res =
        record.map
          (
            fun _k pkg =>
              pkg
              & {
                inputs = record.project pkg.inputs res,
                build_inputs = record.project pkg.build_inputs res,
              }
          )
          base
      in
      res,
  make | Effect { _ : Derivation } =
      get_all_defs
      |> defs_with_name
      |> combine,
}
