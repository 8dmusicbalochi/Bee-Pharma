/*
# [Update Profile RLS Policy]
This migration updates the Row Level Security (RLS) policies on the `profiles` table to allow 'Super Admin' and 'Stock Manager' roles to view all user profiles. This is necessary for features like viewing customer details in sales history. The existing policy that allows users to view their own profile is kept.

## Query Description: This operation modifies security policies. It expands read access to the `profiles` table for administrative roles. There is no risk of data loss, but it changes who can see user profile information.

## Metadata:
- Schema-Category: "Security"
- Impact-Level: "Medium"
- Requires-Backup: false
- Reversible: true (by dropping the new policy)

## Structure Details:
- Table: `profiles`
- Policy Name: `Admins and managers can view all profiles`

## Security Implications:
- RLS Status: Enabled
- Policy Changes: Yes. A new `SELECT` policy is added.
- Auth Requirements: This change depends on the `check_user_role` function.

## Performance Impact:
- Indexes: None
- Triggers: None
- Estimated Impact: Low. The policy check adds minimal overhead to queries on the `profiles` table for authorized roles.
*/

create policy "Admins and managers can view all profiles"
on public.profiles for select
using (
  public.check_user_role('Super Admin') or
  public.check_user_role('Stock Manager')
);
