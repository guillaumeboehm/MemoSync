const express = require('express');
const app = express();

const mongoose = require('mongoose');
const dbName = 'memosync';
const dbUsername = 'memosync';
const dbPwd = 'T6ECFJvfhi6td@%@93gJ';
const dbHost = 'localhost';
const dbPort = '27017';
//const mongoURL = 'mongodb://'+dbUsername+':'+dbPwd+'@'+dbHost+':'+dbPort+'/';
const mongoURL = 'mongodb://'+dbHost+':'+dbPort+'/'+dbName;
const collName = 'users';

main().catch(err => console.log(err));

async function main() {
	await mongoose.connect(mongoURL);

	app.listen(8080, () => {
	  console.log('server listening')
	})
}
