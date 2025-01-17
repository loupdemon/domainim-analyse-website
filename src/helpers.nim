# Module helper
import std/[terminal, strutils, os, strformat]

type MsgType* = enum
    info, success, error, neutral


proc clearLast*() = 
    cursorUp 1
    eraseLine()

proc printMsg*(msgtype: MsgType, msg: string) =
    case msgtype
    of info:
        styledEcho fgYellow, msg
    of success:
        styledEcho fgGreen, msg
    of error:
        styledEcho fgRed, msg
    of neutral:
        styledEcho fgMagenta, msg

proc printUpdate* (msgtype: MsgType, msg: string) =
    clearLast()
    printMsg(msgtype, msg)

proc startProgress*() =
    var msg = "    Progress: " & "░".repeat(20)
    printMsg(info, msg)

proc updateProgress*(current, total: int, msg: string = "") =
    let 
        progress = (current * 100 / total).toInt
        prog = min(20, (progress/5).toInt)
        msg = "    Progress: " & "█".repeat(prog) & "░".repeat(20 - prog) & " $1%" % $progress & msg
    printUpdate(info, msg)

proc finishProgress*(msg: string) =
    clearLast()
    printUpdate(success, msg)

proc printPorts*(portStr: string) =
    if portStr == "all":
        printMsg(neutral, "[*] All ports are being scanned. This will take some times.")
    elif portStr == "none":
        printMsg(neutral, "[*] Port scanning is turened off.")
    elif portStr == "":
        printMsg(neutral, "[*] Port specification not provided. Port scanning will be skipped.")

proc printOutfile*(status: bool, filename: string) =
    if status:
        printMsg(info, fmt"[*] Writing results to {filename}.")
    else:
        printMsg(error, fmt"[!] Could not open {filename}. Results will be printed on console.")

proc printHelp*() =
    echo """
Usage:
    $1 <domain> [--ports=<ports> | -p:<ports>] [--wordlist=<filename> | l:<filename> [--rps=<int> | -r:<int>]] [--dns=<dns> | -d:<dns>] [--out=<filename> | -o:<filename>]
    $1 (-h | --help)

Options:
    -h, --help              Show this screen.
    -p, --ports             Ports to scan. [default: `none`]
                            Can be `all`, `none`, `t<n>`, single value, range value, combination
    -l, --wordlist          Wordlist for subdomain bruteforcing. Bruteforcing is skipped for invalid file.
    -d, --dns               IP and Port for DNS Resolver. Should be a valid IPv4 with an optional port [default: system default]
    -r, --rps               DNS queries to be made per second [default: 1024 req/s]
    -o, --out               JSON file where the output will be saved. Filename must end with `.json`

Examples:
    $1 domainim.com -p:t500 -l:wordlist.txt --dns:1.1.1.1#53 --out=results.json
    $1 sub.domainim.com --ports=all --dns:8.8.8.8 -t:1500 -o:results.json
    """ % getAppFilename().extractFilename