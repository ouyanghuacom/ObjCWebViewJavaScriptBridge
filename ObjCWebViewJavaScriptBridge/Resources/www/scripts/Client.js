const WVJSBCreateClient = function(namespace = 'wvjsb_namespace', infomation = {}) {
	const clientKey = 'wvjsb_client_' + namespace;
	const proxyKey = 'wvjsb_proxy_' + namespace;

	function getClient() {
		return window[clientKey];
	}

	function setClient(client) {
		window[clientKey] = client;
	}

	let client = getClient();

	if (client) return client;
    
	const installURL = 'https://wvjsb/' + namespace + '/install';

	function createGuid() {
		return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			var r = Math.random() * 16 | 0,
				v = c == 'x' ? r : (r & 0x3 | 0x8);
			return v.toString(16);
		});
	}

	const clientId = createGuid();

	let connected = false;
	let nextSeq = 0;
	const cancels = {};
	const handlers = {};
	const operations = {};

	function sendToProxy(message) {
		const data = {};
		data[namespace] = message;
		window.top.postMessage(data, '*');
	}

	function connect() {
		sendToProxy({
			from: clientId,
			to: namespace,
			type: 'connect',
			parameter: infomation
		});
	}

	function disconnect() {
		sendToProxy({
			from: clientId,
			to: namespace,
			type: 'disconnect'
		});
	}

	function startAllOperation() {
		for (let id in operations) {
			const operation = operations[id];
			operation.start();
		}
	}

	function finishAllOperation() {
		for (let id in operations) {
			const operation = operations[id];
			operation.receive(null, "connectionlost");
		}
	}

	client = {
		on: function(type) {
			let handler = handlers[type];
			if (handler){
				return handler;
			}
			handler = {
				onEvent: function(func) {
					const handler = this;
					handler.event = func;
					return handler;
				},
				onCancel: function(func) {
					const handler = this;
					handler.cancel = func;
				}
			};
			handlers[type] = handler;
			return handler;
		},
		event: function(type, parameter) {
			const id = (nextSeq++).toString();
			const operation = {
				id: id,
				type: type,
				parameter: parameter,
				done: false,
				ack: null,
				onAck: function(func) {
					const operation = this;
					if (operation.done) return;
                    operations[id] = operation;
					operation.ack = func;
					return operation;
				},
				timeout: function(timeout) {
					const operation = this;
					if (operation.done) return;
                    if (timeout <= 0) return;
                    operations[id] = operation;
                    if (operation.timer){
                        window.clearTimeout(timer);
                    }
					operation.timer = window.setTimeout(function() {
						if (operation.done) return;
						operation.done = true;
						delete operations[id];
						const timer = operation.timer;
						if (timer){
							window.clearTimeout(timer);
							delete operation.timer;
						}
						const ack = operation.ack;
						if (ack) ack(operation, null, "timedout");
					}, timeout);
					return operation;
				},
				cancel: function() {
					const operation = this;
					if (operation.done) return;
					operation.done = true;
					delete operations[id];
					const timer = operation.timer;
					if (timer) {
						window.clearTimeout(timer);
						delete operation.timer;
					}
					const ack = operation.ack;
					if (ack) ack(operation, null, "cancelled");

				},
				receive: function(result, exception) {
					const operation = this;
					if (operation.done) return;
					operation.done = true;
					delete operations[id];
					const timer = operation.timer;
					if (timer) {
						window.clearTimeout(timer);
						delete operation.timer;
					}
					const ack = operation.ack;
					if (ack) ack(operation, result, exception);
				},
				start: function() {
					if (!connected) return;
					const operation = this;
					sendToProxy({
						id: operation.id,
                        type: operation.type,
                        from: clientId,
                        to: namespace,
						parameter: operation.parameter
					});
				}
			};
			operations[id] = operation;
			operation.start();
			return operation;
		}
	};
	window.addEventListener('message', function({
		data
	}) {
		try {
			const message = data[namespace];
			if (!message) return;
			const {
				id, from, to, type, parameter, exception
			} = message;
			if (proxyKey == from) {
				if ('connect' == type){
					if (true == connected){
						connected = false;
					}
					connect();
				}else if("disconnect" == type){
					if (true == connected){
						connected = false;
						finishAllOperation();
					}
				}
				return;
			}
			if (to != clientId) return;
			if (from != namespace) return;
			if ('connect' == type) {
				if (connected == true) return;
				connected = true;
				startAllOperation();
				const handler = handlers[type];
				if (!handler) return;
				handler.event(null,function(){
					return function(_,_){}
				});
				return;
			}
			if ('cancel' == type) {
				const cancel = cancels[id];
				if (cancel) cancel();
				return;
			}
			if ('ack' == type) {
				const operation = operations[id];
				if (!operation) return;
				if (operation) operation.receive(parameter, exception);
				return;
			}
			const handler = handlers[type];
			if (!handler) return;
			const context = handler.event(message.parameter, function() {
				delete cancels[id];
				return function(result, exception){
					sendToProxy({
						id: id,
						from: clientId,
						to: from,
						type: 'ack',
						parameter: result,
						exception: exception
					});
				}
			});
			cancels[id]=function (){
				handler.cancel(context);
				delete cancels[id];
			}
		} catch (e) {}
	});

	window.addEventListener('unload', function() {
		if (connected == false) return;
		connected = false;
		finishAllOperation();
		disconnect();
	});

	function tellServerToInstall() {
		const iframe = document.createElement('iframe');
		iframe.style.display = 'none';
		iframe.src = installURL;
		document.documentElement.appendChild(iframe);
		window.setTimeout(function() {
			document.documentElement.removeChild(iframe);
		}, 1);
	}
	tellServerToInstall();
	connect();
	setClient(client);
	return client;
};
