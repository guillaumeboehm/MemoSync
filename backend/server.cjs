const express = require('express');
const json = express.json;
const app = express();

// const bcrypt = require('bcrypt');
// const crypto = require('crypto');
const dotenv = require('dotenv');
dotenv.config()
const mongoose = require('mongoose');
const connect = mongoose.connect;
const jwt = require('jsonwebtoken');
const { join } = require('path');
const favicon = require('serve-favicon');

//! view engine setup
app.set('views', join(__dirname,'../frontend/views'));
app.set('view engine', 'ejs');
app.set('view options', {filename:true});
app.use('/css', express.static(join(__dirname, "../frontend/css")));
app.use('/js', express.static(join(__dirname, "../frontend/js")));
app.use('/resources', express.static(join(__dirname, "../resources")));
app.use(favicon(join(__dirname, '../resources/favicon.ico')));
//TODO restrict access for connected/disconnected
app.get('/', (_, res) => {
	res.render('welcome');
})
app.get('/home', (_, res) => {
	res.render('home');
})
app.get('/login', (_, res) => {
	res.render('login');
})
app.get('/signup', (_, res) => {
	res.render('signup');
})
app.get('/verifEmail', (_, res) => {
	res.render('verifEmail');
})
app.get('/resendVerif', (_, res) => {
	res.render('resendVerif');
})
app.get('/forgotPassword', (_, res) => {
	res.render('forgotPassword');
})
app.get('/changePassword', (_, res) => {
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
	connect(mongoURL, {user:dbUsername,pass:dbPwd});
} catch(err){
	console.log(err);
}

const models = require('./models')(mongoose, dbCollNames);

//! Express config
app.use(json());

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
				res.status(409).json({code: "MemoAlreadyExists", message: "Cannot create the memo because a memo with the given title already exists"});
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
		res.status(201).json({code: "MemoCreated", title: memoTitle});
	} catch (err){
		res.status(500).json({code: "InternalError", message:err });
	}
})
app.get('/getMemos', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		models.memos.find({email:email, title: { $in: req.query.memos }}, '-email', function (err, memos){
			if(err){
				console.log(err);
				res.status(500).json({code: "InternalError", message:err });
			}
			else{
				res.status(200).json(memos);
			}
		})
	}catch(err){
		console.log(err);
		res.status(500).json({code: "InternalError", message:err });

	}
})
app.get('/getAllMemos', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		models.memos.find({email:email}, '-email', function (err, memos){
			if(err){
				console.log(err);
				res.status(500).json({code: "InternalError", message:err });
			}
			else{
				res.status(200).json(memos);
			}
		})
	}catch(err){
		console.log(err);
		res.status(500).json({code: "InternalError", message:err });

	}
})
app.get('/getAllMemosMetadata', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		models.memos.find({email:email}, '-email -text', function (err, memos){
			if(err){
				console.log(err);
				res.status(500).json({code: "InternalError", message:err });
			}
			else{
				res.status(200).json(memos);
			}
		})
	}catch(err){
		console.log(err);
		res.status(500).json({code: "InternalError", message:err });

	}
})
app.post('/getMemo', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		const memoTitle = req.body.memoTitle;
		const memoVersion = req.body.version;
		models.memos.findOne({email:email, title:memoTitle}, '-email -title', function (err, memo){
			if(err){
				console.log(err);
				res.status(500).json({code: "InternalError", message:err });
			}
			else{
				if(memo != null){
					if(memo.version <= memoVersion){
						memo = {
							_id: memo['_id'],
							version: memo['version']
						}
					}
					res.status(200).json(memo);
				}
				else {
					res.status(410).json({ code: "MemoDeleted" });
				}
			}
		});
	}catch(err){
		console.log(err);
		res.status(500).json({code: "InternalError", message:err });
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
				res.status(500).json({code: "InternalError", message:err });
			}
			else{
				if(memo != null){
					if(memoVer <= memo.get('version')) return res.status(406).json({code:"NewerVersionExists",memo:memo});
					memo.set({ text: memoTxt, version: memoVer });
					memo.save();
					res.status(200).json({version:memo.version});
				}
				else {
					res.status(410).json({code: "MemoDeleted"});
				}
			}
		})
	}catch(err){
		console.log(err);
		res.status(500).json({code: "InternalError", message:err });
	}
})
app.delete('/deleteMemo', authenticateToken, async (req,res)=>{
	try{
		const email = req.userInfo.email;
		const memoTitle = req.body.memoTitle;
		models.memos.deleteOne({email:email, title:memoTitle}, function (err){
				if(err){
					console.log(err);
					res.status(500).json({code: "InternalError", message:err });
				}
				else{
					console.log("Memo "+req.body.memoTitle+" from "+req.body.email+" removed by user")
					res.status(200).json({code: "MemoDeleted", title: req.body.memoTitle});
				}
			})
	}catch(err){
		console.log(err);
		res.status(500).json({code: "InternalError", message:err });
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
		if(err) return res.status(403).json({code:"InvalidToken" ,message: err});
		req.userInfo = payload;
		next();
	})
}
// INFO: Never used
// function isConnected(req, res, next) {
// 	const authHeader = req.headers['authorization'];
// 	const token = authHeader && authHeader.split(' ')[1];
// 	if(token == null) return res.redirect('/');
// 	jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, (err, payload) => {
// 		console.log(err);
// 		if(err) return res.status(403).json({code:"InvalidToken" ,message: err});
// 		req.userInfo = payload;
// 		next();
// 	})
// }

app.listen(8080, async () => {
	console.log('server listening')
})
