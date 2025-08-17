m = Map("apnselector", translate("APN Selector"))

s = m:section(NamedSection, "apn", "settings", "")

apn_list = {
    ["MTNIRANCELL"] = "Irancell",
    ["MCINET"] = "Hamrah Aval",
    ["RighTel"] = "RighTel"
}

apn = s:option(ListValue, "apn_value", translate("Choose your operator"))
for v, n in pairs(apn_list) do
    apn:value(v, n)
end

apn.default = "MTNIRANCELL"

s:option(DummyValue, "_hint", '', "Please reset your modem after making changes.<br><br>")

function m.on_commit(self)
    local uci = require "luci.model.uci".cursor()
    local apn_value = uci:get("apnselector", "apn", "apn_value")
    if apn_value then
        -- debug log, optional:
        os.execute('echo [Luci/CBI] Commit: APN=' .. apn_value .. ' >> /tmp/apn_debug.log')
        os.execute('/usr/bin/update_apn.sh "'..apn_value..'"')
    end
end

return m