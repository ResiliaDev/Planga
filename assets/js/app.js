// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket";

console.log("app!");


console.log("PLANGE!");

import socket from "./socket";


class Plange {
    constructor(options) {
        this.current_user_hmac = options.current_user_hmac;
        this.current_user_id = options.current_user_id;
        this.app_id = options.app_id;
    }

    createCommuncationSection (chat_container_elem, channel_id) {
        let list    = $(chat_container_elem);
        let channel = socket.channel("chat:"+channel_id, {
            app_id: this.app_id,
            remote_user_id: this.current_user_id,
            remote_user_id_hmac: this.current_user_hmac,
        });

        channel.on('new_message', payload => {
            console.log("Plange: New Message", payload);
            list.append(`<b>${payload.name || 'Anonymous'}:</b> ${payload.message}<br>`);
            list.prop({scrollTop: list.prop("scrollHeight")});
        });

        channel.on('messages_so_far', payload => {
            console.log("Plange: Messages So Far Payload", payload);
            payload.messages.forEach(message => {
                list.innerHTML='';
                list.append(`<b>${message.name || 'Anonymous'}:</b> ${message.message}<br>`);
                list.prop({scrollTop: list.prop("scrollHeight")});
            });
        });

        channel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp) });

        let message = $('#message');
        message.on('keypress', event => {
            if (event.keyCode == 13) {
                channel.push('new_message', { message: message.val() });
                message.val('');
            }
        });

    }
}


console.log("PLANGE!");

console.log("Bar", window.Plange);

$(function(){
    let app_id = '1';
    let channel_id = "asdf";
    let list    = $('#message-list');
    let message = $('#message');
    // let name    = $('#name');
    let remote_user_id = '1234';
    let remote_user_id_hmac = "5ZS5CUUX7eg3/nNw7TevR6PyUfEMrtPRN/V7s7JhdTw="; // Based on API key 'topsecret' for app id '1', with HMAC message '1234' (the user's remote ID)

    let plange = new Plange({app_id: '1', current_user_id: '1234', current_user_hmac: remote_user_id_hmac});
    plange.createCommuncationSection($("#message-list"), "asdf");

});

// let channel = socket.channel("chat:"+channel_id, {
//     app_id: app_id,
//     remote_user_id: remote_user_id,
//     remote_user_id_hmac: remote_user_id_hmac,
// });

// message.on('keypress', event => {
//     if (event.keyCode == 13) {
//         channel.push('new_message', { message: message.val() });
//         message.val('');
//     }
// });

// channel.on('new_message', payload => {
//     console.log("New Message", payload);
//     list.append(`<b>${payload.name || 'Anonymous'}:</b> ${payload.message}<br>`);
//     list.prop({scrollTop: list.prop("scrollHeight")});
// });

// channel.on('messages_so_far', payload => {
//     console.log("Messages So Far Payload", payload);
//     payload.messages.forEach(message => {
//         list.innerHTML='';
//         list.append(`<b>${message.name || 'Anonymous'}:</b> ${message.message}<br>`);
//         list.prop({scrollTop: list.prop("scrollHeight")});
//     });
// });

// channel.join()
//     .receive("ok", resp => { console.log("Joined successfully", resp) })
//     .receive("error", resp => { console.log("Unable to join", resp) })
