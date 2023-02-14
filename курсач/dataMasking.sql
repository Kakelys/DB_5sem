CREATE EXTENSION IF NOT EXISTS anon CASCADE;
ALTER SYSTEM SET shared_preload_libraries = 'anon';
ALTER DATABASE forum SET session_preload_libraries='anon'



