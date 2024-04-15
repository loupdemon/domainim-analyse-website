# Module crtsh

import std/[httpclient, strformat, net, json]
import regex
import utils

const 
    crtUrl = "https://crt.sh/"
    userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
    rowRegEx = re2"<TR>\s*<TD\s+style=\x22text-align:center\x22>[\s\S]*?</TR>"
    subdomainRegEx = re2"<TD>(.*?)</TD>"

let 
    headers = {
        "Accept": "text/html",
        "Accept-Language": "en-US,en;q=0.8",
        "Referer": "https://crt.sh/?a=1",
        "Content-Type": "application/x-www-form-urlencoded"
    }


    client: HttpClient = newHttpClient(userAgent, timeout=20000) # 20s timeout

client.headers = newHttpHeaders(headers)

proc makeRequest(url: string): Response =
    try:
        let paramUrl = fmt"{crtUrl}?Identity={url}&output=json"#&exclude=expired"
        result = client.get(paramUrl)
    except TimeoutError:
        raise newException(WebpageParseError, "crt.sh is not responding as expected")


proc getARecords(response: Response, target: string): seq[string] =
    let data = parseJson(response.body)
    # [
    #     {
    #         "issuer_ca_id": 247115,
    #         "issuer_name": "C=US, O=Amazon, CN=Amazon RSA 2048 M02",
    #         "common_name": "*.cloud.wazuh.com",
    #         "name_value": "*.cloud.wazuh.com",
    #         "id": 12479016921,
    #         "entry_timestamp": "2024-03-25T00:25:02.85",
    #         "not_before": "2024-03-25T00:00:00",
    #         "not_after": "2025-04-23T23:59:59",
    #         "serial_number": "0b1ffe9a1e1c6408e87fb1810b953559",
    #         "result_count": 2
    #     }
    # ]

    # traverse the json and get the name_value
    for entry in data:
        if entry.hasKey("name_value"):
            result.add(entry["name_value"].str)

    result = cleanAll(result, target) # crtsh sometimes provide unnecessary urls. cleaning is needed here
    if len(result) == 0:
        raise newException(WebpageParseError, "A records not found (engine: crt.sh)")

proc getCrtSubs*(url: string): seq[string] =
    return getARecords(makeRequest(url), url)