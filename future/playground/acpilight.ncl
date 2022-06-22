# express "configurable" or "partial" builders thanks to merging, by just
# accumulating stuff in e.g. prebuildHooks
# would need `| merge (@)`
let DerivationDef = {
  name,
  builder,
  args,
  env,
  system,
} in
let PackageDef = DerivationDef & {
  version,
  derivation = builtin.derivation ...
  phases = {},
} in

PkgConfigBuilder = { phases = { packageConfigStuff = { script =
doPkgConfigStuff, before = ["configurePhase"], }, } }



let MyBuilder = PackageDef & PkgConfigBuilder in
let BuilderInterface = { .. } in 

let data = { .. } & Builder1
let Builder = {
  #w ..BuilderInterface,
  derivation = null,
} in

{
  name = "acpilight",
  version = "1.2",

  inputs = {
    lib,
    coreutils,
  },

  build_inputs = {
    python3,
    python_packages_configargparse,
    pyenv = python3 & { with_packages = [ build_inputs.python_packages_configargparse ] },
  },

  src = {
     url = "https://gitlab.com/wavexx/acpilight.git",
     rev = "v%{version}",
     sha256 = "1r0r3nx6x6vkpal6vci0zaa1n9dfacypldf6k8fxg7919vzxdn1w",
     fetchType = `Git,
  },

  vars = {
    src_fetched = inputs.lib.fetch src,
  },

  unpack_phase = m%"
    cp %{vars.src_fetched} source
  "%m,

  post_configure = m%"
    substituteInPlace 90-backlight.rules --replace /bin %{inputs.coreutils}/bin
    substituteInPlace Makefile --replace udevadm true
  "%m,
 
  make_flags = [ "DESTDIR=$(out) prefix=" ],
 
  meta = let {platforms, licenses, maintainers, ..} = inputs.lib in {
    homepage = "https://gitlab.com/wavexx/acpilight",
    description = "ACPI backlight control",
    license = licenses.gpl3,
    maintainers = [ maintainers.msmakarov ],
    platforms = platforms.linux,
    mainProgram = "xbacklight",
  },
} & Builder


# { lib, stdenv, fetchgit, python3, coreutils }:
# 
# stdenv.mkDerivation rec {
#   pname = "acpilight";
#   version = "1.2";
# 
#   src = fetchgit {
#     url = "https://gitlab.com/wavexx/acpilight.git";
#     rev = "v${version}";
#     sha256 = "1r0r3nx6x6vkpal6vci0zaa1n9dfacypldf6k8fxg7919vzxdn1w";
#   };
# 
#   pyenv = python3.withPackages (pythonPackages: with pythonPackages; [
#     configargparse
#   ]);
# 
#   postConfigure = ''
#     substituteInPlace 90-backlight.rules --replace /bin ${coreutils}/bin
#     substituteInPlace Makefile --replace udevadm true
#   '';
# 
#   buildInputs = [ pyenv ];
# 
#   makeFlags = [ "DESTDIR=$(out) prefix=" ];
# 
#   meta = with lib; {
#     homepage = "https://gitlab.com/wavexx/acpilight";
#     description = "ACPI backlight control";
#     license = licenses.gpl3;
#     maintainers = with maintainers; [ smakarov ];
#     platforms = platforms.linux;
#     mainProgram = "xbacklight";
#   };
# }
