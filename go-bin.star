def update_pkg(s, version):
    rows = s.find('tbody > tr')
    checksums = {}
    for row in rows:
        link = row.first().find('a').attr('href')        
        checksum = row.last().find('tt').text()
        
        if 'linux' not in link:
            continue
        elif 'linux-386' in link:
            checksums['386'] = checksum
        elif 'linux-amd64' in link:
            checksums['amd64'] = checksum
        elif 'linux-arm64' in link:
            checksums['arm64'] = checksum
        elif 'linux-armv6l' in link:
            checksums['arm6'] = checksum
        elif 'linux-riscv64' in link:
            checksums['riscv64'] = checksum
    
    tmpl = updater.get_package_file("go-bin", "lure.tmpl.sh")
    updater.write_package_file("go-bin", "lure.sh", tmpl % (
        version,
        checksums["amd64"],
        checksums["arm64"],
        checksums["arm6"],
        checksums["386"],
        checksums["riscv64"],
    ))
    
    updater.push_changes("upg(go-bin): %s" % version)
    
def poll_for_updates():
    res = http.get('https://go.dev/dl')
    s = html.parse(res.body).find('h2#stable').next()
    
    version = s.attr("id").removeprefix("go")
    stored = store.get('version')
    if stored == "":
        store.set("version", version)
    elif stored != version:
        update_pkg(s, version)
        store.set("version", version)

run_every("1h", poll_for_updates)
