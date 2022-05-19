let {Package, ..} = import "nickelpkgs.ncl" in

# inputs | {_: Package}

(%assume% Bar {
  foo,
  bar = 1,
} | Bar)

& { }
$dyn_record Package {foo, bar = 1}
record.map

(record1 | RecContract1) & record2
~= (record1 | RecContract1) &! (check RecContract record2)

{
  foo | Contract
      | default = bar,
}

({ x = 1 } | { x | Dyn }) & {}


fields RecContract ==/(<= if open) fields record2
builtin.is_record record2

(    ) & record2
{foo | Package, bar | Package = 1} | & { }

let default_pkg = { name = "", version = "", drv = null, inputs = {}} in

({
  name = "hello",
  version = "1.0.0",

  some_flag = [inputs.gcc],
  drv = null,

  inputs = {
    gcc | Package,
  },

  build_inputs = {
    foo_pkg | Dyn,
  },
} | Package) & {
  inputs.gcc = default_pkg,
  build_inputs.foo_pkg = default_pkg,
}

# (foo | A) & (bar | B) => ((foo | A) | B) & ((bar | B) | A)
#                       => (foo & bar) | A | B
# ((foo | A) &! (bar | B)) | (A \ fields foo) | (B \ fields bar)

foo = { }
A = { .. }
bar | { x = 1 }
B = { x | Dyn }

nickel> ({} | {..}) & ({ x = 1 } | { x | Dyn })
{ x = <contract,value=1>}

nickel> (({} | {..}) & ({ x = 1 } | { x | Dyn })).x
1
