-- VOW Company Feedback System: compatibility upgrade
-- Run in Supabase SQL Editor as project owner AFTER the earlier schema/migration.
-- Take a backup first. This does not delete customer/review rows.
begin;

-- Add fields used by the ready-made frontend.
alter table public.customers add column if not exists customer_code text;
alter table public.customers add column if not exists email text;
alter table public.customers add column if not exists notes text not null default '';
alter table public.customers add column if not exists updated_at timestamptz not null default now();
alter table public.reviews add column if not exists consent_at timestamptz;
alter table public.reviews add column if not exists branch_id uuid references public.branches(id);
alter table public.reviews add column if not exists created_by uuid references auth.users(id);

-- Allow public visitors to see active branch names only (needed by the feedback form).
drop policy if exists "public_read_active_branches" on public.branches;
create policy "public_read_active_branches"
on public.branches for select to anon
using (is_active = true);
grant select on public.branches to anon;

-- Company admins can create/update branches; branch staff cannot.
grant insert, update on public.branches to authenticated;
drop policy if exists "company_admin_manage_branches" on public.branches;
create policy "company_admin_manage_branches"
on public.branches for all to authenticated
using ((select private.current_role()) = 'company_admin')
with check ((select private.current_role()) = 'company_admin');

-- Public feedback may only be submitted for a real active branch.
-- It is not publicly readable. Public submissions are untrusted and should be moderated.
drop policy if exists "reviews_public_insert_unassigned" on public.reviews;
drop policy if exists "Public can submit reviews" on public.reviews;
drop policy if exists "public_submit_review_active_branch" on public.reviews;
create policy "public_submit_review_active_branch"
on public.reviews for insert to anon, authenticated
with check (
  branch_id is not null
  and exists (select 1 from public.branches b where b.id = branch_id and b.is_active = true)
  and created_by is null
  and length(trim(name)) between 1 and 100
  and length(trim(phone)) between 5 and 20
  and length(trim(service)) between 1 and 120
  and rating between 1 and 5
  and length(coalesce(review,'')) <= 1500
  and consent_at is not null
);

-- Ensure authenticated staff can only read reviews for their assigned branch;
-- company admins can read all. The profile/role helpers come from the prior migration.
drop policy if exists "reviews_select_branch" on public.reviews;
create policy "reviews_select_branch"
on public.reviews for select to authenticated
using (
  (select private.current_role()) = 'company_admin'
  or branch_id = (select private.current_branch())
);

-- Do not allow public access to internal customer/call/complaint/follow-up data.
revoke all on public.customers, public.call_logs, public.complaints,
  public.follow_ups, public.profiles, public.audit_logs from anon;

-- Keep review public access insert-only; never grant public SELECT.
revoke select, update, delete on public.reviews from anon;
grant insert on public.reviews to anon;

create index if not exists customers_code_idx on public.customers(customer_code);
create index if not exists reviews_branch_created_idx on public.reviews(branch_id, created_at desc);

commit;

-- After running, create branches through the company-admin interface.
-- Then create staff users under Authentication > Users, and insert their profiles
-- using trusted SQL Editor with the correct auth user UUID and branch UUID.
