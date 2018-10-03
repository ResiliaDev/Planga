// import socket from "./socket";
import {Socket, LongPoll} from 'phoenix';
import $ from 'jquery';

let ensureFieldExists = (options, field_name) => {
    if(!(field_name in options)) {
        throw "Eror: `" + field_name + "` field expected in `options`";
    };
};

let normalizeSocketLocation = (socket_location) => {
    // Absolute path with predefined protocol
    if(socket_location.chatAt(0) !== "/") {
        return socket_location;
    }
    // Always prefer SSL-connections over non-SSL.
    if(socket_location.charAt(1) === "/") {
        return "wss:" + socket_location;
    }
    // Relative path
    return "wss://" + location.host + socket_location;
};

class Planga {
    constructor(chat_container_elem, options) {
        ensureFieldExists(options, "encrypted_options");
        this.encrypted_options = options.encrypted_options;

        ensureFieldExists(options, "public_api_id");
        this.public_api_id = options.public_api_id;
        this.current_user_name = null;

        this.debug = options.debug || false;
        this.socket_location = normalizeSocketLocation(options.socket_location || "https://chat.planga.io/socket");
        this.notifications_enabled_message = options.notifications_enabled_message || "Chat Notifications are now enabled!";

        this.socket = new Socket(this.socket_location, {params: {}});
        this.socket.connect();

        if("Notification" in window){
            Notification.requestPermission(permission => {
                if(permission === "granted"){
                    new Notification(this.notifications_enabled_message);
                }
            });
        }

        this.createCommunicationSection(chat_container_elem);
    }

    disableChatInterface (container, reason) {
        $('.planga--new-message-field').prop('disabled', true);
        $('.planga--new-message-submit-button').prop('disabled', true);
        $('.planga--new-message-field').attr('placeholder', 'Unable to connect to Planga Chat: ' + reason);
    }

    enableChatInterface (container) {
        $('.planga--new-message-field').prop('disabled', false);
        $('.planga--new-message-submit-button').prop('disabled', false);
        $('.planga--new-message-field').attr('placeholder', this.inputPlaceholder(this.current_user_name) );
    }


    createCommunicationSection (chat_container_elem) {
        let container = $(chat_container_elem);
        container.html(this.containerHTML(this.current_user_name));
        let messages_list_elem    = $('.planga--chat-messages', container);
        let channel_opts = {};
        let channel_name = "encrypted_chat:" + btoa(this.public_api_id) + '#' + btoa(this.encrypted_options);
        let channel = this.socket.channel(channel_name, channel_opts);

        this.disableChatInterface(container, "Connecting...");
        this.socket.onError(() => this.disableChatInterface(container, "Could not connect to server"));
        this.socket.onClose(() => this.disableChatInterface(container, "No connection to the internet?" ));
        channel.onError(() => this.disableChatInterface(container, "Could not connect to server"));
        channel.onClose(() => this.disableChatInterface(container, "No connection to the internet?" ));

        channel.on('new_remote_message', message => {
            if(this.debug)
                console.log("Planga: New Message", message);
            let author_name = message.name || "Anonymous";
            this.addMessage(messages_list_elem, message.uuid, author_name, message.content, message.sent_at, this.current_user_name);
        });

        let loading_new_messages = false;
        channel.on('messages_so_far', payload => {
            loading_new_messages = false;
            this.callWithBottomFixedVscroll(messages_list_elem, () => {
                payload.messages.forEach(message => {
                    let author_name = message.name || "Anonymous";
                    this.addMessageTop($(messages_list_elem), message.uuid, author_name, message.content, message.sent_at, this.current_user_name);
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


        channel.join()
            .receive("ok", resp => {
                this.current_user_name = resp.current_user_name || null;
                $('.planga--new-message-field').prop('disabled', false).attr('placeholder', this.inputPlaceholder(this.current_user_name));
                $('.planga--new-message-submit-button').prop('disabled', false);
                if(this.debug)
                    console.log("Joined Planga communication successfully.", resp);
            })
            .receive("error", resp => {
                if(this.debug)
                    console.log("Unable to join Planga communication: ", resp);
                this.disableChatInterface(container, resp);
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

        this.enableChatInterface(container);
    }

    containerHTML () {
        return `<div class='planga--chat-container'>
                <dl class='planga--chat-messages'>
                </dl>
                <div class='planga--new-message-form'>
                    <div class='planga--new-message-field-wrapper'>
                        <input type='text' maxlength='4096' placeholder='${this.inputPlaceholder()}' name='planga--new-message-field' class='planga--new-message-field'/>
                    </div>
                    <button class='planga--new-message-submit-button'>Send</button>
                </div>
            </div>`;
    }

    inputPlaceholder (current_user_name) {
        if(!current_user_name) {
            return `Type your message here`;
        }
        return `${current_user_name}: Type your message here`;
    }


    addMessage (messages_list_elem, uuid, author_name, content, sent_at, current_user_name) {
        const new_message = this.messageHTML(uuid, author_name, content, sent_at, current_user_name);
        let stale_message = $(`.planga--chat-message[data-message-uuid="${uuid}"]`, messages_list_elem);
        if(stale_message.length > 0) {
            $(stale_message).replaceWith(new_message);
        } else {
            $(messages_list_elem).append(new_message);
            $(messages_list_elem).prop({scrollTop: messages_list_elem.prop("scrollHeight")});
            if(author_name !== current_user_name){
                this.sendNotification(this.notificationHTML(author_name, content, sent_at, current_user_name));
            }
        }
    };


    addMessageTop (messages_list_elem, uuid, author_name, content, sent_at, current_user_name) {
        const new_message = this.messageHTML(uuid, author_name, content, sent_at, current_user_name);
        let stale_message = $(`.planga--chat-message[data-message-uuid="${uuid}"]`, messages_list_elem);
        if(stale_message.length > 0) {
            $(stale_message).replaceWith(new_message);
        } else {
            $(messages_list_elem).prepend(new_message);
        }
    };

    sendNotification (message) {
        if(Notification.permission === 'granted') {
            new Notification(message);
        }
    };



    messageHTML (uuid, author_name, content, sent_at, current_user_name) {
        let current_user_class = author_name == current_user_name ? 'planga--chat-current-user-message' : '';
        return `
    <div class='planga--chat-message ${current_user_class}' data-message-sent-at='${sent_at}' data-message-uuid='${uuid || "failure"}' >
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
