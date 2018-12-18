defmodule Planga.EventReducer do
  def dispatch() do
  end

  @spec reducer(structure, event :: TeaVent.Event.t()) :: {:ok, structure} | {:error, failure}
        when structure: any
  def reducer(structure, event)

  def reducer(_, %Event{
        topic: [:app_id, app_id, :conversation, conversation_id],
        name: :new_message,
        meta: %{creator: conversation_user},
        data: data
      }) do
    case Planga.Chat.Message.valid?(data.message) do
      false ->
        {:error, "Invalid Message"}

      true ->
        {:ok,
         Planga.Chat.Message.new(
           data.message,
           conversation_id,
           conversation_user.user_id,
           conversation_user.id
         )}
    end
  end

  def reducer(message, %Event{
        topic: [:app_id, app_id, :conversation, conversation_id, :messages, _message_id],
        name: :hide,
        meta: %{creator: conversation_user}
      }) do
    case Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        {:ok, Planga.Chat.Message.hide_message(message)}
    end
  end

  def reducer(message, %Event{
        topic: [:app_id, app_id, :conversation, conversation_id, :messages, _message_id],
        name: :show,
        meta: %{creator: conversation_user}
      }) do
    case Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        {:ok, Planga.Chat.Message.show_message(message)}
    end
  end
end
