# Fix for `nix develop`
: ''${outputs:=out}
runHook() {
  eval "$shellHook"
  unset runHook
}
