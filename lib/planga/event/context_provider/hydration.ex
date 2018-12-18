defmodule Planga.Event.ContextProvider.Hydration do
  alias Planga.Repo
  alias TeaVent.Event

  def fetch_creator(
        event = %Event{
          topic: [:apps, app_id, :conversations, remote_conversation_id | _],
          meta: %{remote_user_id: remote_user_id}
        }
      ) do
    ensure_user_partakes_in_conversation(
      app_id,
      remote_conversation_id,
      remote_user_id,
      "creator"
    )
    |> Ecto.Multi.run(:creator, &{:ok, Map.get(&1, :creator_conversation_user)})
    |> IO.inspect(label: "Case 1")
  end

  def fetch_creator(
        event = %Event{topic: [:apps, app_id | _], meta: %{remote_user_id: remote_user_id}}
      ) do
    # |> Ecto.Multi.run(:creator, &({:ok, Map.get(&1, :creator_user)}))
    fetch_or_create_user(app_id, remote_user_id, "creator")
    |> IO.inspect(label: "Case 2")
  end

  def fetch_creator(event = %Event{}),
    do:
      Ecto.Multi.new() |> Ecto.Multi.run(:creator, fn _ -> {:ok, nil} end)
      |> IO.inspect(label: "Case 3")

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
        remote_user_id: remote_user_id
      }) do
    {ensure_user_partakes_in_conversation(app_id, remote_conversation_id, remote_user_id),
     fn _ ->
       {:ok, nil}
     end}
  end

  def hydrate([:apps, app_id, :conversations, remote_conversation_id, :users, remote_user_id], _) do
    {ensure_user_partakes_in_conversation(app_id, remote_conversation_id, remote_user_id),
     fn %{conversation_user: conversation_user} ->
       {:ok, conversation_user}
     end}
  end

  def hydrate([:apps, app_id, :conversations, remote_conversation_id, :messages], _),
    do:
      {fetch_or_create_conversation_by_remote_id(app_id, remote_conversation_id),
       fn %{conversation: conversation} -> {:ok, conversation} end}

  def hydrate([:apps, app_id, :conversations, remote_conversation_id, :messages, message_uuid], %{
        remote_user_id: remote_user_id
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
    IO.inspect([structure_name, schema, kvs])
    atomname = :"pre_insertion_#{structure_name}"

    Ecto.Multi.new()
    |> Ecto.Multi.run(atomname, fn _ ->
      case Repo.get_by(schema, kvs) do
        nil -> {:ok, struct(schema, kvs)}
        result -> {:ok, result}
      end
    end)
    |> IO.inspect()
    |> Ecto.Multi.merge(fn %{^atomname => structure} ->
      IO.inspect(structure)

      res =
        Ecto.Multi.new()
        |> Ecto.Multi.insert_or_update(:"#{structure_name}", structure |> Ecto.Changeset.change())
    end)
    |> IO.inspect()
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

  defp fetch_or_create_user(app_id, remote_user_id, field_name \\ "user") do
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

        other ->
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
