// import socket from "./socket";
import {Socket, LongPoll} from 'phoenix';
import $ from 'jquery';

let ensureFieldExists = (options, field_name) => {
    console.log(options, field_name);
    if(!(field_name in options)) {
        throw "Eror: `" + field_name + "` field expected in `options`";
    };
};

class Planga {
    constructor(options) {
        ensureFieldExists(options, "current_user_id");
        this.current_user_id = options.current_user_id;

        ensureFieldExists(options, "current_user_id_hmac");
        this.current_user_id_hmac = options.current_user_id_hmac;

        ensureFieldExists(options, "current_user_name");
        this.current_user_name = options.current_user_name;
        this.current_user_name_hmac = options.current_user_name_hmac; // Optional; name will be auto-updated if set.

        ensureFieldExists(options, "app_id");
        this.app_id = options.app_id;
        this.debug = options.debug || false;
        this.socket_location = options.socket_location || "http://planga.io/socket";
        this.notifications_enabled_message = options.notifications_enabled_message || "Chat Notifications are now enabled!";


        this.socket = new Socket(this.socket_location, {params: {}/*, transport: LongPoll */});
        this.socket.connect();

        if("Notification" in window){
            Notification.requestPermission(permission => {
                if(permission === "granted"){
                    new Notification(this.notifications_enabled_message);
                }
            });
        }
    }

    createCommuncationSection (chat_container_elem, conversation_id, conversation_id_hmac) {
        let container = $(chat_container_elem);
        container.html(this.containerHTML(this.current_user_name));
        let messages_list_elem    = $('.planga--chat-messages', container);
        let opts = {
            app_id: this.app_id,
            remote_user_id: this.current_user_id,
            remote_user_id_hmac: this.current_user_id_hmac,
            remote_user_name: this.current_user_name,
            remote_user_name_hmac: this.current_user_name_hmac,
            conversation_id_hmac: conversation_id_hmac
        };
        let channel = this.socket.channel("chat:" + btoa(this.app_id) + '#' + btoa(conversation_id), opts);

        channel.on('new_message', payload => {
            if(this.debug)
                console.log("Planga: New Message", payload);
            let author_name = payload.name || "Anonymous";
            this.addMessage(messages_list_elem, author_name, payload.content, payload.sent_at, this.current_user_name);
        });

        let loading_new_messages = false;
        channel.on('messages_so_far', payload => {
            loading_new_messages = false;
            this.callWithBottomFixedVscroll(messages_list_elem, () => {
                payload.messages.forEach(message => {
                    let author_name = message.name || "Anonymous";
                    this.addMessageTop($(messages_list_elem), author_name, message.content, message.sent_at, this.current_user_name);
                    if(this.debug)
                        console.log("Loading older message: ", message);
                });
            });
        });

        $(messages_list_elem).on('scroll', event => {
            if($(messages_list_elem).scrollTop() < 50 && !loading_new_messages) {
                loading_new_messages = true;
                channel.push('load_old_messages', { sent_before: $('.planga--chat-message:first', messages_list_elem).data('message-sent-at') });
            };
        });

        $('.planga--new-message-field').prop('disabled', true);
        $('.planga--new-message-submit-button').prop('disabled', true);

        channel.join()
            .receive("ok", resp => {
                $('.planga--new-message-field').prop('disabled', false);
                $('.planga--new-message-submit-button').prop('disabled', false);
                if(this.debug)
                    console.log("Joined Planga communication successfully.", resp);
            })
            .receive("error", resp => {
                if(this.debug)
                    console.log("Unable to join Planga communication: ", resp);
                $('.planga--new-message-field').attr('placeholder', 'Unable to join chat communication. Reason: ' + resp.reason);
            });

        let message_field = $('.planga--new-message-field', container);
        message_field.on('keypress', event => {
            if (event.keyCode == 13) {
                this.sendMessage(message_field, channel);
            }
        });
        let message_button = $('.planga--new-message-submit-button', container);
        message_button.on('click', event => {
            this.sendMessage(message_field, channel);
        });
    }

    containerHTML (current_user_name) {
        return `<div class='planga--chat-container'>
                <dl class='planga--chat-messages'>
                </dl>
                <div class='planga--new-message-form'>
                    <div class='planga--new-message-field-wrapper'>
                        <input type='text' placeholder='${current_user_name}: Type your message here' name='planga--new-message-field' class='planga--new-message-field'/>
                    </div>
                    <button class='planga--new-message-submit-button'>Send</button>
                </div>
            </div>`;
    }


    addMessage (messages_list_elem, author_name, content, sent_at, current_user_name) {
        $(messages_list_elem).append(this.messageHTML(author_name, content, sent_at, current_user_name));
        $(messages_list_elem).prop({scrollTop: messages_list_elem.prop("scrollHeight")});
        if(author_name !== current_user_name){
            this.sendNotification(this.notificationHTML(author_name, content, sent_at, current_user_name));
        }
    };


    addMessageTop (messages_list_elem, author_name, content, sent_at, current_user_name) {
        $(messages_list_elem).prepend(this.messageHTML(author_name, content, sent_at, current_user_name));
    };

    sendNotification (message) {
        if(Notification.permission === 'granted') {
            new Notification(message);
        }
    };



    messageHTML (author_name, content, sent_at, current_user_name) {
        let current_user_class = author_name == current_user_name ? 'planga--chat-current-user-message' : '';
        return `
    <div class='planga--chat-message ${current_user_class}' data-message-sent-at='${sent_at}'>
            <div class='planga--chat-message-sent-at-wrapper'>
                <span class='planga--chat-message-sent-at' title='${this.styledDateTime(sent_at)}'>${this.styledTime(sent_at)}</span>
            </div>
            <div class='planga--chat-author-wrapper'>
                <span class='planga--chat-author-name'>${author_name}</span><span class='planga--chat-message-separator'>: </span>
            </div>
            <div class='planga--chat-message-content' >${content}</div>
    </div>
    `;
    };

    styledTime (sent_at) {
        return new Date(sent_at).toLocaleTimeString();
    };

    styledDateTime (sent_at) {
        return new Date(sent_at).toLocaleString();
    };


    notificationHTML (author_name, content, sent_at, current_user_name) {
        return `${author_name}: ${content}`;
    };

    sendMessage (message_field, channel) {
        channel.push('new_message', { message: message_field.val() });
        message_field.val('');
    };

    callWithBottomFixedVscroll (elem, func) {
        let current_scroll_pos = $(elem).prop('scrollHeight') - $(elem).scrollTop();
        func();
        $(elem).prop({scrollTop: $(elem).prop('scrollHeight') - current_scroll_pos});
    };
}
// Export to outside world
window.Planga = Planga;
export default Planga;
