local shd_config = ngx.shared.config
local worker_id = ngx.worker.id

local cjson = require "cjson.safe"
local resty_roundrobin = require "resty.roundrobin"
local base = require "resty.upstream.base"
local json_encode = cjson.encode

-- 写死的upstream配置，用于demo。 可自己在fetch_config中实现拉取远程配置，例如连接consul, etcd或者http访问
-- service_A域名为aaa.com,它的上游地址为127.0.0.1:8000、127.0.0.1:8001
-- service_B域名为bbb.com,它的上游地址为127.0.0.1:8000
local remote_config = {
    {
        id = 1,
        service_name = "service_a",
        domain = "aaa.com",
        upstream = {
            ["127.0.0.1:8001"] = 1, --后面数字代表权重
            ["127.0.0.1:8000"] = 5
        }
    },
    {
        id = 2,
        domain = "bbb.com",
        service_name = "service_b",
        upstream = {
            ["127.0.0.1:8000"] = 1
        }
    }
}

--初始化，可以启一个worker线程定时拉取upstreams配置，代码已注释掉
function init_config()
    if worker_id() ~= 0 then
        return
    end
    fetch_config()
    --local ok, err = ngx.timer.every(5, fetch_config)
    --if not ok then
    --    log(WARN, "failed to init config: ", err)
    --    return
    --end
end

function fetch_config()
    if shd_config then
        for _, config in ipairs(remote_config) do
            shd_config:set(config.domain, json_encode(config))
            local rr_up = resty_roundrobin:new(config.upstream)
            base.upstream[config.domain] = rr_up
        end
    end
end

init_config()