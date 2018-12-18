defmodule Planga.Event.Reducer do
  alias TeaVent.Event

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
        meta: %{creator: conversation_user, started_at: started_at}
      })
      when name in [:hide_message, :show_message] do
    case Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        case name do
          :hide_message ->
            {:ok, Planga.Chat.Message.hide_message(message, started_at)}

          :show_message ->
            {:ok, Planga.Chat.Message.show_message(message)}
        end
    end
  end

  def reducer(subject = %Planga.Chat.ConversationUser{}, %Event{
        topic: [:apps, app_id, :conversations, conversation_id, :users, _remote_user_id],
        name: name,
        meta: %{creator: conversation_user, started_at: started_at},
        data: data
      })
      when name in [:ban, :unban] do
    case Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        case name do
          :ban ->
            {:ok, Planga.Chat.ConversationUser.ban(subject, data.duration_minutes, started_at)}

          :unban ->
            {:ok, Planga.Chat.Message.unban(subject)}
        end
    end
  end

  def reducer(input, %Event{name: :noop}) do
    {:ok, input}
  end
end
