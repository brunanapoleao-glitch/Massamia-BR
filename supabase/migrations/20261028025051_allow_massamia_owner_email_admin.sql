/*
# Allow the MassaMia owner email to administer the store

1. Modified security behavior
- The existing settings update policy now accepts either a user explicitly listed in `massamia_admin_users` or the authenticated owner email `massamiabr@gmail.com`.
- The browser still needs a valid Supabase email/password session before any settings can be changed.
- No password is stored in the database migration or application source.

2. User experience
- The owner can create the account from the `/admin` page using the configured email and password.
- Once signed in, the owner can edit prices, names, and availability.

3. Important notes
- Authorization is enforced by the database policy, not by hiding the admin page.
- Additional administrators can continue to be managed through `massamia_admin_users`.
*/

DROP POLICY IF EXISTS "Admins can update MassaMia settings" ON public.massamia_store_settings;
CREATE POLICY "Admins can update MassaMia settings" ON public.massamia_store_settings
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.massamia_admin_users WHERE user_id = auth.uid())
    OR lower(coalesce(auth.jwt() ->> 'email', '')) = 'massamiabr@gmail.com'
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.massamia_admin_users WHERE user_id = auth.uid())
    OR lower(coalesce(auth.jwt() ->> 'email', '')) = 'massamiabr@gmail.com'
  );
