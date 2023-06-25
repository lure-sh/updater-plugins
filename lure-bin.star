def get_checksums(download_url):
    checksum_url = download_url + "/checksums.txt"
    res = http.get(checksum_url)
    lines = res.body.string().split("\n")
    res.body.close()
    checksum_list = [item.split("  ") for item in lines]
    checksums = [(checksum[1], checksum[0]) for checksum in checksum_list if len(checksum) == 2]
    return checksums

def update_pkg(req):    
    if req.headers["X-Gitea-Event"][0] != "release":
        return {"code": 400, "body": "This plugin only accepts release events"}
    
    body = req.body.read_json()
    req.body.close()
    
    if body["action"] != "published":
        return {"code": 400, "body": "This plugin only accepts release publish events"}
    
    name = body["release"]["name"]    
    url = body["repository"]["html_url"]
    download_url = url + "/releases/download/" + name
    checksums = get_checksums(download_url)
    
    items = {}
    for filename, checksum in checksums:
        if ".tar.gz" not in filename:
            continue
        
        if "aarch64" in filename:
            items["arm64"] = (filename, checksum)
        elif "armv6" in filename:
            items["arm"] = (filename, checksum)
        elif "i386" in filename:
            items["386"] = (filename, checksum)
        elif "riscv64" in filename:
            items["riscv64"] = (filename, checksum)
        elif "x86_64" in filename:
            items["amd64"] = (filename, checksum)
    
    tmpl = updater.get_package_file("lure-bin", "lure.tmpl.sh")
    updater.write_package_file("lure-bin", "lure.sh", tmpl % (
        name[1:],
        download_url + "/" + items["arm64"][0],
        items["arm64"][1],
        download_url + "/" + items["arm"][0],
        items["arm"][1],
        download_url + "/" + items["amd64"][0],
        items["amd64"][1],
        download_url + "/" + items["386"][0],
        items["386"][1],
        download_url + "/" + items["riscv64"][0],
        items["riscv64"][1],
    ))
    
    updater.push_changes("upg(lure-bin): %s" % name[1:])    

register_webhook(update_pkg)
