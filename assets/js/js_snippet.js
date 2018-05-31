import socket from "./socket";
import $ from 'jquery';


let addMessage = (messages_list_elem, author_name, content, sent_at, current_user_name) => {
    $(messages_list_elem).append(message_html(author_name, content, sent_at, current_user_name));
    $(messages_list_elem).prop({scrollTop: messages_list_elem.prop("scrollHeight")});
    if(author_name !== current_user_name){
        sendNotification(`${author_name}: ${content}`);
    }
};


let addMessageTop = (messages_list_elem, author_name, content, sent_at, current_user_name) => {
    $(messages_list_elem).prepend(message_html(author_name, content, sent_at, current_user_name));
};

let sendNotification = (message) => {
    if(Notification.permission === 'granted') {
        new Notification(message);
    }
};



let message_html = (author_name, content, sent_at, current_user_name) => {
    let current_user_class = author_name == current_user_name ? 'plange--chat-current-user-message' : '';
    return `
    <div class='plange--chat-message ${current_user_class}' data-message-sent-at='${sent_at}'>
            <dt class='plange--chat-author-wrapper'>
            <span class='plange--chat-author-name'>${author_name}</span><span class='plange--chat-message-separator'>: </span></dt>
            <dd class='plange--chat-message-content' >${content}</dd>
    </div>
    `;
};

let sendMessage = (message_field, channel) => {
    channel.push('new_message', { message: message_field.val() });
    message_field.val('');
}

let callWithBottomFixedVscroll = (elem, func) => {
    let current_scroll_pos = $(elem).prop('scrollHeight') - $(elem).scrollTop();
    func();
    $(elem).prop({scrollTop: $(elem).prop('scrollHeight') - current_scroll_pos});
}

class Plange {
    constructor(options) {
        this.current_user_id_hmac = options.current_user_id_hmac;
        this.current_user_name = options.current_user_name;
        this.current_user_name_hmac = options.current_user_name_hmac; // Optional; name will be auto-updated if set.
        this.current_user_id = options.current_user_id;
        this.app_id = options.app_id;
        this.debug = options.debug || false;

        if("Notification" in window){
            Notification.requestPermission(permission => {
                if(permission === "granted"){
                    new Notification("Chat Notifications are now enabled!");
                }
            });
        }
    }

    createCommuncationSection (chat_container_elem, conversation_id, conversation_id_hmac) {
        let container = $(chat_container_elem);
        // console.log(container);
        container.html(
            `<div class='plange--chat-container'>
                <dl class='plange--chat-messages'>
                </dl>
                <div class='plange--new-message-form'>
                    <div class='plange--new-message-field-wrapper'>
                        <input type='text' placeholder='${this.current_user_name}: Type your message here' name='plange--new-message-field' class='plange--new-message-field'/>
                    </div>
                    <button class='plange--new-message-submit-button'>Send</button>
                </div>
            </div>`
        );
        let messages_list_elem    = $('.plange--chat-messages', container);
        // console.log(messages_list_elem);
        let opts = {
            app_id: this.app_id,
            remote_user_id: this.current_user_id,
            remote_user_id_hmac: this.current_user_id_hmac,
            remote_user_name: this.current_user_name,
            remote_user_name_hmac: this.current_user_name_hmac,
            conversation_id_hmac: conversation_id_hmac
        };
        // console.log(opts);
        let channel = socket.channel("chat:" + btoa(this.app_id) + '#' + btoa(conversation_id), opts);

        channel.on('new_message', payload => {
            if(this.debug)
                console.log("Plange: New Message", payload);
            let author_name = payload.name || "Anonymous";
            addMessage(messages_list_elem, author_name, payload.content, payload.sent_at, this.current_user_name);
        });

        let loading_new_messages = false;
        channel.on('messages_so_far', payload => {
            loading_new_messages = false;
            // console.log("Plange: Messages So Far Payload", payload);
            callWithBottomFixedVscroll(messages_list_elem, () => {
                payload.messages.forEach(message => {
                    let author_name = message.name || "Anonymous";
                    addMessageTop($(messages_list_elem), author_name, message.content, message.sent_at, this.current_user_name);
                    if(this.debug)
                        console.log("Loading older message: ", message);
                });
            });
        });

        $(messages_list_elem).on('scroll', event => {
            // console.log($(messages_list_elem).scrollTop(), $(messages_list_elem).innerHeight());
            if($(messages_list_elem).scrollTop() < 50 && !loading_new_messages) {
                loading_new_messages = true;
                channel.push('load_old_messages', { sent_before: $('.plange--chat-message:first', messages_list_elem).data('message-sent-at') });
            };
        });

        $('.plange--new-message-field').prop('disabled', true);
        $('.plange--new-message-submit-button').prop('disabled', true);

        channel.join()
            .receive("ok", resp => {
                $('.plange--new-message-field').prop('disabled', false);
                $('.plange--new-message-submit-button').prop('disabled', false);
                if(this.debug)
                    console.log("Joined Plange communication successfully.", resp);
            })
            .receive("error", resp => {
                if(this.debug)
                    console.log("Unable to join Plange communication: ", resp);
                $('.plange--new-message-field').attr('placeholder', 'Unable to join chat communication. Reason: ' + resp.reason);
            });

        let message_field = $('.plange--new-message-field', container);
        message_field.on('keypress', event => {
            if (event.keyCode == 13) {
                sendMessage(message_field, channel);
            }
        });
        let message_button = $('.plange--new-message-submit-button', container);
        message_button.on('click', event => {
            sendMessage(message_field, channel);
        });
    }
}
// Export to outside world
window.Plange = Plange;
export default Plange;
