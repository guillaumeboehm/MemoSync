module.exports = {
  apps : [{
    name   : "server",
    script : "./server.cjs",
    watch  : true,
    ignore_watch : [".gitignore","*.pdf","authServer.js","node_modules","package-lock.json","*.cert","*.key"]
  },
  {
    name   : "authServer",
    script : "./authServer.cjs",
    watch  : true,
    ignore_watch : [".gitignore","*.pdf","server.js","node_modules","package-lock.json","*.cert","*.key"]
  }]
}
