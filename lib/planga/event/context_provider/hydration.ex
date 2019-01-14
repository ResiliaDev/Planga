defmodule Planga.Event.ContextProvider.Hydration do
  @moduledoc """
  Responsible for finding the 'logical context' of each incoming event.

  Because the application state is too big to use at once, and there is no 'single truth' in a distributed system,
  this 'logical context' can be consideed the _single state of truth for this given event call_.
  """
  alias Planga.Repo
  alias TeaVent.Event

  @doc """
  Fills the `meta.ctreator` field of the event with something useful,
  if applicable; either a User or a ConversationUser, depending on the Event's topic.
  """
  def fetch_creator(%Event{
        topic: [:apps, app_id, :conversations, remote_conversation_id | _],
        meta: %{creator: remote_user_id}
      })
      when remote_user_id != nil do
    app_id
    |> ensure_user_partakes_in_conversation(
      remote_conversation_id,
      remote_user_id,
      "creator"
    )
    |> Ecto.Multi.run(:creator, &{:ok, Map.get(&1, :creator_conversation_user)})
  end

  def fetch_creator(%Event{topic: [:apps, app_id | _], meta: %{creator: remote_user_id}})
      when remote_user_id != nil do
    fetch_or_create_user(app_id, remote_user_id, "creator")
  end

  def fetch_creator(%Event{}),
    do: Ecto.Multi.new() |> Ecto.Multi.run(:creator, fn _ -> {:ok, nil} end)

  @doc """
  Fetches the subject (AKA 'logical context') for the given event, based on its topic (and potentially some other information like e.g. the event's meta-content).

  In some cases the topic refers something that might not be persisted yet, in which case we add it to the DB firrst, before running the reducer (in a transaction, such that when the reducer fails, everything is removed from the DB again).

  Returns `{Ecto.Multi.t, function_returning_structure_based_on_ecto_multi_map}`.

  The `ecto_multi_map` is a map containing keys with the names of earlier Ecto.Multi stages; see the `Ecto.Multi` library module for more information.

  In simple cases, a function clause will look like `{Ecto.Multi.new, fn _ -> Repo.fetch(something_or_other) end}`
  """
  def hydrate([:apps, app_id], _) do
    {Ecto.Multi.new(),
     fn _ ->
       Repo.fetch(Planga.Chat.App, app_id)
     end}
  end

  def hydrate([:apps, app_id, :conversations, cid], _) do
    {fetch_or_create_conversation_by_remote_id(app_id, cid),
     fn %{conversation: conversation} -> {:ok, conversation} end}
  end

  def hydrate([:apps, app_id, :conversations, remote_conversation_id, :messages], %{
        creator: remote_user_id
      }) do
    {ensure_user_partakes_in_conversation(app_id, remote_conversation_id, remote_user_id),
     fn _ ->
       {:ok, nil}
     end}
  end

  def hydrate([:apps, app_id, :conversations, rcid, :users, remote_user_id], _) do
    # {fetch_or_create_conversation_by_remote_id(app_id, rcid),
    {ensure_user_partakes_in_conversation(app_id, rcid, remote_user_id),
     fn %{conversation_user: conversation_user} ->
       {:ok, conversation_user}

       # Repo.fetch_by(Planga.Chat.ConversationUser, conversation_id: conversation.id, user_id: user_id)
     end}
  end

  def hydrate([:apps, app_id, :conversations, remote_conversation_id, :messages], _),
    do:
      {fetch_or_create_conversation_by_remote_id(app_id, remote_conversation_id),
       fn %{conversation: conversation} -> {:ok, conversation} end}

  def hydrate([:apps, app_id, :conversations, remote_conversation_id, :messages, message_uuid], %{
        creator: remote_user_id
      }) do
    {
      ensure_user_partakes_in_conversation(app_id, remote_conversation_id, remote_user_id),
      fn %{conversation: conversation} ->
        with {:ok, message} <-
               Repo.fetch_by(
                 Planga.Chat.Message,
                 conversation_id: conversation.id,
                 uuid: message_uuid
               ) do
          {:ok,
           message
           |> Repo.preload(:sender)
           |> Repo.preload(:conversation_user)}
        end
      end
    }
  end

  defp fetch_or_create_structure(structure_name, schema, kvs) do
    atomname = :"pre_insertion_#{structure_name}"

    Ecto.Multi.new()
    |> Ecto.Multi.run(atomname, fn _ ->
      case Repo.get_by(schema, kvs) do
        nil ->
          schema.new(kvs)

        result ->
          {:ok, result}
      end
    end)
    |> Ecto.Multi.merge(fn %{^atomname => structure} ->
      Ecto.Multi.new()
      |> Ecto.Multi.insert_or_update(:"#{structure_name}", structure |> Ecto.Changeset.change())
    end)
  end

  defp fetch_or_create_conversation_by_remote_id(
         app_id,
         remote_conversation_id,
         field_name \\ "conversation"
       ) do
    fetch_or_create_structure(
      field_name,
      Planga.Chat.Conversation,
      app_id: app_id,
      remote_id: remote_conversation_id
    )
  end

  defp fetch_or_create_user(app_id, remote_user_id, field_name) do
    fetch_or_create_structure(
      field_name,
      Planga.Chat.User,
      app_id: app_id,
      remote_id: remote_user_id
    )
  end

  defp ensure_user_partakes_in_conversation(
         app_id,
         remote_conversation_id,
         remote_user_id,
         field_name_prefix \\ ""
       ) do
    field_name =
      case field_name_prefix do
        "" ->
          fn name -> :"#{name}" end

        _other ->
          fn name -> :"#{field_name_prefix}_#{name}" end
      end

    field_name_conversation = field_name.("conversation")
    field_name_user = field_name.("user")
    field_name_conversation_user = field_name.("conversation_user")

    multi_a =
      fetch_or_create_conversation_by_remote_id(
        app_id,
        remote_conversation_id,
        field_name_conversation
      )

    multi_b = fetch_or_create_user(app_id, remote_user_id, field_name_user)

    multi_a
    |> Ecto.Multi.append(multi_b)
    |> Ecto.Multi.merge(fn %{^field_name_conversation => conversation, ^field_name_user => user} ->
      fetch_or_create_structure(
        field_name_conversation_user,
        Planga.Chat.ConversationUser,
        conversation_id: conversation.id,
        user_id: user.id
      )
    end)
  end
end
