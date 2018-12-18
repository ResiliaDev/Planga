defmodule Planga.EventReducer do
  alias TeaVent.Event

  def dispatch(topic, name, data \\ %{}, meta \\ %{}, options \\ []) do
    dispatch_event(TeaVent.Event.new(topic, name, data, meta), options)
  end

  def dispatch_event(event, options \\ []) do
    options =
      options ++
        [
          context_provider: &Planga.EventContextProvider.run/2,
          reducer: &Planga.EventReducer.reducer/2,
          middleware: [&Planga.EventMiddleware.repo_transaction/1]
        ]

    TeaVent.dispatch_event(event, options)
  end

  @spec reducer(structure, event :: TeaVent.Event.t()) :: {:ok, structure} | {:error, any}
        when structure: any
  def reducer(structure, event)

  def reducer(_, %Event{
        topic: [:app, app_id, :conversation, conversation_id, :messages],
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
           content: data.message,
           conversation_id: conversation_id,
           sender_id: conversation_user.user_id,
           conversation_user_id: conversation_user.id
         )}
    end
  end

  def reducer(message, %Event{
        topic: [:app, app_id, :conversation, conversation_id, :messages, _message_id],
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
        topic: [:app, app_id, :conversation, conversation_id, :messages, _message_id],
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

  def reducer(input, %Event{name: :noop}) do
    {:ok, input}
  end
end
