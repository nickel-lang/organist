# Migrating from 0.1

Since 0.2, Organist uses a [module system] for the configuration.
This means that the `project.ncl` is now a module, with a slightly different interface.

## Migrating `project.ncl`

In the vast majority of cases, the migration consists of three things:

1. Declare a new `Schema` field;
2. Move all the options under a `config` field;
3. Replace the schema by `organist.module.T`, and instead merge the config with the previous schema.

As an example is probably more eloquent, this means rewriting:

```nickel
{
  shells = …,
  foo = bar,
  …
} | (organist.OrganistExpression & organist.something.Schema & organist.somethingElse.Schema)
```

into:

```nickel
organist.OrganistExpression
& organist.something
& organist.somethingElse
& {
  Schema,
  config | Schema = {
    shells = …,
    foo = bar,
    …
  },
} | organist.module.T
```

## Migrating custom modules

Migrating custom modules is similar, except that
1. The module system now separates the _declaration_ of options from their _definition_ (respectively the `Schema` and `config` fields)
2. Modules must now merge with all of their dependencies (the modules whose option they use).

For instance, an hypothetical module like the one below:

```nickel
{
  readme.content
    | doc "Content of the README file"
    | String,
  files."foo".content = readme.content,
}
```

should be rewritten to

```nickel
(import organist.files) # Because we set the `files` option which is defined there
& {
  # New options defined by the module
  Schema = {
    readme.content
      | doc "Content of the README file"
      | String,
  },
  # Implementation of the module, setting options from other modules
  config | Schema = {
    readme,
    files."foo".content = readme.content,
  },
}
```
