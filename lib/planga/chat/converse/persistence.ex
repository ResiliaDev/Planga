defmodule Planga.Chat.Converse.Persistence do

  persistence_implementation = __MODULE__.Mnesia
  defdelegate fetch_messages_by_conversation_id(conversation_id, sent_before_datetime), to: persistence_implementation
  defdelegate find_or_create_conversation_by_remote_id!(app_id, remote_id), to: persistence_implementation

  defdelegate create_message(app_id, remote_conversation_id, user_id, message, other_user_ids), to: persistence_implementation

  defdelegate fetch_conversation_user_info(conversation_id, user_id), to: persistence_implementation

  defdelegate find_conversation_by_remote_id, to: persistence_implementation
end
