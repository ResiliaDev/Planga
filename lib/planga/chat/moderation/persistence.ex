defmodule Planga.Chat.Moderation.Persistence do

  persistence_implementation = __MODULE__.Mnesia

  # defdelegate hide_message(conversation_id, message_uuid), to: persistence_implementation
  # defdelegate ban_chatter(conversation_id, user_id, duration_minutes), to: persistence_implementation
  # defdelegate set_role(conversation_id, user_id, role), to: persistence_implementation

  defdelegate update_message(conversation_id, message_uuid, update_function), to: persistence_implementation
  defdelegate update_conversation_user(conversation_id, user_id, update_function), to: persistence_implementation

  defdelegate find_or_create_conversation_by_remote_id!(app_id, remote_id), to: Planga.Chat.Converse.Persistence
  defdelegate fetch_conversation_user_info(conversation_id, user_id), to: Planga.Chat.Converse.Persistence
end
