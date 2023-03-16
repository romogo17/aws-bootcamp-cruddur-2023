-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrew@exampro.co', 'andrewbrown' ,'MOCK'),
  ('Roberto Mora', 'romogo17@gmail.com', 'romogo17' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'romogo17' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )