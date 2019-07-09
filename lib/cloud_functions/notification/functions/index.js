var functions = require("firebase-functions");
var admin = require("firebase-admin");

admin.initializeApp(functions.config().firebase);
var chatMetaData;
exports.pushNotification = functions.firestore
	.document("messages/{groupid}/{groupmessageid}/{message}")
	.onCreate((snapshots, context) => {
		console.log(context.params);

		chatMetaData = snapshots.data();
		var receiverToken = chatMetaData.receiverToken;
		console.log(receiverToken);

		var payload = {
			notification: {
				title: "Message from " + chatMetaData.isMe,
				body: chatMetaData.content,
				sound: "default"
			},
			data: {
				sendername: chatMetaData.isMe,
				message: chatMetaData.content
			}
		};
		return admin
			.messaging()
			.sendToDevice(receiverToken, payload)
			.then(response => {
				console.log("Pushed notifications");
				return "Success";
			})
			.catch(err => {
				console.log(err);
			});
	});
