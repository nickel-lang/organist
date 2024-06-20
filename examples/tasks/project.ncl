let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

organist.OrganistExpression
& {

  Schema,
  config | Schema
    = {
      shells = organist.shells.Bash,

      tasks = {
        enable = true,
        config = {
          tasks.test = {
            cmds = [
              "echo Foo",
              "echo ran_the_tests",
            ],
            deps = ["build"],
            desc = "Run the build",
          },
          tasks.build.cmds = ["echo ran_the_build"],

          includes.local = {
            taskfile = "Taskfiles.local.yaml",
            "optional" = true,
          },
        },
      },
    },
}
  | organist.modules.T
