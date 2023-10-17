let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  shells.build.hooks."regenerate_files" = m%"
    nix run .#regenerate-files
  "%,
  files."Makefile".content = m%"
    check:
    	git init
    	git add .
    	[[ -f README.md ]]
    	[[ -L this-is-a-symlink ]]
    	git check-ignore this-is-a-symlink
    	! git check-ignore README.md

  "%,
  shells = organist.shells.Bash,

  files."README.md".content = "This is a test of generating files with Organist",
  files."symlink".content = "blah",
  files."symlink".materialisation_method = 'Symlink,
  files."symlink".gitignore = true,
  files."symlink".target = "this-is-a-symlink",
}
  | organist.OrganistExpression
