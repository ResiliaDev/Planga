import socket from "./socket";


let addMessage = (messages_list_elem, author_name, message) => {
    $(messages_list_elem).append(`<p class='plange--chat-message'><b class='plange--chat-author'>${author_name}:</b> <em class='plange--chat-message-content' >${message}</em></p>`);
    $(messages_list_elem).prop({scrollTop: messages_list_elem.prop("scrollHeight")});
};

class Plange {
    constructor(options) {
        this.current_user_hmac = options.current_user_hmac;
        this.current_user_id = options.current_user_id;
        this.app_id = options.app_id;
    }

    createCommuncationSection (chat_container_elem, channel_id, channel_id_hmac) {
        let container = $(chat_container_elem);
        container.html(
            `<div class='plange--chat-container'>
                <div class='plange--chat-messages'>
                </div>
                <div class='plange--message-form'>
                    <div class='plange--new-message-field-wrapper'>
                        <input type='text' name='plange--new-message-field' class='plange--new-message-field'/>
                    </div>
                    <button class='plange--new-message-submit-button>Send</button>
                </div>
            </div>`
        );
        let messages_list_elem    = $('plange--chat-messages', container);
        console.log(messages_list_elem);
        let channel = socket.channel("chat:"+channel_id, {
            app_id: this.app_id,
            remote_user_id: this.current_user_id,
            remote_user_id_hmac: this.current_user_hmac,
            channel_id_hmac: channel_id_hmac
        });

        channel.on('new_message', payload => {
            console.log("Plange: New Message", payload);
            let author_name = payload.name || "Anonymous";
            addMessage(messages_list_elem, author_name, payload.message);
        });

        channel.on('messages_so_far', payload => {
            console.log("Plange: Messages So Far Payload", payload);
            messages_list_elem.innerHTML = '';
            payload.messages.forEach(message => {
                let author_name = message.name || "Anonymous";
                addMessage($(messages_list_elem), author_name, message.message);
            });
        });

        channel.join()
            .receive("ok", resp => {
                console.log("Joined Plange communication successfully.", resp);
            })
            .receive("error", resp => {
                console.log("Unable to join Plange communication: ", resp);
            });

        let message = $('#message');
        message.on('keypress', event => {
            if (event.keyCode == 13) {
                channel.push('new_message', { message: message.val() });
                message.val('');
            }
        });
    }
}
// Export to outside world
window.Plange = Plange;

// Usage Example:
$(function(){
    let app_id = '1';
    let channel_id = "asdf";
    let messages_list_elem    = $('#message-list');
    let message = $('#message');
    // let name    = $('#name');
    let remote_user_id = '1234';
    let remote_user_id_hmac = "5ZS5CUUX7eg3/nNw7TevR6PyUfEMrtPRN/V7s7JhdTw="; // Based on API key 'topsecret' for app id '1', with HMAC message '1234' (the user's remote ID)

    let plange = new Plange({app_id: '1', current_user_id: '1234', current_user_hmac: remote_user_id_hmac});
    plange.createCommuncationSection($("#message-messages_list_elem"), "asdf");

});

window.Plange = Plange;
