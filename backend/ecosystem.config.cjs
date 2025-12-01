module.exports = {
  apps : [{
    name   : "server",
    script : "./server.cjs",
    watch  : ['./'],
    ignore_watch : [".gitignore","*.pdf","authServer.cjs","node_modules","package-lock.json","*.cert","*.key","utils","dockerfiles","docs",".env.default","compose.yaml","*Servers.sh"]
  },
  {
    name   : "authServer",
    script : "./authServer.cjs",
    watch  : ['./'],
    ignore_watch : [".gitignore","*.pdf","server.cjs","node_modules","package-lock.json","*.cert","*.key","utils","dockerfiles","docs",".env.default","compose.yaml","*Servers.sh"]
  }]
}
