# Generating files with Organist

Organist can be used to manage configuration files on the repository through the `files` option.

For instance:

```nickel
let netlify_schema = import "nickel/netlify_schema.ncl" in
{
  files."netlify.toml".content = std.serialize 'Toml {
    build.command = "gatsby build",
    build.publish = "public/",
  } | netlify_schema
}
```

This has two main advantages:

1. It allows keeping everything under control (compared to a bunch of dotfiles everywhere that are easy to loose track of)
2. It is now possible to benefit from the flexibility and safety of Nickel in these files.
    In the example above, being able to specify a schema for the netlify config (taken from https://github.com/thufschmitt/nickel-schemastore/blob/master/out/Netlify%20config.ncl for instance) means that it's possible to get some early check and not have to wait for he CI to fail to detect a typo.
