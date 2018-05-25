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
            app_id: app_id,
            remote_user_id: remote_user_id,
            remote_user_id_hmac: remote_user_id_hmac,
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
    }
}


console.log("PLANGE!");
