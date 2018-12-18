defmodule Planga.EventReducer do
  alias TeaVent.Event

  def dispatch(topic, name, data \\ %{}, meta \\ %{}, remote_user_id \\ nil, options \\ []) do
    dispatch_event(TeaVent.Event.new(topic, name, data, meta), remote_user_id, options)
  end


  def dispatch_event(event, remote_user_id \\ nil, options \\ []) do
    options =
      options ++
        [
          context_provider: &Planga.EventContextProvider.run/2,
          reducer: &Planga.EventReducer.reducer/2,
          middleware: [&Planga.EventMiddleware.repo_transaction/1]
        ]

    meta = Map.put(event.meta, :remote_user_id, remote_user_id)

    event = %Event{event | meta: meta}
    with {:ok, event} <- TeaVent.dispatch_event(event, options) do
      broadcast_changes(event)
    end
  end


  def broadcast_changes(event) do
    case event.topic do
      [:apps, app_id, :conversations, remote_conversation_id, :messages] ->
        IO.inspect(event, label: "broadcast_changes")
        Planga.Connection.broadcast_new_message!(app_id, remote_conversation_id, event.changed_subject)
      [:apps, app_id, :conversations, remote_conversation_id, :messages, message_id] ->
        Planga.Connection.broadcast_changed_message!(app_id, remote_conversation_id, event.changed_subject)
    end
    {:ok, event}
  end

  @spec reducer(structure, event :: TeaVent.Event.t()) :: {:ok, structure} | {:error, any}
        when structure: any
  def reducer(structure, event)

  def reducer(_, %Event{
        topic: [:apps, app_id, :conversations, conversation_id, :messages],
        name: :new_message,
        meta: %{creator: conversation_user},
        data: data
      }) do
    case Planga.Chat.Message.valid_message?(data.message) do
      false ->
        {:error, "Invalid Message"}

      true ->
        {:ok,
         Planga.Chat.Message.new(
           content: data.message,
           conversation_id: conversation_user.conversation_id,
           sender_id: conversation_user.user_id,
           conversation_user_id: conversation_user.id
         )}
    end
  end

  def reducer(message = %Planga.Chat.Message{}, %Event{
        topic: [:apps, app_id, :conversations, conversation_id, :messages, _message_id],
        name: name,
        meta: %{creator: conversation_user}
      })
  when name in [:hide_message, :show_message] do
    case Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        case name do
          :hide_message ->
            {:ok, Planga.Chat.Message.hide_message(message)}

          :show_message ->
            {:ok, Planga.Chat.Message.show_message(message)}
        end
    end
  end

  def reducer(subject = %Planga.Chat.ConversationUser{}, %Event{
        topic: [:apps, app_id, :conversations, conversation_id, :users, _remote_user_id],
        name: name,
        meta: %{creator: conversation_user}
      })
      when name in [:ban, :unban] do
    case Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        case name do
          :ban ->
            {:ok, Planga.Chat.ConversationUser.ban(subject)}

          :unban ->
            {:ok, Planga.Chat.Message.unban(subject)}
        end
    end
  end

  def reducer(input, %Event{name: :noop}) do
    {:ok, input}
  end
end
