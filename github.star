def update_repo(req):
    if req.method != 'POST':
        return {"code": 405, "body": "Method not allowed"}
    
    if req.headers["X-Github-Event"][0] != "push":
        return {"code": 400, "body": "This plugin only accepts push events"}
    
    updater.pull()

register_webhook(update_repo)