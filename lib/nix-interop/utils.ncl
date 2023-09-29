{
  escape_drv_name
    : String -> String
    | doc m%"
      Escape the given string to make it an allowed derivation name
    "%
    = fun str =>
      if std.string.is_match "^\\." str then
        "-" ++ str
      else
        str
}
