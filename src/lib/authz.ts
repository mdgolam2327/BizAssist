import { createClient } from '@/lib/supabase/server';

/** Use from server pages/actions before performing work for a business module. */
export async function requireBusinessModule(businessId:string,moduleId:string,roles?:string[]) {
  const supabase=await createClient();
  const {data:{user}}=await supabase.auth.getUser();
  if(!user)throw new Error('AUTHENTICATION_REQUIRED');
  const {data:membership}=await supabase.from('business_members').select('role').eq('business_id',businessId).eq('user_id',user.id).maybeSingle();
  if(!membership)throw new Error('BUSINESS_ACCESS_DENIED');
  if(roles&&!roles.includes(membership.role))throw new Error('ROLE_ACCESS_DENIED');
  const {data:module}=await supabase.from('business_modules').select('enabled').eq('business_id',businessId).eq('module_id',moduleId).maybeSingle();
  if(!module?.enabled)throw new Error('BUSINESS_MODULE_DISABLED');
  return {supabase,user,role:membership.role};
}
