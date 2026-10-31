/*
# Create MassaMia store settings and admin access

1. New Tables
- `massamia_store_settings` stores the public menu configuration as a single JSON document, including product names, prices, and active options.
- `massamia_admin_users` maps authenticated Supabase users who are allowed to change the store settings.

2. Security
- Row level security is enabled on both tables.
- Anyone may read the public store settings so the storefront can load without signing in.
- Only authenticated users listed in `massamia_admin_users` may update settings.
- Admin membership cannot be created or changed through the browser client.

3. Important notes
- The first administrator must be added to `massamia_admin_users` by the project owner after creating their Supabase email/password account.
- Prices are stored inside the JSON configuration but are validated again in the browser as cent values before display and checkout.
*/

CREATE TABLE IF NOT EXISTS public.massamia_store_settings (
  id text PRIMARY KEY DEFAULT 'main',
  config jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT massamia_store_settings_singleton CHECK (id = 'main')
);

CREATE TABLE IF NOT EXISTS public.massamia_admin_users (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.massamia_store_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.massamia_admin_users ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.massamia_store_settings TO anon, authenticated;
GRANT SELECT ON public.massamia_admin_users TO authenticated;
GRANT UPDATE (config, updated_at) ON public.massamia_store_settings TO authenticated;

DROP POLICY IF EXISTS "Public can read MassaMia settings" ON public.massamia_store_settings;
CREATE POLICY "Public can read MassaMia settings" ON public.massamia_store_settings
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Admins can update MassaMia settings" ON public.massamia_store_settings;
CREATE POLICY "Admins can update MassaMia settings" ON public.massamia_store_settings
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.massamia_admin_users WHERE user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.massamia_admin_users WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can read their own membership" ON public.massamia_admin_users;
CREATE POLICY "Admins can read their own membership" ON public.massamia_admin_users
  FOR SELECT TO authenticated USING (user_id = auth.uid());

INSERT INTO public.massamia_store_settings (id, config)
VALUES ('main', '{"sizes":[{"id":"250g","label":"250 g","priceCents":1000},{"id":"500g","label":"500 g","priceCents":1499}],"pastaTypes":[{"id":"penne","name":"Penne","active":true},{"id":"fettuccine","name":"Fettuccine","active":true},{"id":"parafuso","name":"Parafuso","active":true},{"id":"caracolinho","name":"Caracolinho","active":true}],"sauces":[{"id":"sugo","name":"Molho ao sugo com manjericão","active":true},{"id":"branco","name":"Molho branco","active":true}],"extras":[{"id":"frango","name":"Frango","active":true},{"id":"carne-moida","name":"Carne moída","active":true},{"id":"presunto","name":"Presunto","active":true},{"id":"azeitona","name":"Azeitona","active":true},{"id":"cheddar","name":"Cheddar","active":true},{"id":"cebola","name":"Cebola","active":true},{"id":"bacon","name":"Bacon","active":true},{"id":"linguica","name":"Linguiça calabresa","active":true},{"id":"milho","name":"Milho","active":true},{"id":"parmesao","name":"Queijo parmesão","active":true},{"id":"mussarela","name":"Queijo mussarela","active":true}],"extraPriceCents":200}'::jsonb)
ON CONFLICT (id) DO NOTHING;
