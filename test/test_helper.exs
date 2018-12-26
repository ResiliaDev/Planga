ExUnit.start()

require ExUnitProperties


domains = [
  "gmail.com",
  "hotmail.com",
  "yahoo.com",
]

datetime_generator =
  StreamData.integer()
  |> StreamData.map(&DateTime.from_unix!/1)

pos_integer_generator =
  StreamData.integer
  |> StreamData.map(&Kernel.abs/1)

num_id_generator  =
  pos_integer_generator

remote_id_generator =
  [StreamData.integer, StreamData.string(:alphanumeric)]
  |> StreamData.one_of
  |> StreamData.map(&Kernel.to_string/1)

email_generator =
  ExUnitProperties.gen all name <- StreamData.string(:alphanumeric),
  name != "",
  domain <- StreamData.member_of(domains) do
  name <> "@" <> domain
end

user_generator =
  ExUnitProperties.gen all app_id <- StreamData.integer(),
  remote_user_id <- StreamData.string(:alphanumeric),
  name <- StreamData.string(:alphanumeric) do
  Planga.Chat.User.new(remote_user_id, name)
end

conversation_user_generator =
  ExUnitProperties.gen all  conversation_id <- num_id_generator,
  user_id <- num_id_generator,
  role <- role_generator do
  Planga.Chat.ConversationUser.new(%{
        conversation_id: conversation_id,
        user_id: user_id,
        role: role,
        banned_until: nil
                                   })
end

message_generator =
  ExUnitProperties.gen all  content <- StreamData.string(:printable),
                            content != "",
                            String.length(content) < 1024,
                            sender_id <- num_id_generator,
                            conversation_id <- num_id_generator,
                            conversation_user_id <- num_id_generator,
                            inserted_at <- datetime_generator do
    Planga.Chat.Message.new(%{
          content: content,
          sender_id: sender_id,
          conversation_id: conversation_id,
          conversation_user_id: conversation_user_id,
          inserted_at: inserted_at,
                            })
  end

deleted_message_generator =
  ExUnitProperties.gen all  message <- message_generator,
                            deleted_at <- datetime_generator,
                            deleted_at > message.inserted_at do
    put_in message.deleted_at, deleted_at
  end
