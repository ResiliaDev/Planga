defprotocol RiakSerialization do
  @fallback_to_any true

  def serialize(obj)
  def deserialize(riak_obj)
end

defimpl RiakSerialization, for: Any do
  def serialize(anything) do
    anything
    |> :erlang.term_to_binary
    |> Riak.CRDT.Register.new
  end

  def deserialize(register) do
    register
    |> Riak.CRDT.Register.value
    |> :erlang.binary_to_term
  end
end

defimpl RiakSerialization, for: Planga.Chat.Message do
  def serialize(message) do
    message_map = Map.from_struct(message)
    [:id, :uuid, :content, :inserted_at, :updated_at, :deleted_at, :sender_id, :conversation_id, :conversation_user_id]
    |> Enum.map(fn field ->
      val =
        message_map
        |> Access.get(field)
        |> :erlang.term_to_binary
        |> Riak.CRDT.Register.new
      {Atom.to_string(field), val}
    end)
    |> Enum.reduce(Riak.CRDT.Map.new(), fn {k, v}, map ->
      map
      |> Riak.CRDT.Map.put(k, v)
    end)
  end

  def deserialize(riak_map) do
    struct(Planga.Chat.Message, RiakSerialization.Map.deserialize(riak_map))
  end
end

defimpl RiakSerialization, for: String do
  def serialize(str) do
    str
    |> :erlang.term_to_binary
    |> Riak.CRDT.Register.new
  end
end


defimpl RiakSerialization, for: Boolean do
  def serialize(str) do
    str
    |> :erlang.term_to_binary
    |> Riak.CRDT.Flag.new
  end
end

defimpl RiakSerialization, for: Map do
  @doc """
  NOTE: Assumes the string contains atom keys.
  If non-atom is encountered, will fail.
  """
  def serialize(map) do
    map
    |> Enum.map(fn {key, value} ->
      {Atom.to_string(key), RiakSerialization.serialize(value)}
    end)
  end

  def deserialize(riak_map) do
    riak_map
    |> Riak.CRDT.Map.value
    |> Enum.map(fn {{key, value_type}, raw_value} ->
      value =
        case value_type do
          :register ->
            raw_value
            |> :erlang.binary_to_term
          :flag ->
            raw_value
        end
      {String.to_existing_atom(key), value}
    end)
    |> Enum.into(%{})
  end
end
