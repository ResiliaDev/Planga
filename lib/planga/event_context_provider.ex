defmodule Planga.EventContextProvider do
  alias Planga.Repo
  alias TeaVent.Event

  def run(event = %TeaVent.Event{topic: topic}, reducer) do
    {db_preparation, subject_fun} = hydrate(topic, event.meta)

    IO.inspect("TEST")

    ecto_multi =
      Ecto.Multi.new()
      |> Ecto.Multi.append(db_preparation)
      |> Ecto.Multi.run(:subject, subject_fun)
      |> Ecto.Multi.run(:reducer, fn %{subject: subject} ->
      IO.inspect(subject, label: :reducer)
        reducer.(subject)
      end)
      |> Ecto.Multi.merge(fn %{reducer: event_result} ->
        changes =
          case event_result do
            %Event{changes: nil, changed_subject: new_thing} ->
              Ecto.Changeset.change(new_thing)

            %Event{changes: changes, subject: original_thing} ->
              Ecto.Changeset.change(original_thing, changes)
          end

        Ecto.Multi.new()
        |> Ecto.Multi.insert_or_update(:insert_or_update_subject, changes)
      end)

    # {status, ecto_multi} =
    #   with {db_preparation, subject_fun} <- hydrate(topic, event.meta) |> IO.inspect(),
    #        {:ok, updated_event} <- reducer.(subject) |> IO.inspect() do
    #     changes =
    #       case updated_event do
    #         %Event{changes: nil, changed_subject: new_thing} ->
    #           Ecto.Changeset.change(new_thing)

    #         %Event{changes: changes, subject: original_thing} ->
    #           Ecto.Changeset.change(original_thing, changes)
    #       end

    #     ecto_multi =
    #       Ecto.Multi.new()
    #       |> Ecto.Multi.insert_or_update(:insert_or_update_subject, changes)

    #     {:ok, ecto_multi}
    #   else
    #     {:error, problem} -> {:error, Ecto.Multi.error(:error, problem)}
    #   end

    new_meta = Map.put(event.meta, :ecto_multi, ecto_multi)

    {:ok, %TeaVent.Event{event | meta: new_meta}}
  end

  def hydrate([:app, app_id], _) do
    {Ecto.Multi.new(),
     fn _ ->
       Repo.fetch(Planga.Chat.App, app_id)
     end}
  end

  def hydrate([:app, app_id, :conversation, cid], _) do
    {fetch_or_create_conversation_by_remote_id(app_id, cid),
     fn %{conversation: conversation} -> {:ok, conversation} end}
  end

  def hydrate([:app, app_id, :conversation, remote_conversation_id, :messages], _),
    do:
      {fetch_or_create_conversation_by_remote_id(app_id, remote_conversation_id),
       fn %{conversation: conversation} -> {:ok, conversation} end}

  def hydrate([:app, app_id, :conversation, remote_conversation_id, :messages, message_uuid], %{
        remote_user_id: remote_user_id
      }) do
    {
      ensure_user_partakes_in_conversation(app_id, remote_conversation_id, remote_user_id),

      # TODO more lazy conversation creation?
      # conversation =
      #   Planga.Chat.Converse.Persistence.find_or_create_conversation_by_remote_id!(
      #     app_id,
      #     remote_conversation_id
      #   )
      fn %{conversation: conversation} ->
        Repo.fetch_by(Planga.Chat.Message, conversation_id: conversation.id, uuid: message_uuid)
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
    |> IO.inspect
    |> Ecto.Multi.merge(fn %{^atomname => structure} ->
      IO.inspect(structure)
      res = Ecto.Multi.new
      |> Ecto.Multi.insert_or_update(:"#{structure_name}", structure |> Ecto.Changeset.change())
    end)
    |> IO.inspect
  end

  defp fetch_or_create_conversation_by_remote_id(app_id, remote_conversation_id) do
    fetch_or_create_structure("conversation", Planga.Chat.Conversation, app_id: app_id, remote_id: remote_conversation_id)
  end

  defp fetch_or_create_user(app_id, remote_user_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:pre_insertion_user, fn _ ->
      case Repo.get_by(Planga.Chat.User, app_id: app_id, remote_id: remote_user_id) do
        nil -> %Planga.Chat.User{app_id: app_id, remote_id: remote_user_id}
      end
    end)
    |> Ecto.Multi.insert_or_update(:user, fn %{pre_insertion_user: user} -> user end)
  end

  defp ensure_user_partakes_in_conversation(app_id, remote_conversation_id, remote_user_id) do
    multi_a = fetch_or_create_conversation_by_remote_id(app_id, remote_conversation_id)
    multi_b = fetch_or_create_user(app_id, remote_user_id)

    multi_a
    |> Ecto.Multi.append(multi_b)
    |> Ecto.Multi.merge(fn %{conversation: conversation, user: user} ->
      Ecto.Multi.new()
      |> Ecto.Multi.run(:pre_insertion_user, fn _ ->
        case Repo.get_by(
               Planga.Chat.ConversationUser,
               conversation_id: conversation.id,
               user_id: user.id
             ) do
          nil -> %Planga.Chat.User{app_id: app_id, remote_id: remote_user_id}
          conversation_user -> conversation_user
        end
      end)
      |> Ecto.Multi.insert_or_update(:conversation_user, fn %{
                                                              pre_insertion_conversation_user:
                                                                conversation_user
                                                            } ->
        conversation_user
      end)
    end)
  end
end
