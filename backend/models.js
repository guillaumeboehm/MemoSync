module.exports = function(mongoose, dbCollNames) {
	var userSchema = new mongoose.Schema({
		email: String,
		password: String,
		verification: String,
		resetPasswordToken: String,
		jwt_recovery_tokens: [String],
		creationDate: Date
	}, {versionKey: false});
	var memoSchema = new mongoose.Schema({
		email: String,
		title: String,
		text: String,
		version: Number
	}, {versionKey: false});
	var models = {
		users : mongoose.model('User', userSchema, dbCollNames.Users),
		memos : mongoose.model('Memo', memoSchema, dbCollNames.Memos)
	};
	return models;
}
