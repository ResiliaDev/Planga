import re
import json
import uuid
from jwcrypto import jwk, jwe

class Planga(object):
    @staticmethod
    def get_planga_snippet(configuration):
        return """
        <script type="text/javascript" src="{}/js/js_snippet.js"></script>
        <div id="{}"></div>
            <script type="text/javascript" >
                new Planga(document.getElementById("{}"), {{
                    public_api_id: "{}",
                    encrypted_options: "{}",
                    socket_location: "{}/socket",
                }});
            </script>
        """.format(
            configuration.remote_host,
            configuration.container_id,
            configuration.container_id,
            configuration.public_api_id,
            Planga._encrypt_options(configuration),
            configuration.remote_host
        )

    ## Private Methods ##

    @staticmethod
    def _encrypt_options(configuration):
        key = jwk.JWK(k=configuration.private_api_key, kty="oct")
        protected = {"alg": "A128GCMKW", "enc": "A128GCM"}
        
        payload = json.dumps({
                "conversation_id": configuration.conversation_id,
                "current_user_id": configuration.current_user_id,
                "current_user_name": configuration.current_user_name
            }) 
        
        encryption = jwe.JWE(payload, json.dumps(protected))
        encryption.add_recipient(key)
        return encryption.serialize(compact=True)

class PlangaConfiguration(object):
    def __init__(self, public_api_id=None, private_api_key=None, conversation_id=None,
        current_user_id=None, current_user_name=None, container_id=None):

        self.public_api_id = public_api_id
        self.private_api_key = private_api_key
        self.conversation_id = conversation_id
        self.current_user_id = current_user_id
        self.current_user_name = current_user_name
        self.container_id = container_id
        self.remote_host = "//planga.def"

        if not container_id:
            self.container_id = "planga-chat-" + str(uuid.uuid4()) 

    def is_valid(self):
        return self._is_alpha(self.public_api_id) and self._is_alpha(self.private_api_key)

    ### Private Methods ###

    def _is_alpha(self, string):
        return re.match(r"^[a-zA-Z]+$", string) != None