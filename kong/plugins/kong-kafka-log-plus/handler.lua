local BasePlugin = require "kong.plugins.base_plugin"
local inspect = require 'inspect'
local json = require "cjson"
local http = require "resty.http"
local client = require "resty.kafka.client"
local producer = require "resty.kafka.producer"

local KafkaLogPlus = BasePlugin:extend()

function KafkaLogPlus:new()
    KafkaLogPlus.super.new(self, "kafka-log-plus")
end


function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function KafkaLogPlus:log(config)
    KafkaLogPlus.super.log(self)
    local logPayload = {
      ip = kong.client.get_ip(),
      request = {
        method = kong.request.get_method(),
        path = kong.request.get_path_with_query(),
        headers = kong.request.get_headers(),
        body = "DUMMY", -- check
      },
      response = {
        status = kong.response.get_status(),
        headers = kong.response.get_headers(),
        body = "DUMMY",
      },
      consumer = kong.client.get_consumer(),
      route = kong.router.get_route(),
      service = kong.router.get_service(),
    }
       
    local ok, err = ngx.timer.at(0, timedKafkaLog, config, logPayload)
    if not ok then
      ngx.log(ngx.ERR, "timer no create:", err)
      return
    end  
end

function timedKafkaLog(premature, config, logPayLoad)

    if premature then
      return
    end

    local client_config = {
      ssl = true,
      refresh_interval = 300,
    }

    local broker_list = {
      {
        host = config.bootstrap_servers,
        port = config.port,
        sasl_config = {
          mechanism = config.sasl_mechanism, 
          user = config.sasl_user, 
          password = config.sasl_password,
        },
      },
    }

    local client_config = {
      ssl = config.ssl,
--    support this and other properties 
      refresh_interval = 300,
    }

    local cli = client:new(broker_list, client_config)
--  useful to force metadata refreshes
--  cli:refresh()
--  local brokers, partitions = cli:fetch_metadata("fx")

    local p = producer:new(broker_list, client_config)
    local offset, err = p:send(config.topic, logPayLoad.request.path, json.encode(logPayLoad))
    if not offset then
      kong.log("send err:", err)
      return
    end
    kong.log("send success, offset: ", tonumber(offset))

end


return KafkaLogPlus
