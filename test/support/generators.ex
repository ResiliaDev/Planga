defmodule Planga.Test.Support.Generators do
  require ExUnitProperties

  @email_domains [
    "gmail.com",
    "hotmail.com",
    "yahoo.com"
  ]

  def datetime_generator do
    StreamData.integer()
    |> StreamData.map(&DateTime.from_unix!/1)
  end

  def pos_integer_generator do
    StreamData.integer()
    |> StreamData.map(&Kernel.abs/1)
  end

  def num_id_generator do
    pos_integer_generator()
  end

  def remote_id_generator do
    [num_id_generator(), StreamData.string(:alphanumeric, min_length: 1)]
    |> StreamData.one_of()
    |> StreamData.map(&Kernel.to_string/1)
  end

  def email_generator do
    ExUnitProperties.gen all name <- StreamData.string(:alphanumeric),
                             name != "",
                             domain <- StreamData.member_of(@email_domains) do
      name <> "@" <> domain
    end
  end

  def role_generator do
    StreamData.one_of([StreamData.constant(""), StreamData.constant("moderator")])
  end

  def user_generator do
    ExUnitProperties.gen all id <- num_id_generator(),
                             app_id <- num_id_generator(),
                             remote_id <- remote_id_generator(),
                             name <- StreamData.string(:alphanumeric, min_length: 1) do
      {:ok, res} =
        Planga.Chat.User.new(%{
          app_id: app_id,
          remote_id: remote_id,
          name: name
        })

      put_in(res.id, id)
    end
  end

  def app_generator do
    ExUnitProperties.gen all id <- num_id_generator(),
                             name <- StreamData.string(:printable, min_length: 1) do
      {:ok, res} = Planga.Chat.App.new(name: name)

      app = put_in(res.id, id)

      app
    end
  end

  def conversation_generator do
    ExUnitProperties.gen all id <- num_id_generator(),
                             remote_id <- remote_id_generator(),
                             app_id <- num_id_generator() do
      {:ok, res} =
        Planga.Chat.Conversation.new(%{
          app_id: app_id,
          remote_id: remote_id
        })

      put_in(res.id, id)
    end
  end

  def filled_conversation_generator do
    ExUnitProperties.gen all app <- app_generator(),
                             conversation <- conversation_generator() do
      conversation = put_in(conversation.app_id, app.id)
      conversation = put_in(conversation.app, app)

      conversation
    end
  end

  def conversation_user_generator do
    ExUnitProperties.gen all id <- num_id_generator(),
                             conversation_id <- num_id_generator(),
                             user_id <- num_id_generator(),
                             role <- role_generator() do
      {:ok, res} =
        Planga.Chat.ConversationUser.new(%{
          conversation_id: conversation_id,
          user_id: user_id,
          role: role,
          banned_until: nil
        })

      put_in(res.id, id)
    end
  end

  def filled_conversation_user_generator do
    ExUnitProperties.gen all conversation <- filled_conversation_generator(),
                             user <- user_generator(),
                             conversation_user <- conversation_user_generator() do
      conversation_user = put_in(conversation_user.user_id, user.id)
      conversation_user = put_in(conversation_user.user, user)

      conversation_user = put_in(conversation_user.conversation_id, conversation.id)
      conversation_user = put_in(conversation_user.conversation, conversation)

      conversation_user = put_in(conversation_user.user.app_id, conversation.app.id)
      conversation_user = put_in(conversation_user.user.app, conversation.app)

      conversation_user
    end
  end

  def message_generator do
    ExUnitProperties.gen all content <- StreamData.string(:printable),
                             content != "",
                             String.length(content) < 1024,
                             sender_id <- num_id_generator(),
                             conversation_id <- num_id_generator(),
                             conversation_user_id <- num_id_generator(),
                             inserted_at <- datetime_generator() do
      {:ok, res} =
        Planga.Chat.Message.new(%{
          content: content,
          sender_id: sender_id,
          conversation_id: conversation_id,
          conversation_user_id: conversation_user_id,
          inserted_at: inserted_at
        })

      res
    end
  end

  def filled_message_generator do
    ExUnitProperties.gen all conversation_user <- filled_conversation_user_generator(),
                             message <- message_generator() do
      message = put_in(message.conversation_user_id, conversation_user.id)
      message = put_in(message.conversation_user, conversation_user)

      message = put_in(message.conversation_id, conversation_user.conversation.id)
      message = put_in(message.conversation, conversation_user.conversation)

      message = put_in(message.sender_id, conversation_user.user.id)
      message = put_in(message.sender, conversation_user.user)

      message
    end
  end

  def deleted_message_generator do
    ExUnitProperties.gen all message <- message_generator(),
                             deleted_at <- datetime_generator(),
                             deleted_at > message.inserted_at do
      put_in(message.deleted_at, deleted_at)
    end
  end
end
