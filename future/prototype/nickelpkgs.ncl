let PackageDef = {..} in
let Drv = Dyn in
let Unit = Dyn in
let Effect = fun x => x in
let derivation = fun _x = {} in

let lib = {
  fetch : Str -> Drv = fun s => {path = "dummy"},
} in

{
  # Rok: all packages should be in the same dir (flat structure) with names
  # matching their `name` field
  get_all_pkgs | Effect Unit -> Array PackageDef,
  # can we have different names? probably simpler to require names to be unique
  to_record | Array PackageDef -> {_ : PackageDef},
  combine | {_: PackageDef} -> {_ : Drv} = fun pkgs => {
    # Problem: record.map doesn't allow further overriding
    pkgs
    |> record.map (fun _k x => x & {derivation = derivation x})
    |> record.map (fun _k x => x & {inputs = res, build_inputs = res} 
    # Instead, contract approach: define this derivation = in the Builder
    # contract itself. Sounds like abusing contracts, but ok as long as
    # idempotent?
    # Then, all we need to do is to "tie the knot"
  }
}

# nickelpkgs @ [let py = import "python.ncl" in py & { version = "3", name =
# "%{py.name}3"}] 


