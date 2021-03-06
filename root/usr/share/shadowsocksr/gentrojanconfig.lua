local ucursor = require "luci.model.uci".cursor()
local json = require "luci.jsonc"
local server_section = arg[1]
local proto = arg[2]
local threads = tonumber(arg[3])
local local_addr = arg[4]
local local_port = arg[5]
local usr_dns = arg[6]
local usr_port = arg[7]

local server = ucursor:get_all("shadowsocksr", server_section)
local cipher = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA"
local cipher13 = "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384"

local trojan = {
    -- error = "/tmp/ssrplus.log",
    log_level = 3,
    run_type = proto,
    local_addr = local_addr,
    local_port = tonumber(local_port),
    remote_addr = server.server,
    remote_port = tonumber(server.server_port),
    target_addr = (proto == "forward") and usr_dns or nil,
    target_port = (proto == "forward") and tonumber(usr_port) or nil,
    udp_timeout = 60,
    -- 传入连接
    password = {server.password},
    -- 传出连接
    ssl = {
        verify = (server.insecure == nil or server.insecure == "0") and true or false,
        verify_hostname = (server.insecure == nil or server.insecure == "0") and true or false,
        cert = "",
        cipher =  server.fingerprint == nil and cipher or (server.fingerprint == "disable" and cipher13 .. ":" .. cipher or ""),
        cipher_tls13 = server.fingerprint == nil and cipher13 or nil,
        sni = server.tls_host or (server.ws_host or server.server),
        alpn = (server.trojan_transport == "ws") and {} or {"h2", "http/1.1"},
        fingerprint = (server.fingerprint ~= nil and server.fingerprint ~= "disable" ) and server.fingerprint or "",
        curve = "",
        reuse_session = true,
        session_ticket = server.session_ticket == "1",
        },
    mux = (server.mux == "1") and {
        enabled = true,
        concurrency = tonumber(server.concurrency),
        idle_timeout = 60,
        } or nil,
    tranport_plugin = server.stream_security == "none" and server.trojan_transport == "original" and {
        enabled = server.plugin_type ~= nil,
        type = server.plugin_type or "plaintext",
        command = server.plugin_type ~= "plaintext" and server.plugin_cmd or nil,
        plugin_option = server.plugin_type ~= "plaintext" and server.plugin_option or nil,
        arg = server.plugin_type ~= "plaintext" and server.plugin_arg or nil,
        env = {}
        } or nil,
    websocket = server.trojan_transport and server.trojan_transport:find("ws") and {
        enabled = true,
        path = server.ws_path or "/",
        host = server.ws_host or (server.tls_host or server.server)
        } or nil,
    shadowsocks = (server.ss_aead == "1") and {
        enabled = true,
        method = server.ss_aead_method or "aead_aes_128_gcm",
        password = server.ss_aead_pwd or ""
        } or nil,
        tcp = {
            no_delay = true,
            keep_alive = true,
            reuse_port = (threads > 1) and true or false,
            fast_open = (server.fast_open == "1") and true or false,
            fast_open_qlen = 20
        }
}
if server.stream_security ~= nil and server.trojan_transport == "original" then trojan.ssl = nil end
print(json.stringify(trojan, 1))
