import helpers
import std/[terminal, strutils, tables, json]
import modules/[iputils, subfinder]

proc printResults*(subdomains: seq[Subdomain], ips: Table[string, IPv4]) =
    printMsg(neutral, "[*] Printing results\n")
    for s in subdomains:
        styledEcho styleUnderscore, s.url
        if not s.isAlive:
            styledEcho "  ↳ ", fgRed, styleBright, styleUnderscore, "Public IPv4 not found\n"
            continue
        for ip in s.ipv4:
            styledEcho "  ↳ ", fgGreen, styleUnderscore, ip
            let
                vhostnames = ips[ip].vhostNames.join(", ")
                rdns = ips[ip].rdns
                ports = ips[ip].openPorts            
            if rdns == "":
                discard
            else:
                styledEcho "    ↳ ", styleBright, "Reverse DNS: ", resetStyle, rdns
            if vhostnames == "":
                discard
            else:
                styledEcho "    ↳ ", styleBright, "Virtual Hostnames: ", resetStyle, vhostnames
            if len(ports) == 0:
                discard
            else:
                styledEcho "    ↳ ", styleBright, "Open Ports: ", resetStyle, fgGreen, ports.join(", ")
            echo " "

proc generateJsonResults(subdomains: seq[Subdomain], ips: Table[string, IPv4]): string =
    var res = newJArray()

    for s in subdomains:
        var sub: JsonNode = newJObject()
        sub["subdomain"] = %s.url
        sub["data"] = newJArray()
        if not s.isAlive:
            res.add(sub)
            continue
        for ip in s.ipv4:
            var subData = newJObject()
            subData["ipv4"] = %ip
            subData["vhosts"] = %ips[ip].vhostnames
            subData["reverse_dns"] = %ips[ip].rdns
            subData["ports"] = %ips[ip].openPorts
            sub["data"].add(subData)
        res.add(sub)
    return res.pretty

proc saveResults*(subdomains: seq[Subdomain], ips: Table[string, IPv4], outfile: File) =
    let outstr = generateJsonResults(subdomains, ips)
    outfile.write(outstr)