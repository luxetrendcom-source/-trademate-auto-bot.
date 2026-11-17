-- Run ONCE in the Supabase SQL editor after deploying the functions.
-- 1) Replace <PROJECT_REF> and <LONG_RANDOM_SECRET>. The same secret must be set as the BOT_WORKER_SECRET function secret.
create extension if not exists pg_cron;
create extension if not exists pg_net;

select vault.create_secret('<LONG_RANDOM_SECRET>', 'bot_worker_secret');

select cron.schedule(
  'trademate-bot-worker',
  '* * * * *',                                  -- every minute, server-side, no browser needed
  $$
  select net.http_post(
    url     := 'https://<PROJECT_REF>.supabase.co/functions/v1/bot-worker',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-bot-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'bot_worker_secret')),
    body    := '{}'::jsonb,
    timeout_milliseconds := 55000
  );
  $$
);

-- To pause the whole background engine:  select cron.unschedule('trademate-bot-worker');
