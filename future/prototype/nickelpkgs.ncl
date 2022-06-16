let PackageDef = {..} in
let Drv = Dyn in
let Unit = Dyn in
let Effect = fun x => x in
let derivation = fun _x = {} in

let lib = {
  fetch : Str -> Drv = fun s => {path = "dummy"},
} in

let Drv = {
  name | Str,
  # ...,
  derivation = %derivation% name ....,
  ..
} in

{
  name = "acpiligh",
  version = "..",
  src = ".",
}
|> Drv
{
  ..,
  derivation = %derivation% name version src ...
}

let InputBinder = fun res => {
  inputs = res,
  build_inputs = res,
  
} in

{
  # Rok: all packages should be in the same dir (flat structure) with names
  # matching their `name` field
  get_all_pkgs | Effect Unit -> Array PackageDef,
  # can we have different names? probably simpler to require names to be unique
  to_record | Array PackageDef -> {_ : PackageDef},
  combine | {_: PackageDef} -> {_ : Drv} = fun pkgs =>
    # Problem: record.map doesn't allow further overriding
    let res = pkgs | {_ : Drv} in


    # Fixpoint, but not sure
    record.fixpoint (fun self =>
      record.map (fun _k pkg => pkg & {inputs = self, build_inputs = self}) res)

    # But when do we apply "overlays"/override?
    # we can't really do it after the fact without additional machinery,
    # because inputs and build_inputs wouldn't be bound.

    (combine foo) & bar =~= (combine (foo & bar))

    # (r | [foo, .., ])
    # res & { fixed = record.map (fun _k x => x & {inputs = res, build_inputs = res} }
    res | (fun lbl x -> x & …)

    #record.fixpoint (fun self => { })
    #(foo | A | B) & (bar | C | D) ~ (foo | A | B | C | D) & (bar | C | D | A | B)
    #(foo & bar) | A | B | C | D
    #res & ...
    #something_else & ...
    
    n1 & n2 = n1 if n1 == n2 or _|_
    booleans
    strings
    arrays must both empty [] - arr1 if arr1 == arr2 or _|_
    
{ } | { foo | Num, bar | Num} ~ {foo | Num, bar | Num}

(acpilight | Drv) & { inputs.gcc = myGcc } ===> ((acpilight | Drv) & ({ inputs.gcc = myGcc } | Drv)).derivation

StaticAccess "derivation" (..)
& merge
op1 = (inner_op1) | Drv ~ (inner_op1 @ %assume% acpilight Drv label) | Drv
op2 = { inputs.gcc = myGcc}

let op2_app = contract.apply Drv label {inputs.gcc = myGcc}

(inner_op1 & op2_app) | Drv

(inner_op1 & op2_app)

inner_op1 = acpilight &ctr Drv 
{ name | Str = "acpiligh", .., derivation = %derivation% ... }

{ name | Str, .., derivation = ... } 

{ name | Str = "acipilight", ..., inputs = { ... }, derivation = (%derivation%
...) & (%derivation% ...) }

{
  foo,
  bar = foo + 1,
}

x & { foo = self.bar }

fun self => { bar = self.foo + 1 }
    let rec res = pkgs 
    |> record.map (fun _k x => x & {derivation = %derivation% x})
    |> record.fix (fun self => )
    # |> record.rec_map (fun _k x self => let super = self in x & {inputs = super@{1}, build_inputs = super}
  ,
    # Instead, contract approach: define this derivation = in the Builder
    # contract itself. Sounds like abusing contracts, but ok as long as
    # idempotent?
    # Then, all we need to do is to "tie the knot"
}

{
  foo = "this",
  bar = foo + 1,
  baz = self."%{foo}",
  inputs = self,
}

# nickelpkgs @ [let py = import "python.ncl" in py & { version = "3", name =
# "%{py.name}3"}] 
