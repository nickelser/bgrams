/*!
 * Pusher JavaScript Library v1.7.4
 * http://pusherapp.com/
 *
 * Copyright 2010, New Bamboo
 * Released under the MIT licence.
 */

if(typeof Function.prototype.scopedTo=="undefined")Function.prototype.scopedTo=function(a,b){var c=this;return function(){return c.apply(a,Array.prototype.slice.call(b||[]).concat(Array.prototype.slice.call(arguments)))}};
var Pusher=function(a,b){this.options=b||{};this.path="/app/"+a+"?client=js&version="+Pusher.VERSION;this.key=a;this.channels=new Pusher.Channels;this.global_channel=new Pusher.Channel("pusher_global_channel");this.global_channel.global=true;this.connected=this.secure=false;this.retry_counter=0;this.encrypted=this.options.encrypted?true:false;Pusher.isReady&&this.connect();Pusher.instances.push(this);this.bind("pusher:connection_established",function(c){this.connected=true;this.retry_counter=0;this.socket_id=
c.socket_id;this.subscribeAll()}.scopedTo(this));this.bind("pusher:connection_disconnected",function(){for(var c in this.channels.channels)this.channels.channels[c].disconnect()}.scopedTo(this));this.bind("pusher:error",function(c){Pusher.log("Pusher : error : "+c.message)})};Pusher.instances=[];
Pusher.prototype={channel:function(a){return this.channels.find(a)},connect:function(){var a=this.encrypted||this.secure?"wss://"+Pusher.host+":"+Pusher.wss_port+this.path:"ws://"+Pusher.host+":"+Pusher.ws_port+this.path;Pusher.allow_reconnect=true;Pusher.log("Pusher : connecting : "+a);var b=this;if(window.WebSocket){var c=new WebSocket(a),d=window.setTimeout(function(){c.close()},2E3+b.retry_counter*1E3);c.onmessage=function(){b.onmessage.apply(b,arguments)};c.onclose=function(){window.clearTimeout(d);
b.onclose.apply(b,arguments)};c.onopen=function(){window.clearTimeout(d);b.onopen.apply(b,arguments)};this.connection=c}else{this.connection={};setTimeout(function(){b.send_local_event("pusher:connection_failed",{})},0)}},toggle_secure:function(){if(this.secure==false){this.secure=true;Pusher.log("Pusher: switching to wss:// connection")}else{this.secure=false;Pusher.log("Pusher: switching to ws:// connection")}},disconnect:function(){Pusher.log("Pusher : disconnecting");Pusher.allow_reconnect=false;
this.retry_counter=0;this.connection.close()},bind:function(a,b){this.global_channel.bind(a,b);return this},bind_all:function(a){this.global_channel.bind_all(a);return this},subscribeAll:function(){for(var a in this.channels.channels)this.channels.channels.hasOwnProperty(a)&&this.subscribe(a)},subscribe:function(a){var b=this.channels.add(a);this.connected&&b.authorize(this,function(c){this.send_event("pusher:subscribe",{channel:a,auth:c.auth,channel_data:c.channel_data})}.scopedTo(this));return b},
unsubscribe:function(a){this.channels.remove(a);this.connected&&this.send_event("pusher:unsubscribe",{channel:a})},send_event:function(a,b){var c=JSON.stringify({event:a,data:b});Pusher.log("Pusher : sending event : ",c);this.connection.send(c);return this},send_local_event:function(a,b,c){b=Pusher.data_decorator(a,b);if(c){var d=this.channel(c);d&&d.dispatch_with_all(a,b)}this.global_channel.dispatch_with_all(a,b);Pusher.log("Pusher : event received : channel: "+c+"; event: "+a,b)},onmessage:function(a){a=
Pusher.parser(a.data);if(!(a.socket_id&&a.socket_id==this.socket_id)){var b=a.event,c=a.data,d=a.channel;if(typeof c=="string")c=Pusher.parser(a.data);this.send_local_event(b,c,d)}},reconnect:function(){var a=this;setTimeout(function(){a.connect()},0)},retry_connect:function(){this.encrypted||this.toggle_secure();var a=Math.min(this.retry_counter*1E3,1E4);Pusher.log("Pusher: Retrying connection in "+a+"ms");var b=this;setTimeout(function(){b.connect()},a);this.retry_counter+=1},onclose:function(){this.global_channel.dispatch("close",
null);Pusher.log("Pusher: Socket closed");if(this.connected){this.send_local_event("pusher:connection_disconnected",{});if(Pusher.allow_reconnect){Pusher.log("Pusher : Connection broken, trying to reconnect");this.reconnect()}}else{this.send_local_event("pusher:connection_failed",{});this.retry_connect()}this.connected=false},onopen:function(){this.global_channel.dispatch("open",null)}};Pusher.Util={extend:function(a,b){for(var c in b)a[c]=b[c];return a}};Pusher.VERSION="1.7.4";Pusher.host="ws.pusherapp.com";
Pusher.ws_port=80;Pusher.wss_port=443;Pusher.channel_auth_endpoint="/pusher/auth";Pusher.log=function(){};Pusher.data_decorator=function(a,b){return b};Pusher.allow_reconnect=true;Pusher.channel_auth_transport="ajax";Pusher.parser=function(a){try{return JSON.parse(a)}catch(b){Pusher.log("Pusher : data attribute not valid JSON - you may wish to implement your own Pusher.parser");return a}};Pusher.isReady=false;
Pusher.ready=function(){Pusher.isReady=true;for(var a=0;a<Pusher.instances.length;a++)Pusher.instances[a].connected||Pusher.instances[a].connect()};Pusher.Channels=function(){this.channels={}};Pusher.Channels.prototype={add:function(a){var b=this.find(a);if(b)return b;else{b=Pusher.Channel.factory(a);return this.channels[a]=b}},find:function(a){return this.channels[a]},remove:function(a){delete this.channels[a]}};
Pusher.Channel=function(a){this.name=a;this.callbacks={};this.global_callbacks=[];this.subscribed=false};
Pusher.Channel.prototype={init:function(){},disconnect:function(){},acknowledge_subscription:function(){this.subscribed=true},bind:function(a,b){this.callbacks[a]=this.callbacks[a]||[];this.callbacks[a].push(b);return this},bind_all:function(a){this.global_callbacks.push(a);return this},dispatch_with_all:function(a,b){this.dispatch(a,b);this.dispatch_global_callbacks(a,b)},dispatch:function(a,b){var c=this.callbacks[a];if(c)for(var d=0;d<c.length;d++)c[d](b);else this.global||Pusher.log("Pusher : No callbacks for "+
a)},dispatch_global_callbacks:function(a,b){for(var c=0;c<this.global_callbacks.length;c++)this.global_callbacks[c](a,b)},is_private:function(){return false},is_presence:function(){return false},authorize:function(a,b){b({})}};Pusher.auth_callbacks={};
Pusher.authorizers={ajax:function(a,b){var c=window.XMLHttpRequest?new XMLHttpRequest:new ActiveXObject("Microsoft.XMLHTTP");c.open("POST",Pusher.channel_auth_endpoint,true);c.setRequestHeader("Content-Type","application/x-www-form-urlencoded");c.setRequestHeader("X-CSRF-Token", Pusher.csrf_token);c.onreadystatechange=function(){if(c.readyState==4)if(c.status==200){var d=Pusher.parser(c.responseText);b(d)}else Pusher.log("Couldn't get auth info from your webapp"+status)};c.send("socket_id="+encodeURIComponent(a.socket_id)+"&channel_name="+encodeURIComponent(this.name))},
jsonp:function(a,b){var c="socket_id="+encodeURIComponent(a.socket_id)+"&channel_name="+encodeURIComponent(this.name),d=document.createElement("script");Pusher.auth_callbacks[this.name]=b;d.src=Pusher.channel_auth_endpoint+"?callback="+encodeURIComponent("Pusher.auth_callbacks['"+this.name+"']")+"&"+c;c=document.getElementsByTagName("head")[0]||document.documentElement;c.insertBefore(d,c.firstChild)}};
Pusher.Channel.PrivateChannel={is_private:function(){return true},authorize:function(a,b){Pusher.authorizers[Pusher.channel_auth_transport].scopedTo(this)(a,b)}};
Pusher.Channel.PresenceChannel={init:function(){this.bind("pusher_internal:subscription_succeeded",function(a){this.acknowledge_subscription(a);this.dispatch_with_all("pusher:subscription_succeeded",this.members())}.scopedTo(this));this.bind("pusher_internal:member_added",function(a){this.track_member(a,1);if(this.member_exists(a))return false;this.add_member(a);this.dispatch_with_all("pusher:member_added",a)}.scopedTo(this));this.bind("pusher_internal:member_removed",function(a){this.track_member(a,
-1);if(this._members_count[a.user_id]>0)return false;this.remove_member(a);this.dispatch_with_all("pusher:member_removed",a)}.scopedTo(this))},disconnect:function(){this._members_map={};this._members_count={}},acknowledge_subscription:function(a){this._members_map={};this._members_count={};for(var b=0;b<a.length;b++){this._members_map[a[b].user_id]=a[b];this.track_member(a[b],1)}this.subscribed=true},track_member:function(a,b){this._members_count[a.user_id]=this._members_count[a.user_id]||0;this._members_count[a.user_id]+=
b;return this},member_exists:function(a){return typeof this._members_map[a.user_id]!="undefined"},is_presence:function(){return true},members:function(){var a=[],b;for(b in this._members_map)a.push(this._members_map[b]);return a},add_member:function(a){this._members_map[a.user_id]=a},remove_member:function(a){delete this._members_map[a.user_id]}};
Pusher.Channel.factory=function(a){var b=new Pusher.Channel(a);if(a.indexOf(Pusher.Channel.private_prefix)===0)Pusher.Util.extend(b,Pusher.Channel.PrivateChannel);else if(a.indexOf(Pusher.Channel.presence_prefix)===0){Pusher.Util.extend(b,Pusher.Channel.PrivateChannel);Pusher.Util.extend(b,Pusher.Channel.PresenceChannel)}b.init();return b};Pusher.Channel.private_prefix="private-";Pusher.Channel.presence_prefix="presence-";WEB_SOCKET_SWF_LOCATION="http://js.pusherapp.com/1.7.4/WebSocketMain.swf";
var _require=function(){var a;a=document.addEventListener?function(b,c){b.addEventListener("load",c,false)}:function(b,c){b.attachEvent("onreadystatechange",function(){if(b.readyState=="loaded"||b.readyState=="complete")c()})};return function(b,c){function d(j,f){f=f||function(){};var k=document.getElementsByTagName("head")[0],e=document.createElement("script");e.setAttribute("src",j);e.setAttribute("type","text/javascript");e.setAttribute("async",true);a(e,function(){var l=f;h++;i==h&&setTimeout(l,
0)});k.appendChild(e)}for(var h=0,i=b.length,g=0;g<i;g++)d(b[g],c)}}();
(function(){var a=[],b=function(){Pusher.ready()};window.JSON==undefined&&a.push("http://js.pusherapp.com/1.7.4/json2.min.js");if(window.WebSocket==undefined){window.WEB_SOCKET_DISABLE_AUTO_INITIALIZATION=true;a.push("http://js.pusherapp.com/1.7.4/flashfallback.min.js");b=function(){FABridge.addInitializationCallback("webSocket",function(){Pusher.ready()});window.WebSocket?WebSocket.__initialize():Pusher.log("Pusher : Could not connect : WebSocket is not availabe natively or via Flash")}}a.length>0?
_require(a,b):b()})();
