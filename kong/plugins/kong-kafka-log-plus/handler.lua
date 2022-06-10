local BasePlugin = require "kong.plugins.base_plugin"
local inspect = require 'inspect'
local json = require "cjson"
local http = require "resty.http"
local client = require "resty.kafka.client"
local producer = require "resty.kafka.producer"
local socket = require("socket")
local uuid = require("uuid")
local timestamp = require("kong.tools.timestamp")

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

function KafkaLogPlus:access(config)
    KafkaLogPlus.super.access(self)
    uuid.randomseed(socket.gettime()*10000)
    kong.ctx.plugin.request_access_time = timestamp.get_utc()
    kong.ctx.plugin.request_body =  kong.request.get_body()
    kong.ctx.plugin.correlation_id = uuid()
end    


function KafkaLogPlus:body_filter(config)
    KafkaLogPlus.super.body_filter(self)
    kong.ctx.plugin.response_body = kong.response.get_raw_body()
end    


function KafkaLogPlus:log(config)
    KafkaLogPlus.super.log(self)
    local logPayload = {
      correlation_id = kong.ctx.plugin.correlation_id,
      request_access_time = kong.ctx.plugin.request_access_time,
      ip = kong.client.get_ip(),
      request = {
        method = kong.request.get_method(),
        path = kong.request.get_path_with_query(),
        headers = kong.request.get_headers(),
        body = kong.ctx.plugin.request_body,
      },
      response = {
        status = kong.response.get_status(),
        headers = kong.response.get_headers(),
        body = kong.ctx.plugin.response_body,
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
