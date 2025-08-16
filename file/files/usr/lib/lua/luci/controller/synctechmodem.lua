module("luci.controller.synctechmodem", package.seeall)

function index()
    entry({"admin", "status", "synctechmodem"}, call("action_status"), _("Synctech LTE Modem"), 90)
    entry({"admin", "status", "synctechmodem", "json"}, call("json_status"), nil).leaf=true
end

function action_status()
    local output = luci.sys.exec("/usr/share/synctechmodem/get_modem_info.sh") or ""
    local modeminfo = {}
    for line in output:gmatch("[^\r\n]+") do
        local k, v = line:match("^([^:]+):%s*(.*)$")
        if k and v then
            local key = k:gsub("^%l", string.upper)
            modeminfo[key] = v
        end
    end

    local csq = tonumber(modeminfo.Signal) or 0
    modeminfo.SignalBar = math.floor((csq / 31) * 5 + 0.5)

    luci.template.render("synctechmodem/status", {modeminfo = modeminfo})
end

-- Çíä ÊÇÈÚ ÑÇ ÇÖÇÝå ˜ä!
function json_status()
    local output = luci.sys.exec("/usr/share/synctechmodem/get_modem_info.sh") or ""
    local modeminfo = {}
    for line in output:gmatch("[^\r\n]+") do
        local k, v = line:match("^([^:]+):%s*(.*)$")
        if k and v then
            local key = k:gsub("^%l", string.upper)
            modeminfo[key] = v
        end
    end

    local csq = tonumber(modeminfo.Signal) or 0
    modeminfo["SignalBar"] = math.floor((csq / 31) * 5 + 0.5)

    luci.http.prepare_content("application/json")
    luci.http.write_json(modeminfo)
end
