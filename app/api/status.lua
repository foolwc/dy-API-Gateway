local cjson = require "cjson.safe"
local base = require "resty.upstream.base"
local resty_roundrobin = require "resty.roundrobin"
local get_method = ngx.req.get_method
local get_body_data = ngx.req.get_body_data
local read_body = ngx.req.read_body
local uri = ngx.var.uri
local shd_config = ngx.shared.config

function print(msg)
    ngx.print("{\"code\": 0, \"msg\": \"",msg, "\"}")
    ngx.exit(ngx.HTTP_OK)
end
if uri == "/status" then
    ngx.header.content_type = "application/json"
    local method = get_method()
    -- 查看upstream
    if method == "GET" then
        if shd_config then
            local args = ngx.req.get_uri_args()
            local domain = args["domain"]
            if not domain then
                print("no arg 'domain'!")
            end
            local config = shd_config:get(domain)
            if not config then
                print("no config found!")
            end
            ngx.print(config)
        end
    elseif method == "POST" then
        -- 修改upstream
        read_body()
        local body = get_body_data()
        if not body then
            print("no post body!")
        else
            local config = cjson.decode(body)
            if not config.domain or not config.upstream then
                return ngx.exit(ngx.HTTP_OK)
            end
            if shd_config then
                local rr_up = resty_roundrobin:new(config.upstream)
                base.upstream[config.domain] = rr_up
                shd_config:set(config.domain, body)
            end
        end
    elseif method == "DELETE" then
        local args = ngx.req.get_uri_args()
        local domain = args["domain"]
        if not domain then
            print("no arg 'domain'")
            return
        end
        local config = shd_config:get(domain)
        shd_config:set(domain, nil)
        base.upstream[domain] = nil
        print("success")
    end
    return ngx.exit(ngx.HTTP_OK)
end