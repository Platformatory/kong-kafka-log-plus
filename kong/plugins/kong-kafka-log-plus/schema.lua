local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

return {
  name = plugin_name,
  fields = { 
    {
      config = {
        type = "record",
        fields = {
          { ssl = { type = "boolean", required = true, default = true }},
          { bootstrap_servers = { type = "string", required = true, default = "|", len_max = 120 }},
          { port = { type = "number", required = true, default = 9092, between = {0, 65534} }},
          { sasl_mechanism = { type = "string", required = true, default = "PLAIN", len_max = 10 }},
          { sasl_user = { type = "string", required = true, default = "|", len_max = 120 }},
          { sasl_password = { type = "string", required = true, default = "|", len_max = 120 }},
          { topic = { type = "string", required = true, default = "|", len_max = 120 }},              
        }
      }
    }
  }
}


