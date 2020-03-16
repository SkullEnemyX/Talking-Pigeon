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
				title:
					chatMetaData.groupchat === "true"
						? chatMetaData.groupname
						: chatMetaData.isMe,
				body: chatMetaData.content.includes("https://i.ibb.co/")
					? ""
					: chatMetaData.groupchat === "true"
					? chatMetaData.isMe + ": " + chatMetaData.content
					: chatMetaData.content,
				sound: "default",
				image: chatMetaData.content.includes("https://i.ibb.co/")
					? chatMetaData.content
					: "",
				priority: "urgent",
				collapse_key: "talking_pigeon",
				tag: chatMetaData.isMe,
				click_action: "FLUTTER_NOTIFICATION_CLICK"
			},
			data: {
				sendername: chatMetaData.isMe,
				message: chatMetaData.content,
				groupchat: chatMetaData.groupchat,
				groupname: chatMetaData.groupname,
				groupid: chatMetaData.groupid
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
