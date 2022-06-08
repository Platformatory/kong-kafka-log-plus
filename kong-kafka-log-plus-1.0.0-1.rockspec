package = "kong-kafka-log-plus"

version = "1.0.0-1"

supported_platforms = {"linux"}

source = {
  url = "git@github.com:Platformatory/kong-kafka-log-plus.git",
  tag = "1.0.0"
}

description = {
  summary = "Demonstrate API composition with Kong",
  license = "MIT",
  maintainer = "Pavan Keshavamurthy <pavan@platformatory.com>"
}

dependencies = {
  "lua-resty-kafka = 0.20-0"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.kong-kafka-log-plus.handler"] = "kong/plugins/kong-kafka-log-plus/handler.lua",
    ["kong.plugins.kong-kafka-log-plus.schema"] = "kong/plugins/kong-kafka-log-plus/schema.lua",
  }
}
