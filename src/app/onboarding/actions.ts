'use server';

import { redirect } from 'next/navigation';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';

const schema = z.object({
  primaryType: z.string().min(1), additionalTypes: z.array(z.string()), businessName: z.string().trim().min(2).max(120), ownerName: z.string().trim().min(2).max(120), phone: z.string().trim().min(7).max(24), address: z.string().trim().max(500).optional(), gstin: z.string().trim().max(15).optional(), currency: z.string().length(3), financialYearStart: z.string(), inventoryEnabled: z.boolean(), billingEnabled: z.boolean(), paymentPreference: z.string(),
});
export async function createBusiness(input: unknown) {
  const parsed = schema.safeParse(input);
  if (!parsed.success) return { error: 'Please check the business details and try again.' };
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Your session has expired. Sign in and continue onboarding.' };
  const { data, error } = await supabase.rpc('create_business_onboarding', {
    p_primary_type: parsed.data.primaryType,
    p_additional_types: parsed.data.additionalTypes,
    p_name: parsed.data.businessName,
    p_owner_name: parsed.data.ownerName,
    p_phone: parsed.data.phone,
    p_address: parsed.data.address || null,
    p_gstin: parsed.data.gstin || null,
    p_currency: parsed.data.currency,
    p_financial_year_start: parsed.data.financialYearStart,
    p_inventory_enabled: parsed.data.inventoryEnabled,
    p_billing_enabled: parsed.data.billingEnabled,
    p_payment_preference: parsed.data.paymentPreference,
  });
  if (error) {
    // Keep database details in server logs while giving a useful, safe action to the user.
    console.error('Business onboarding RPC failed', { code: error.code, message: error.message });
    if (error.code === 'PGRST202' || error.message.toLowerCase().includes('create_business_onboarding')) {
      return { error: 'The BizAssist database setup is missing. Apply the onboarding migration in Supabase, then try again.' };
    }
    if (error.message.toLowerCase().includes('industry')) return { error: 'That business category is unavailable. Apply the latest BizAssist migration and try again.' };
    if (error.code === '23514') return { error: 'One of the details does not match the required format. Check the GSTIN and preferences.' };
    return { error: 'We could not create this business. Please check the server logs for the Supabase error.' };
  }
  const result = data as { business_id?: string } | null;
  if (!result?.business_id) return { error: 'Business setup did not complete. Please try again.' };
  redirect(`/business/${result.business_id}`);
}
