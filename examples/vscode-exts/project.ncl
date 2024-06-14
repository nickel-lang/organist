let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  shells = organist.shells.Bash,

  shells.dev = {
    packages.hello = organist.import_nix "nixpkgs#hello",  
  },
  
  vscode = {
    extensions = {
      "nickel" = {
        publisher = "Tweag",
        name = "vscode-nickel",
        version = "0.3.0",
        sha256 = "sha256-OntQfxh51B3x92IE4y62bw8csBGukqUzmUJIr/rGioU=",
      },
      "test" = {
        name = "vscode-markdownlint",
        publisher = "DavidAnson",
        version = "0.55.0",
        sha256 = "sha256-slfHfRPcuRu+649n6kAr2bv9H6J+DvYVN/ysq1QpPQM=",
      },
    },
  },
}
  | organist.OrganistExpression
