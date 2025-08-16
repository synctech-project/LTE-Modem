module("luci.controller.apnselector", package.seeall)
function index()
    entry({"admin", "network", "apnselector"}, cbi("apnselector"), _("APN Selector"), 90)
end