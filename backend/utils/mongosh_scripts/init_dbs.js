const db = connect( 'mongodb://localhost/MemoSync' );
if(db.getCollectionInfos().length === 0) {
    console.log("Enter admin password: ")
    db.createUser({
      user: "admin",
      // pwd: passwordPrompt(),
      pwd: "oyboi", // WARN: For testing
      roles: [ "dbAdmin" ],
    });
    console.log("Enter localserver password (same as .env-secret): ")
    db.createUser({
      user: "localserver",
      // pwd: passwordPrompt(),
      pwd: "pwd", // WARN: For testing
      roles: [ "readWrite" ],
    });
    db.createCollection("Memos")
    db.createCollection("User")
}
else {
    console.log("Database already setup, leaving.")
}
