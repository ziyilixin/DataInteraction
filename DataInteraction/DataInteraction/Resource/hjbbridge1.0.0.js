window['ios'] = true

function device() {
	if(/(iPhone|iPad|iPod|iOS)/i.test(navigator.userAgent)) { //判断iPhone|iPad|iPod|iOS
		return window['ios']
	} else if(/(Android)/i.test(navigator.userAgent)) { //判断Android
		window['ios'] = false
		return window['ios']
	} else { //pc
		window['ios'] = false
		return window['ios']
	}
}

window.onload = device();

window.HJBbridge = {
	getImageByCamera: function(dict) {
		if(window['ios']) {
			window.webkit.messageHandlers.getImageByCamera.postMessage({
				"maxSize": dict.maxSize,
				"maxLength": dict.maxLength,
				"callback": "window.HJBbridge.onFinish"
			})
		} else {
			window.HJBbridgeAndroid.getImageByCamera("{'maxSize':" + dict.maxSize + ",'maxLength':" + dict.maxLength + ",'callback': 'window.HJBbridge.onFinish'}")
		}
		window['callback'] = dict
		return window['callback']
	},

	getLocation: function(dict) {
		if (window['ios']) {
			window.webkit.messageHandlers.getLocation.postMessage({
				"callback": "window.HJBbridge.onFinish"
			});
		} else{
			window.HJBbridgeAndroid.getLocation("{'callback': 'window.HJBbridge.onFinish'}")
		}
		window['callback'] = dict
		return window['callback']
	},

	close: function() {
		if (window['ios']) {
			window.webkit.messageHandlers.closeWindow.postMessage({});
		} else{
			window.HJBbridgeAndroid.close()
		}
	},
	getNetworkInfo: function(dict) {
		if (window['ios']) {
			window.webkit.messageHandlers.getNetworkInfo.postMessage({"callback": "window.HJBbridge.onFinish"})
		} else {
			window.HJBbridgeAndroid.getNetworkInfo("{'callback': 'window.HJBbridge.onFinish'}")
		}
		window['callback'] = dict
		return window['callback']
	},
	onFinish: function(result) {
		result = JSON.parse(result)
		window['callback'].onFinish(result)
	}
}
