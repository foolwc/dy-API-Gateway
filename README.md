# dy-API-Gateway
+ 基于OpenResty, 实现动态Upstream列表功能(不需要reload即可修改upstream IP地址)
+ 采用rrb的负载均衡方式，可自己实现IP or Consistence Hash
+ 代码简单，功能简易。容易理解  

## windows环境搭建  
1、下载[OpenResty](http://openresty.org/en/download.html)并按照官网步骤安装。  
2、克隆本项目后将**lib/resty**文件夹拷贝至**your\path\to\openresty-1.13.6.2-win64\lualib\resty**。  
3、进入openresty目录，cmd运行
```
nginx.exe -p /your/path/to/API-Gateway/ -c /your/path/to/API-Gateway/conf/nginx.conf
```   
  或者运行shell命令(作者是采用MINGW运行的...放在了E盘)：
 ```
./nginx.exe -p /e/API-Gateway/ -c /e/API-Gateway/conf/nginx.conf
 ```

## 默认配置
查看 app/api/init_config.lua：
```
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

```
## 查询Upstream
GET /status?domain={your.domain}
```
curl 'http://127.0.0.1:8080/status?domain=aaa.com'
```
响应结果：
```
{
  "upstream": {
    "127.0.0.1:8000": 1
  },
  "domain": "aaa.com",
  "id": 1
}
```
## 修改Upstream
POST请求网关/status接口即可。
POST请求体JSON格式：
```
{
  "upstream": {
    "127.0.0.1:8000": 1, --域名对应上游地址，后面跟权重
    "127.0.0.1:8001": 1 
  },
  "domain": "ccc.com", --域名
  "id": 1 -- 暂时未使用，持久化待开发
}
```
```
curl -XPOST -H "Content-Type:application/json" -d '{"upstream":{"127.0.0.1:8000":1},"domain":"ccc.com","id":1}' 'http://192.168.172.1:8080/status'
```
