# Planga

Planga is the Chat-Service that is very easy to integrate with your existing application!

It is currently in a relatively early alpha-stage; check back soon for more information.

# Table of Contents

<!--ts-->
   * [Planga](#planga)
   * [Table of Contents](#table-of-contents)
   * [Using Planga](#using-planga)
      * [Back-end setup](#back-end-setup)
         * [What should I use for conversation_id?](#what-should-i-use-for-conversation_id)
         * [What is a SHA256-HMAC?](#what-is-a-sha256-hmac)
         * [How do I compute a SHA256-HMAC?](#how-do-i-compute-a-sha256-hmac)
            * [Ruby:](#ruby)
            * [PHP:](#php)
            * [NodeJS:](#nodejs)
            * [Elixir:](#elixir)
            * [Python2](#python2)
            * [Python3](#python3)
      * [Front-end setup](#front-end-setup)
         * [Example:](#example)
   * [Running Planga Yourself](#running-planga-yourself)

<!-- Added by: qqwy, at: 2018-07-13T17:21+02:00 -->

<!--te-->

# Using Planga

_This documentation is a work-in-progress!_

## Back-end setup

1. Compute some information that Planga needs: 
  - `user_id`: The identifier of the currently logged-in user. Can be any string that uniquely identifies a user.
  - `user_id_hmac`: The SHA256-HMAC of the `user_id`, using your API-key for signing.
  - The `conversation_id` of the conversation the user can interact with. Can be any string that uniquely identifies a conversation.
  - `conversation_id_hmac`: The SHA256-HMAC of the `conversation_id`, using your API-key for signing.
2. Send/output that information in a way that your front-end JavaScript can access it.
  
### What should I use for `conversation_id`?

For conversations that all users are allowed to be part of, it is simple: Just use a string like `"general"` for a general chat channel.

For private conversations between two users, it makes sense to take the two user_ids, sort them (so it does not matter which one is 'first'), and then concatenate them, prefixing them with a common string to indicate the kind of channel:

Say we have the users `Alice` with user_id `12` and `Bob` with user_id `42`, then their private conversation_id might be `private/12/42`.


_Tl;Dr: Planga does not restrict you at all in choosing conversation identifiers, so choose something that makes sense for your application!_
  
### What is a SHA256-HMAC?

These are used to make the application secure: They ensure that your back-end:
- that the current user exists and is the specifically listed user.
- that the current user is allowed to connect to the given conversation.

### How do I compute a SHA256-HMAC?

This is a very common thing to do.
Planga expects the SHA256-HMAC to be in hexadecimal (also known as hexdigest) format.

Here are a couple of programming language examples:

_For other languages, see [these more in-depth hmac-examples](https://github.com/danharper/hmac-examples)_

#### Ruby:

```ruby
require 'openssl'

user_id_hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), "YOUR_API_KEY", user_id)
conversation_id_hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), "YOUR_API_KEY", conversation_id)
```

#### PHP:

```php
$user_id_hmac = hash_hmac("sha256", $user_id, "YOUR_API_KEY")
$conversation_id_hmac = hash_hmac("sha256", $conversation_id, "YOUR_API_KEY")
```

#### NodeJS:

```nodejs
const crypto = require("crypto")

let user_id_hmac = crypto.createHmac("SHA256", "YOUR_API_KEY").update(user_id).digest("hex");
let conversation_id_hmac = crypto.createHmac("SHA256", "YOUR_API_KEY").update(conversation_id).digest("hex");
```

#### Elixir:

```elixir
user_id_hmac = 
  :crypto.hmac(:sha256, "YOUR_API_KEY", user_id) 
  |> Base.encode16


conversation_id_hmac = 
  :crypto.hmac(:sha256, "YOUR_API_KEY", conversation_id) 
  |> Base.encode16
```

#### Python2

```python2
import hashlib
import hmac

user_id_hmac = hmac.new(bytes('YOUR_API_KEY').encode('utf-8'), bytes(user_id).encode('utf-8'), hashlib.sha256).hexdigest()
conversation_id_hmac = hmac.new(bytes('YOUR_API_KEY').encode('utf-8'), bytes(conversation_id).encode('utf-8'), hashlib.sha256).hexdigest()
```

#### Python3


```python3
import hashlib
import hmac

user_id_hmac = hmac.new(bytes('YOUR_API_KEY', 'utf-8'), bytes(user_id, 'utf-8'), hashlib.sha256).hexdigest()
conversation_id_hmac = hmac.new(bytes('YOUR_API_KEY', 'utf-8'), bytes(conversation_id, 'utf-8'), hashlib.sha256).hexdigest()
```


## Front-end setup

1. Add a script-tag to your application, loading the Planga JS-snippet.
2. Add an HTML-element somewhere in your document that you want the chat interface to be contained in.
3. In JavaScript, create a new `Planga` object, passing any options you'd want to create the current conversation(s):
  - These options contain the information the back-end sent to the front-end:
    - `current_user_id`
    - `current_user_id_hmac`
    - `conversation_id`
    - `conversation_id_hmac`
  - And the following extra options:
    - `app_id`: Unique Identifier that Planga assigns to your account. This is public information.
  - Optionally, you can also send the following extra options:
    - `current_user_name`: This will set the current user's name to the given name. If this was already set earlier, it requires an `current_user_name_hmac` to override the previous value (to prevent abuse).
    - `notifications_enabled_message`: Can be a custom string message that will be shown when the user enables browser notifications.
    - `socket_location`: Required only if you host the application somewhere else.



### Example:

```html
<!-- To be able to use 'Planga', add this to your application: -->
<script src="/js/js_snippet.js" type="text/javascript"></script> 

<!-- The chat-interface will be injected in this div element: -->
<div id='planga-example' class='row'></div>

<!-- The chat-interface will be created using the following JavaScript snippet: -->
<script type="text/javascript" >
 // Usage Example:
 window.onload = function(){
     let messages_list_elem = document.getElementById('planga-example');

     let app_id = '1';
     let conversation_id = "asdf";
     let conversation_id_hmac = "Syv/GTCGSFSYtRVKxq7ECm2/M320i2Dby7jOl7+057E=";
     let current_user_id = '1234';
     let current_user_name = 'wm';
     let current_user_id_hmac = "5ZS5CUUX7eg3/nNw7TevR6PyUfEMrtPRN/V7s7JhdTw="; // Based on API key 'topsecret' for app id '1', with HMAC message '1234' (the user's remote ID)

     let planga = new Planga({
         app_id: '1',
         current_user_id: current_user_id,
         current_user_id_hmac: current_user_id_hmac,
         current_user_name: current_user_name,
     });
     planga.createCommuncationSection(messages_list_elem, conversation_id, conversation_id_hmac);
 };
</script>
```


# Running Planga Yourself

1. Copy this repository
2. Install Erlang and Elixir
3. Install Elixir dependencies using `mix deps.get`
4. Create the Mnesia database using `mix do ecto.create, ecto.migrate, run priv/repo/seeds.exs`
5. Run the application using `mix phx.server` or with console using `iex -S mix. phx.server`
