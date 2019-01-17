defmodule Planga.Event.Reducer do
  @moduledoc """
  This module knows/decides how to change the application state based on incooming events.
  """
  alias TeaVent.Event

  @doc """
  Receives the current subject (the 'logical context') for this event as first  parameter, and the event itself as the second parameter.

  Supposed to return `{:ok, updated_subject} | {:error, problem}`
  """
  @spec reducer(structure, event :: TeaVent.Event.t()) :: {:ok, structure} | {:error, any}
        when structure: any
  def reducer(structure, event)

  def reducer(_, %Event{
        topic: [:apps, _app_id, :conversations, _conversation_id, :messages],
        name: :new_message,
        meta: %{creator: conversation_user},
        data: data
      }) do
    if Planga.Chat.ConversationUser.banned?(conversation_user) do
      {:error, "You are not allowed to perform this action"}
    else
    Planga.Chat.Message.new(%{
      content: data.message,
      conversation_id: conversation_user.conversation_id,
      sender_id: conversation_user.user_id,
      conversation_user_id: conversation_user.id
    })
    end
  end

  def reducer(message = %Planga.Chat.Message{}, %Event{
        topic: [:apps, _app_id, :conversations, _conversation_id, :messages, _message_id],
        name: name,
        meta: %{creator: conversation_user, started_at: started_at}
      })
      when name in [:hide_message, :show_message] do
    case is_nil(conversation_user) ||
           Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
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
        topic: [:apps, _app_id, :conversations, _conversation_id, :conversation_users, _remote_user_id],
        name: name,
        meta: %{creator: conversation_user, started_at: started_at},
        data: data
      })
      when name in [:ban, :unban] do
    case is_nil(conversation_user) ||
           Planga.Chat.ConversationUser.is_moderator?(conversation_user) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        case name do
          :ban ->
            {:ok, Planga.Chat.ConversationUser.ban(subject, data.duration_minutes, started_at)}

          :unban ->
            {:ok, Planga.Chat.ConversationUser.unban(subject)}
        end
    end
  end

  def reducer(subject = %Planga.Chat.ConversationUser{}, %Event{
        topic: [:apps, _app_id, :conversations, _conversation_id, :users, _remote_user_id],
        name: :set_role,
        meta: %{creator: creator},
        data: data
      }) do
    case creator == nil || Planga.Chat.ConversationUser.is_moderator?(creator) do
      false ->
        {:error, "You are not allowed to perform this action"}

      true ->
        Planga.Chat.ConversationUser.set_role(subject, data.role)
    end
  end

  def reducer(input, %Event{name: :noop}) do
    {:ok, input}
  end
end
