import std/[parseopt, os, strformat, terminal, strutils]
import processors, helpers, results

let 
    usage = fmt"Invalid argument(s). Use ./{getAppFilename().extractFilename} --help for usage."
    banner = """

▓█████▄  ▒█████   ███▄ ▄███▓ ▄▄▄       ██▓ ███▄    █  ██▓ ███▄ ▄███▓
▒██▀ ██▌▒██▒  ██▒▓██▒▀█▀ ██▒▒████▄    ▓██▒ ██ ▀█   █ ▓██▒▓██▒▀█▀ ██▒
░██   █▌▒██░  ██▒▓██    ▓██░▒██  ▀█▄  ▒██▒▓██  ▀█ ██▒▒██▒▓██    ▓██░
░▓█▄   ▌▒██   ██░▒██    ▒██ ░██▄▄▄▄██ ░██░▓██▒  ▐▌██▒░██░▒██    ▒██ 
░▒████▓ ░ ████▓▒░▒██▒   ░██▒ ▓█   ▓██▒░██░▒██░   ▓██░░██░▒██▒   ░██▒
 ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒░   ░  ░ ▒▒   ▓▒█░░▓  ░ ▒░   ▒ ▒ ░▓  ░ ▒░   ░  ░
 ░ ▒  ▒   ░ ▒ ▒░ ░  ░      ░  ▒   ▒▒ ░ ▒ ░░ ░░   ░ ▒░ ▒ ░░  ░      ░
 ░ ░  ░ ░ ░ ░ ▒  ░      ░     ░   ▒    ▒ ░   ░   ░ ░  ▒ ░░      ░   
   ░        ░ ░         ░         ░  ░ ░           ░  ░         ░   
 ░  

"""

proc startChecking(domain: string, portStr: string, dnsStr: string, sbList: string, rps: int, filename: string) =
    var
        outfile: File
        writeable: bool = true
        ports: seq[int]
    try:
        ports = processPortString(portStr)
    except:
        echo "Invalid port specification. Example of proper form: 't10,5432,53,100-150'"
    echo banner
    styledEcho "Provided domain: ", styleUnderscore, domain

    let subdomains = processSubdomains(domain, dnsStr, sbList, rps)
    if len(subdomains) == 0:
        printMsg(error, fmt"[!] No subdomains found for the {domain}")
        return

    printPorts(portStr)
    var iptable = processVHostNames(subdomains)
    iptable = processOpenPorts(iptable, ports)

    if not filename.isEmptyOrWhitespace and not outfile.open(filename, fmWrite):
        printOutfile(false, filename)
        writeable = false

    if not filename.isEmptyOrWhitespace and writeable:
        printOutfile(true, filename)
        saveResults(subdomains, iptable, outfile)
        printUpdate(success, fmt"[+] Results saved to {filename}")
    else:
        printResults(subdomains, iptable)
    

proc main =
    var 
        ports = ""
        p = initOptParser(quoteShellCommand(commandLineParams()))
        domain: string
        dns = ""
        sbList = ""
        rps: int = 1000
        outfile = ""
    if paramCount() == 0:
        echo usage
        return
    while true:
        p.next()
        case p.kind
        of cmdEnd: break
        of cmdArgument:
            if domain != "":
                echo usage
                return
            domain = p.key
        of cmdLongOption:
            case p.key
            of "ports":
                ports = p.val
            of "dns":
                dns = p.val
            of "wordlist":
                sbList = p.val
            of "rps":
                try:
                    rps = p.val.parseInt
                except:
                    echo usage
                    return
            of "out":
                if p.val.endsWith(".json"):
                    outfile = p.val
                else:
                    echo fmt"Invalid output filename {p.val}. File must be a json file."
                    return
            of "help":
                printHelp()
                return
            else:
                echo usage
                return
        of cmdShortOption:
            case p.key:
            of "p":
                ports = p.val
            of "d":
                dns = p.val
            of "l":
                sbList = p.val
            of "r":
                try:
                    rps = p.val.parseInt
                except:
                    echo usage
                    return
            of "o":
                if p.val.endsWith(".json"):
                    outfile = p.val
                else:
                    echo fmt"Invalid output filename {p.val}. File must be a json file."
                    return
            of "h":
                printHelp()
                return
            else:
                echo usage
                return

    startChecking(domain, ports, dns, sbList, rps, outfile)

when isMainModule:
    main()