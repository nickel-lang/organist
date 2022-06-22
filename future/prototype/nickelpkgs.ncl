let PackageDef = {
  inputs | default = [],
  build_inputs | default = [],
  ..
} in
let DrvDef = {
  name | Str,
  version | Str,
  system | {..},
  ..
} in
let Drv = {..} in
let Package = PackageDef & {
  derivation | Drv,
} in
let Unit = fun label => function.id in
let Effect = fun x => x in
let _mk_derivation | Str -> Str -> {..} -> Drv = fun name_ version_ system_ => {path = "dummy"} in

# Can't implement this function in a satisfying way (i.e. that preserves
# recursive fields and all). Binding everything like a brute for now
let record = record & {
  project = fun sub_record r =>
    sub_record
    |> record.fields
    |> array.foldl (fun acc field => record.insert field r."%{field}" acc) {}
} in

let drv_builder = {
  name | Str,
  # ...,
  derivation | Drv = _mk_derivation name ....,
  ..
} in

{
  get_all_defs | Effect Unit -> Array PackageDef,
  defs_with_name | Array PackageDef -> {_ : PackageDef},
  combine | {_: PackageDef} -> {_ : Package} = fun pkgs =>
    # Bind the derivation field to the others
    let base = record.map (fun _k pkg => pkgs & drv_builder) in
    # bind the inputs and build_inputs
    let rec res = record.map (fun _k pkg => pkg & {
        inputs = record.project pkg.inputs res,
        build_inputs = record.project pkg.build_inputs res,
      }) base in
    res,
  make | Effect Unit -> {_ : Drv}
}
