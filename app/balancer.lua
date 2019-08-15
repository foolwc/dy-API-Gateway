local balancer = require "ngx.balancer"
local shd_config = ngx.shared.config

local set_current_peer = balancer.set_current_peer
-- 用于添加超时时间
local set_more_tries = balancer.set_more_tries
local set_timeouts = balancer.set_timeouts

local cjson = require "cjson.safe"
local base = require "resty.upstream.base"

local function get_upstream_by_host()
    local host = ngx.var.host
    return cjson.decode(shd_config:get(host))
end

local config = get_upstream_by_host()
--如果没有该域名的配置 返回502
if config == nil then
    ngx.exit(502)
    return
end
-- 默认拿负载均衡 round_robin 也可使用resty的consistent_hash /IP hash
-- 如果upstream不会经常改变，不需要new。在init的时候就创建好
local rr_up = base.upstream[config.domain]
local server = rr_up:find()
ok, err = set_current_peer(server)
if not ok then
    ngx.log(ngx.ERR, "set_current_peer failed, ", err)
    return
end
-- 可继续设置超时时间等参数