def update_pkg(location):
    match = regex.compile(r'https://dl\.discordapp\.net/apps/linux/(\d+\.\d+\.\d+)/.+\.tar\.gz').find_one(location)
    tmpl = updater.get_package_file("discord-bin", "lure.tmpl.sh")
    updater.write_package_file("discord-bin", "lure.sh", tmpl % (match[1], location))
    updater.push_changes("upg(discord-bin): %s" % match[1])

def poll_for_updates():
    res = http.get("https://discord.com/api/download?platform=linux&format=tar.gz", redirect=False)
    res.body.close()
    
    if res.code != 302:
        log.error("Invalid response code", fields={"code": res.code, "expected": 302})
        return
    
    location = res.headers["Location"][0]
    stored = store.get("location")
    
    if stored == "":
        store.set("location", location)
    elif stored != location:
        update_pkg(location)
        store.set("location", location)

run_every("1h", poll_for_updates)
