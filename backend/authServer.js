const bcrypt = require('bcrypt');
const crypto = require('crypto');
require('dotenv').config();

const express = require('express');
const app = express();
const jwt = require('jsonwebtoken');

//! Mongoose config
const mongoose = require('mongoose');
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

app.use(express.json());

app.post('/newToken', async (req, res) => {
	try{
		const refreshToken = req.body.token;
		if (refreshToken == null) return res.sendStatus(401);
		jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET, async function(err, payload){
			if(err){
				console.log(err);
				return res.sendStatus(401);
			}
			if(await models.users.exists({email:payload.email, jwt_recovery_tokens:[refreshToken]})) return res.sendStatus(401);

			const accessToken = generateAccessToken({ email: payload.email });
			res.status(200).json({ accessToken: accessToken });
		});
	} catch(e){
		console.log(e);
		res.status(500).json({err:e})
	}
})

app.delete('/logout', async (req, res) => {
	try{
		// Delete the user's refresh tokens
		const email = req.body.email;
		const refreshToken = req.body.refreshToken;
		models.users.findOne({email:email},function(err, user){
			if(err) {
				console.log(err);
				return res.sendStatus(500);
			}
			if(user===null) {
				console.log('No user found');
				return res.status(401).json({err:"No user found with this email"});
			}

			const tokens = user.get('jwt_recovery_tokens');
			tokens.pop(refreshToken);
			user.save();

			res.sendStatus(204);
		});
	} catch(e){
		console.log(e);
		res.status(500).json({err:e})
	}
})
app.delete('/logoutEverywhere', async (req, res) => {
	try{
		// Delete all this user's refresh tokens
		const email = req.body.email;
		models.users.findOne({email:email},function(err, user){
			if(err) {
				console.log(err);
				return res.sendStatus(500);
			}
			if(user===null) {
				console.log('No user found');
				return res.status(401).json({err:"No user found with this email"});
			}

			user.set('jwt_recovery_tokens', []);
			user.save();

			res.sendStatus(204);
		});
	} catch(e){
		console.log(e);
		res.status(500).json({err:e})
	}
})

app.post('/login', async (req, res) => {
	try{
		const email = req.body.email;
		const pass = req.body.password;
		models.users.findOne({email:email},function(err, user){
			if(err) {
				console.log(err);
				return res.sendStatus(500);
			}
			if(user===null) {
				console.log('No user found');
				return res.status(401).json({err:"No user found with this email"});
			}

			bcrypt.compare(pass, user.get('password'), function(err,success){
				if(err) {
					console.log(err);
					return res.sendStatus(500);
				}
				if(success){
					const payload = { email: email };
					const accessToken = generateAccessToken(payload);
					const refreshToken = jwt.sign(payload, process.env.REFRESH_TOKEN_SECRET);

					const tokens = user.get('jwt_recovery_tokens');
					tokens.push(refreshToken);
					user.save();

					res.status(200).json({ accessToken: accessToken, refreshToken: refreshToken });
				}
				else res.status(401).json({err:"Wrong password"});
			});
		});
	} catch(e){
		console.log(e);
		res.status(500).json({err:e})
	}
})
app.post('/register', async (req, res) => {
	try{
		//if already exists exit
		if(await models.users.exists({email:req.body.email})) return res.sendStatus(409);

		const email = req.body.email;
		const hashedPassword = await bcrypt.hash(req.body.password, 10);
		const verifToken = crypto.randomBytes(40).toString('hex');
		//TODO send mail
		const newUser = new models.users({
			email: email,
			password: hashedPassword,
			verification: verifToken,
			jwt_recovery_tokens: [],
			creationDate: Date.now().toString() });
		newUser.save();
		res.sendStatus(201);
	} catch(err) {
		console.log(err)
		res.sendStatus(500);
	}

})

function generateAccessToken(payload) {
	return jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, { expiresIn: '15h' });
}

app.listen(8081, async () => {
	console.log('authServer listening')
})
