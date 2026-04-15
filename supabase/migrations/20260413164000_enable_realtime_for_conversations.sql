-- Enable realtime replication for conversations and messages tables
-- This fixes the realtime subscription issue in the messages page

-- Add conversations table to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

-- Add messages table to realtime publication  
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
