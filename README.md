# VOW Customer Experience — GitHub-ready source

## Files
- `index.html` — responsive Blue/White website, public review form, sign-in, dashboard, customer records, call logs, complaints, follow-ups, branches, CSV exports.
- `company_upgrade.sql` — compatibility SQL for the previous schema/migration discussed in chat.

## Important setup order
1. In Supabase, take a database backup/export first.
2. If you have already run the earlier SQL and company migration, run `company_upgrade.sql` in Supabase SQL Editor.
3. Create a company admin in Supabase Authentication > Users.
4. In SQL Editor, create the first admin profile. Replace UUID with that user's actual auth.users UUID:

```sql
insert into public.profiles(user_id, full_name, role, branch_id, is_active)
values ('REPLACE_WITH_AUTH_USER_UUID'::uuid, 'Company Admin', 'company_admin', null, true)
on conflict (user_id) do update set full_name=excluded.full_name, role='company_admin', branch_id=null, is_active=true;
```

5. Open `index.html` in the GitHub web editor, commit it to the root of your repository.
6. In GitHub: Settings > Pages > Deploy from a branch > `main` > `/(root)` > Save.
7. Open the published Pages URL. The first screen asks for your Supabase Project URL and publishable/anon key. These client-side values are saved only in that browser's local storage. Never enter a service-role/secret key or database password.
8. Create branches using the company-admin dashboard. To add branch managers/staff, first create their auth users, then add profiles with their exact auth UUID and branch UUID. Never allow public users to self-assign roles.

## Role profile examples
Company admin:
```sql
insert into public.profiles(user_id,full_name,role,branch_id,is_active)
values ('AUTH_USER_UUID'::uuid,'Company Admin','company_admin',null,true);
```
Branch manager:
```sql
insert into public.profiles(user_id,full_name,role,branch_id,is_active)
values ('AUTH_USER_UUID'::uuid,'Branch Manager','branch_manager','BRANCH_UUID'::uuid,true);
```
Staff:
```sql
insert into public.profiles(user_id,full_name,role,branch_id,is_active)
values ('AUTH_USER_UUID'::uuid,'Branch Staff','staff','BRANCH_UUID'::uuid,true);
```

## Data safety and production checklist
- Supabase is the live database; browser local storage stores only the public project URL/key, not customer records.
- Configure provider backups and, if business-critical, independent encrypted exports/backups in a separate account/storage. Test restore regularly. Retention and PITR depend on your Supabase plan.
- Use strong passwords and MFA for privileged accounts. Disable public account registration. Only an owner/admin should create role profiles.
- Review RLS policies before real customer data is added. Test as anonymous visitor, branch staff, branch manager, and company admin to confirm cross-branch isolation.
- The public review form accepts customer-submitted content; add CAPTCHA/rate limiting and a moderation workflow before broad public use.
- This starter logs manually entered calls; it does not automatically detect calls made by the phone or record audio.
- No service can guarantee data is preserved forever. Maintain tested independent backups and a written retention policy.

## Notes
This is a ready-to-deploy starter, not a fully audited enterprise product. It requires the Supabase project, schema, auth users and role profiles to be configured. Keep private credentials out of GitHub.
