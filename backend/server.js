const express = require('express');
const app = express();

const bcrypt = require('bcrypt');
const crypto = require('crypto');
require('dotenv').config();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
var path = require('path');
var favicon = require('serve-favicon');

//! view engine setup
app.set('views', path.join(__dirname,'../frontend/views'));
app.set('view engine', 'ejs');
app.set('view options', {filename:true});
app.use('/css', express.static(path.join(__dirname, "../frontend/css")));
app.use('/js', express.static(path.join(__dirname, "../frontend/js")));
app.use('/resources', express.static(path.join(__dirname, "../resources")));
app.use(favicon(path.join(__dirname, '../resources/favicon.ico')));
//TODO restrict access for connected/disconnected
app.get('/', (req, res) => {
	res.render('welcome');
})
app.get('/home', (req, res) => {
	res.render('home');
})
app.get('/login', (req, res) => {
	res.render('login');
})
app.get('/signup', (req, res) => {
	res.render('signup');
})
app.get('/verifEmail', (req, res) => {
	res.render('verifEmail');
})
app.get('/resendVerif', (req, res) => {
	res.render('resendVerif');
})
app.get('/forgotPassword', (req, res) => {
	res.render('forgotPassword');
})
app.get('/changePassword', (req, res) => {
	res.render('changePassword');
})

//! Mongoose config
const dbName = process.env.DB_NAME;
const dbUsername = process.env.DB_USERNAME;
const dbPwd = process.env.DB_PWD;
const dbHost = process.env.DB_HOST;
const dbPort = process.env.DB_PORT;
const dbCollNames = {
	Users: process.env.DB_USER_COLL_NAME,
	Memos: process.env.DB_MEMO_COLL_NAME
}
const mongoURL = 'mongodb://'+dbHost+':'+dbPort+'/'+dbName;

try{
	mongoose.connect(mongoURL, {user:dbUsername,pass:dbPwd});
} catch(err){
	console.log(err);
}

const models = require('./models')(mongoose, dbCollNames);

//! Express config
app.use(express.json());

//Admin routes
app.delete('/AdminRemUsers', async (req,res)=>{
	if(req.headers.pwd !== process.env.ADMIN_PASS) return res.sendStatus(403);
	models.users.deleteMany({}, function (err){
		if(err){
			console.log(err);
			res.sendStatus(500);
		}
		else{
			console.log('All users deleted by admin');
			res.sendStatus(205);
		}
	});
	models.memos.deleteMany({}, function (err){
		if(err){
			console.log(err);
			res.sendStatus(500);
		}
		else{
			console.log("All memos removed by admin")
			res.sendStatus(200);
		}
	})
})
app.delete('/AdminRemUser', async (req,res)=>{
	if(req.headers.pwd !== process.env.ADMIN_PASS) return res.sendStatus(403);
	models.users.deleteOne({email:req.body.email}, function (err){
		if(err){
			console.log(err);
			res.sendStatus(500);
		}
		else{
			console.log('User '+req.body.email+' deleted by admin');
			res.sendStatus(205);
		}
	});
	models.memos.deleteMany({email:req.body.email}, function (err){
		if(err){
			console.log(err);
			res.sendStatus(500);
		}
		else{
			console.log("All memos from "+req.body.email+" removed by admin")
			res.sendStatus(200);
		}
	})
})
app.delete('/AdminRemAllMemos', async (req,res)=>{
	if(req.headers.pwd !== process.env.ADMIN_PASS) return res.sendStatus(403);
	models.memos.deleteMany({}, function (err){
		if(err){
			console.log(err);
			res.sendStatus(500);
		}
		else{
			console.log("All memos removed by admin")
			res.sendStatus(200);
		}
	})
})
app.delete('/AdminRemMemos', async (req,res)=>{
	if(req.headers.pwd !== process.env.ADMIN_PASS) return res.sendStatus(403);
	models.memos.deleteMany({email:req.body.email}, function (err){
		if(err){
			console.log(err);
			res.sendStatus(500);
		}
		else{
			console.log("All memos from "+req.body.email+" removed by admin")
			res.sendStatus(200);
		}
	})
})
app.delete('/AdminRemMemo', async (req,res)=>{
	if(req.headers.pwd !== process.env.ADMIN_PASS) return res.sendStatus(403);
	models.memos.deleteOne({email:req.body.email, title:req.body.memoTitle}, function (err){
		if(err){
			console.log(err);
			res.sendStatus(500);
		}
		else{
			console.log("Memo "+req.body.memoTitle+" from "+req.body.email+" removed by admin")
			res.sendStatus(200);
		}
	})
})

//Normal routes
app.post('/newMemo', authenticateToken, async (req,res)=>{
	try{
		const userEmail = req.userInfo.email;
		const memoTitle = req.body.memoTitle;
		//if already exists exit
		if(await models.memos.exists({email:userEmail, title:memoTitle}).then(exists=>{
			if(exists){
				res.status(409).json({err: "memoAlreadyExists"});
				return true;
			}
		})) return 0;

		const newMemo = new models.memos({
			email: userEmail,
			title: memoTitle,
			text: "",
			version: 0
		});
		newMemo.save();
		res.sendStatus(201);
	} catch {
		res.sendStatus(500);
	}
})
app.get('/getAllMemos', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		models.memos.find({email:email}, '-email', function (err, memos){
			if(err){
				console.log(err);
				res.sendStatus(500);
			}
			else{
				res.status(200).json(memos);
			}
		})
	}catch(err){
		console.log(err);
		res.sendStatus(500);
	}
})
app.post('/getMemo', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		const memoTitle = req.body.memoTitle;
		models.memos.findOne({email:email, title:memoTitle}, '-email -title', function (err, memo){
			if(err){
				console.log(err);
				res.sendStatus(500);
			}
			else{
				res.status(200).json(memo);
			}
		})
	}catch(err){
		console.log(err);
		res.sendStatus(500);
	}
})
app.post('/updateMemo', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		const memoTitle = req.body.memoTitle;
		const memoTxt = req.body.memoTxt;
		const memoVer = req.body.currentVersion;
		models.memos.findOne({email:email, title:memoTitle}, '-email -title',function (err, memo){
			if(err){
				console.log(err);
				res.sendStatus(500);
			}
			else{
				if(memoVer < memo.get('version')) return res.status(406).json(memo);
				memo.set({text:memoTxt, version:memo.version+1});
				memo.save();
				res.status(200).json(memo.version);
			}
		})
	}catch(err){
		console.log(err);
		res.sendStatus(500);
	}
})
app.delete('/deleteMemo', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		const memoTitle = req.body.memoTitle;
		models.memos.deleteOne({email:email, title:memoTitle}, function (err){
				if(err){
					console.log(err);
					res.sendStatus(500);
				}
				else{
					console.log("Memo "+req.body.memoTitle+" from "+req.body.email+" removed by user")
					res.sendStatus(200);
				}
			})
	}catch(err){
		console.log(err);
		res.sendStatus(500);
	}
})

//Utilities
function authenticateToken(req, res, next) {
	const authHeader = req.headers['authorization'];
	const token = authHeader && authHeader.split(' ')[1];
	console.log('received token', token)
	if(token == null) return res.redirect('/');

	jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, (err, payload) => {
		console.log(err);
		if(err) return res.sendStatus(403);
		req.userInfo = payload;
		next();
	})
}
function isConnected(req, res, next) {
	const authHeader = req.headers['authorization'];
	const token = authHeader && authHeader.split(' ')[1];
	if(token == null) return res.redirect('/');

	jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, (err, payload) => {
		console.log(err);
		if(err) return res.sendStatus(403);
		req.userInfo = payload;
		next();
	})
}

app.listen(8080, async () => {
	console.log('server listening')
})
