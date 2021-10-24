const bcrypt = require('bcrypt');
const crypto = require('crypto');
require('dotenv').config();

const express = require('express');
const app = express();
const jwt = require('jsonwebtoken');

//! Mail setup
const mailer = require('nodemailer');
const mailTransporter = mailer.createTransport({
	host: process.env.MAIL_HOST,
	port: process.env.MAIL_PORT,
	secure: true,
	auth: {
		user: process.env.MAIL_USER,
		pass: process.env.MAIL_PWD
	}
});

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

String.prototype.format = function () {
  var i = 0, args = arguments;
  return this.replace(/{}/g, function () {
    return typeof args[i] != 'undefined' ? args[i++] : '';
  });
};
const asciiToB64 = (data) => Buffer.from(data).toString('base64');
const b64ToAscii = (data) => Buffer.from(data, 'base64').toString('ascii');

app.use(express.json());

app.post('/newToken', async (req, res) => {
	try{
		const refreshToken = req.body.token;
		if (refreshToken == null) return res.status(401).json({err:"NoRefreshTokenSent"});
		jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET, async function(err, payload){
			if(err){
				console.log(err);
				return res.status(401).json({err:"RefreshTokenInvalid"});
			}
			if(await models.users.exists({email:payload.email, jwt_recovery_tokens:[refreshToken]})) return res.status(401).json({err:"RefreshTokenNotFound"});//I think I need a ! there... I'll just wait for it to crash cause I'm not sure

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
				return res.status(401).json({err:"NoUserFound"});
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
				return res.status(401).json({err:"NoUserFound"});
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
				return res.status(401).json({err:"NoUserFound"});
			}

			bcrypt.compare(pass, user.get('password'), function(err,success){
				if(err) {
					console.log(err);
					return res.sendStatus(500);
				}
				if(success){
					if(user.verification !== 'verified') return res.status(401).json({err:'VerifEmail'});
					const payload = { email: email };
					const accessToken = generateAccessToken(payload);
					const refreshToken = jwt.sign(payload, process.env.REFRESH_TOKEN_SECRET);

					const tokens = user.get('jwt_recovery_tokens');
					tokens.push(refreshToken);
					user.save();

					res.status(200).json({ accessToken: accessToken, refreshToken: refreshToken });
				}
				else res.status(401).json({err:"WrongPass"});
			});
		});
	} catch(e){
		console.log(e);
		res.status(500).json({err:e})
	}
})
app.post('/signup', async (req, res) => {
	try{
		if(await models.users.exists({email:req.body.email})) return res.status(409).json({err:"UserAlreadyExists"});

		const email = req.body.email;
		const hashedPassword = await bcrypt.hash(req.body.password, 10);
		const verifToken = crypto.randomBytes(40).toString('hex');
		sendVerifEmail(email, verifToken);
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
app.get('/verifEmail', async (req, res)=>{
	const email = req.query.user;
	const token = req.query.token;

	models.users.findOne({email:b64ToAscii(email)},function(err, user){
		if(err) {
			console.log(err);
			return res.sendStatus(500);
		}
		if(user===null) {
			console.log('No user found');
			return res.status(401).json({err:"NoUserFound"});
		}

		if(user.verification === 'verified') return res.status(200).send('<h1>Your email is already verified.</h1>');
		if(user.verification !== token) return res.status(400).send('<h1>The verification token is invalid, try logging in again and resending the verification email');
		user.verification = 'verified';
		user.save();
		res.status(200).send('<h1>Your Email is verified! You can close this window.</h1>');
	});
});
app.post('/resendVerif', async (req, res)=>{

});
app.post('/forgetPassword', async (req, res)=>{

});

function generateAccessToken(payload) {
	return jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, { expiresIn: '15h' });
}
function generateVerifURL(user, token){
	return process.env.VERIF_URL.format(user, token);
}
function sendVerifEmail(dest, token) {
	mailOptions = {
		from: process.env.MAIL_USER,
		to: dest,
		subject: process.env.MAIL_SUBJECT,
		text: process.env.MAIL_TEXT.format(generateVerifURL(asciiToB64(dest), token))
	}
	mailTransporter.sendMail(mailOptions, function(err, info){
		if (err) {
			console.log(err);
			//TODO Ensure that the user will eventually receive the mail dunno how
		} else {
			console.log('Email sent: ' + info.response);
		}
	});
}

app.listen(8081, async () => {
	console.log('authServer listening on 8081')
})
