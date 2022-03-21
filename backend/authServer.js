const bcrypt = require('bcrypt');
const crypto = require('crypto');
require('dotenv').config();

const express = require('express');
const app = express();
const jwt = require('jsonwebtoken');
var cors = require('cors');
var apiCall = undefined;

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
	if(err) console.log(err);
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
app.use(cors({origin: '*'}));

app.post('/newToken', async (req, res) => {
	apiCall='newToken'
	try{
		const authHeader = req.headers['authorization'];
		const authToken = authHeader && authHeader.split(' ')[1];
		refresh = true
		if (authToken != null) await jwt.verify(authToken, process.env.ACCESS_TOKEN_SECRET, (err, payload) => {
			if(!err){
				refresh = false;
				// check if user still exists
				if(models.users.exists({email:payload.email}).then(exists=>{ // Not sure wait await isn't accepted here... Seems to work without so meh
					if(!exists){
						logError('UserNotFound');
						res.status(401).json({err:"UserNotFound"});
						return true;
					}
				})) return 0;
				logSuccess('Sending back current token');
				return res.status(200).json({ accessToken: authToken });// resend the same token
			}
		});
		if(!refresh) return 0;
		const refreshToken = req.body.token;
		if (refreshToken == null){
			logError("NoRefreshTokenSent");
			return res.status(401).json({err:"NoRefreshTokenSent"});
		}
		jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET, async function(err, payload){
			if(err){
				logError("RefreshTokenInvalid", err);
				return res.status(401).json({err:"RefreshTokenInvalid"});
			}
			if(await models.users.exists({email:payload.email, jwt_recovery_tokens:[refreshToken]}).then(exists=>{
				if(!exists){
					logError("RefreshTokenNotFound");
					res.status(401).json({err:"RefreshTokenNotFound"});
					return true;
				}
			})) return 0;

			const accessToken = generateAccessToken({ email: payload.email });
			logSuccess('Sending new token');
			res.status(200).json({ accessToken: accessToken });
		});
	} catch(e){
		logError("InternalError", e);
		res.status(500).json({err:e})
	}
})

app.delete('/logout', async (req, res) => {
	apiCall='logout';
	try{
		// Delete the user's refresh tokens
		const authHeader = req.headers['authorization'];
		const refreshToken = authHeader && authHeader.split(' ')[1];
		if(refreshToken == null){
			logError("NoUserFound");
			return res.status(400).json({err:"NoUserFound"});
		}
		jwt.verify(token, process.env.REFRESH_TOKEN_SECRET, (err, payload) => {
			if(err){
				logError("InvalidBearerToken", err);
				return res.status(401).json({err:"InvalidBearerToken"});
			}
			models.users.findOne({email:payload.email},function(err, user){
				if(err){
					logError("InternalError", err);
					return res.sendStatus(500);
				}
				if(user===null){
					logError("NoUserFound");
					return res.status(400).json({err:"NoUserFound"});
				}

				const tokens = user.get('jwt_recovery_tokens');
				tokens.pop(refreshToken);
				user.save();

				logSuccess(payload.email+" logged out");
				res.sendStatus(204);
			});
		});
		logError("UnknownError");
		return res.sendStatus(500);
	} catch(e){
		logError("InternalError", e);
		res.status(500).json({err:e})
	}
})
app.delete('/logoutEverywhere', async (req, res) => {
	apiCall='logoutEverywhere';
	try{
		// Delete all this user's refresh tokens
		const authHeader = req.headers['authorization'];
		const token = authHeader && authHeader.split(' ')[1];
		if(token == null){
			logError("NoBearerTokenSent");
			return res.status(401).json({err:"NoBearerTokenSent"});
		}

		jwt.verify(token, process.env.REFRESH_TOKEN_SECRET, (err, payload) => {
			if(err){
				logError("InvalidBearerToken",err);
				return res.status(401).json({err:"InvalidBearerToken"});
			}
			models.users.findOne({email:payload.email},function(err, user){
				if(err){
					logError("InternalError", err);
					return res.sendStatus(500);
				}
				if(user===null){
					logError("NoUserFound",err);
					return res.status(400).json({err:"NoUserFound"});
				}

				user.set('jwt_recovery_tokens', []);
				user.save();

				logSuccess(payload.email+'logged out everywhere');
				res.sendStatus(204);
			});
		})
		logError("UnknownError");
		return res.sendStatus(500);
	} catch(e){
		logError("InternalError", e);
		res.status(500).json({err:e})
	}
})

app.post('/login', async (req, res) => {
	apiCall='login';
	try{
		const email = req.body.email;
		const pass = req.body.password;
		models.users.findOne({email:email},function(err, user){
			if(err) {
				logError("InternalError", err);
				return res.sendStatus(500);
			}
			if(user===null) {
				logError("NoUserFound");
				return res.status(401).json({err:"NoUserFound"});
			}
			if(user.verification !== 'verified'){
				logError("VerifEmail");
				return res.status(401).json({err:'VerifEmail'});
			}

			bcrypt.compare(pass, user.get('password'), function(err,success){
				if(err) {
					logError("InternalError", err);
					return res.sendStatus(500);
				}
				if(success){
					const payload = { email: email };
					const accessToken = generateAccessToken(payload);
					const refreshToken = jwt.sign(payload, process.env.REFRESH_TOKEN_SECRET);

					const tokens = user.get('jwt_recovery_tokens');
					tokens.push(refreshToken);
					user.save();

					logSuccess(payload.email+" logged in");
					res.status(200).json({ accessToken: accessToken, refreshToken: refreshToken });
				}
				else{
					logError("WrongPass");
					res.status(401).json({err:"WrongPass"});
				}
			});
		});
	} catch(e){
		logError("InternalError", e);
		res.status(500).json({err:e})
	}
})
app.post('/signup', async (req, res) => {
	apiCall='signup';
	try{
		if(await models.users.exists({email:req.body.email}).then(exists=>{
			if(exists){
				logError("UserAlreadyExists");
				res.status(409).json({err:"UserAlreadyExists"});
				return true;
			}
		})) return 0;

		const email = req.body.email;
		const hashedPassword = await bcrypt.hash(req.body.password, 10);
		const verifToken = crypto.randomBytes(40).toString('hex');
		sendVerifEmail(email, verifToken).then(mailRes=>{
			console.log(mailRes)
			switch(mailRes.status){
				case 504:
					logError('UnqualifiedAddress');
					return res.status(400).json({err:'UnqualifiedAddress'});
			}
			const newUser = new models.users({
				email: email,
				password: hashedPassword,
				verification: verifToken,
				jwt_recovery_tokens: [],
				creationDate: Date.now().toString() });
			newUser.save();
			logSuccess(email+" user created");
			return res.sendStatus(201);
		});
	} catch(err) {
		logError("InternalError", err);
		return res.sendStatus(500);
	}
})
app.get('/verifEmail', async (req, res)=>{
	apiCall='verifEmail';
	try{
		const email = req.query.user;
		const token = req.query.token;

		if(email===undefined || token===undefined){
			logError('InvalidURL');
			return res.status(403).json({
				text: 'The url is invalid, try resending the verification email.',
				button: 'Resend verification email',
				redirect: '/resendVerif'
			});
		}

		models.users.findOne({email:b64ToAscii(email)},function(err, user){
			if(err) {
				logError('InternalError', err);
				return res.sendStatus(500);
			}
			if(user===null) {
				logError('NoUserFound');
				return res.status(401).json({
					text: 'The user you\'re trying to verify couldn\'t be found.',
					button: 'Sign up',
					redirect: '/signup'
				});

			}

			if(user.verification === 'verified'){
				logSuccess("Email already verified");
				return res.status(200).json({
					text: 'Your email is already verified.',
					button: 'Login',
					redirect: '/login'
				});
			}
			if(user.verification !== token){
				logError("verification token invalid");
				return res.status(400).json({
					text: 'The verification token is invalid, try resending the verification email.',
					button: 'Resend verification email',
					redirect: '/resendVerif'
				});
			}
			user.verification = 'verified';
			user.save();
			logSuccess("Email is verified");
			res.status(200).json({
				text: 'Your email has been verified, your can now log in your MemoSync account.',
				button: 'Login',
				redirect: '/login'
			});
		});
	} catch(err){
		logError("InternalError", err);
		res.sendStatus(500);
	}
});
app.post('/forgotPassword', async (req, res)=>{
	apiCall='forgotPassword';
	try{
		const email = req.body.email;
		models.users.findOne({email:email}, (err,user)=>{
			if(err) {
				logError("InternalError", err);
				return res.sendStatus(500);
			}
			if(user===null) {
				logError("NoUserFound");
				return res.status(400).json({err:"NoUserFound"});
			}

			const pwdToken = crypto.randomBytes(40).toString('hex');
			sendForgottenPasswordEmail(email, pwdToken).then(mailRes=>{
				console.log(mailRes)
				switch(mailRes.status){
					case 504:
						logError("UnqualifiedAddress");
						return res.status(400).json({err:'UnqualifiedAddress'});
				}
				user.set('resetPasswordToken', pwdToken);
				user.save();
				logSuccess('reset link sent');
				res.sendStatus(200);
			});
		});
	} catch(err) {
		logError("InternalError", err);
		res.sendStatus(500);
	}
});
app.post('/changePassword', async (req, res)=>{
	const authHeader = req.headers['authorization'];
	const accessToken = authHeader && authHeader.split(' ')[1];
	const hashedPassword = await bcrypt.hash(req.body.password, 10);

	var resetToken = undefined;
	var email = undefined;
	var error = {err: 'UnkownError'};
	// Check access token if one is provided
	if(accessToken){
		jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET, (err, payload) => {
			if(err) logError("accessToken invalid", err);
			if(!err) email = payload.email;
			error = err;
		});
	}
	// if no access token was provided get the email from the body
	if(!email){
		resetToken = req.body.resetToken;
		if(req.body.user && resetToken) email = b64ToAscii(req.body.user);
		else error = {err: 'MalformedLink'};
	}
	// if email is still not set something went wrong
	if(!email){
		if(error.err) logError(error.err);
		return res.status(400).json(error);
	}
	models.users.findOne({email:email},function(err, user){
		if(err) {
			logError('InternalError', err);
			return res.sendStatus(500);
		}
		if(user===null){
			logError('NoUserFound');
			return res.status(400).json({ err: 'NoUserFound' });
		}
		if(resetToken && user.get('resetPasswordToken')!==resetToken){
			logError('MalformedLink');
			return res.status(400).json({ err: 'MalformedLink' });
		}

		//Issok
		user.set('password', hashedPassword);
		user.set('resetPasswordToken', '');
		user.save();
		logSuccess('password changed');
		res.sendStatus(201);
	});
});
app.post('/resendVerif', async (req, res)=>{
	apiCall='resendVerif';
	try{
		const email = req.body.email;
		models.users.findOne({email:email},function(err, user){
			if(err) {
				logError('InternalError', err);
				return res.sendStatus(500);
			}
			if(user===null){
				logError('NoUserFound');
				return res.status(400).json({ err: 'NoUserFound' });
			}
			if(user.verification === 'verified'){
				logError('AlreadyVerified');
				return res.status(400).json({ err: 'AlreadyVerified' });
			}

			const verifToken = crypto.randomBytes(40).toString('hex');
			sendVerifEmail(email, verifToken).then(mailRes=>{
				console.log(mailRes)
				switch(mailRes.status){
					case 504:
						logError('UnqualifiedAddress');
						return res.status(400).json({err:'UnqualifiedAddress'});
				}
				user.set('verification', verifToken);
				user.save();
				logSuccess('verif email sent');
				res.sendStatus(200);
			});
		});
	} catch(err) {
		logError('InternalError', err);
		res.sendStatus(500);
	}
});

function generateAccessToken(payload) {
	return jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, { expiresIn: '15h' });
}
async function sendVerifEmail(dest, token) {
	return new Promise((resolve,reject)=>{
		mailOptions = {
			from: process.env.MAIL_USER,
			to: dest,
			subject: process.env.VERIF_MAIL_SUBJECT,
			text: process.env.VERIF_MAIL_TEXT.format(process.env.VERIF_URL.format(asciiToB64(dest), token))
		}
		let mailRes = {};
		mailTransporter.sendMail(mailOptions, function(err, info){
			if (err) {
				console.log(err);
				mailRes.status = err.responseCode;
				mailRes.err = err.response;
				resolve(mailRes);
				//TODO Ensure that the user will eventually receive the mail dunno how
			} else {
				mailRes.status = 200;
				console.log('Email sent: ' + info.response);
				resolve(mailRes);
			}
		});
	});
}
async function sendForgottenPasswordEmail(dest, token) {
	return new Promise((resolve,reject)=>{
		mailOptions = {
			from: process.env.MAIL_USER,
			to: dest,
			subject: process.env.PWD_MAIL_SUBJECT,
			text: process.env.PWD_MAIL_TEXT.format(process.env.PWD_URL.format(asciiToB64(dest), token))
		}
		let mailRes = {};
		mailTransporter.sendMail(mailOptions, function(err, info){
			if (err) {
				console.log(err);
				mailRes.status = err.responseCode;
				mailRes.err = err.response;
				resolve(mailRes);
				//TODO Ensure that the user will eventually receive the mail dunno how
			} else {
				mailRes.status = 200;
				console.log('Email sent: ' + info.response);
				resolve(mailRes);
			}
		});
	});
}

function logSuccess(msg, ret){
	ret ? console.log("SUCCESS "+apiCall+" : "+msg, ret) : console.log("SUCCESS "+apiCall+" : "+msg);
}
function logError(msg, ret){
	ret ? console.log("ERROR "+apiCall+" : "+msg, ret) : console.log("ERROR "+apiCall+" : "+msg);
}

app.listen(8081, async () => {
	console.log('authServer listening on 8081')
})
