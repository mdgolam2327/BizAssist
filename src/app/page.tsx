import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
export default async function Home() {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) redirect('/login');
    const { data: membership } = await supabase.from('business_members').select('business_id').eq('user_id', user.id).limit(1).maybeSingle();
    redirect(membership ? `/business/${membership.business_id}` : '/onboarding');
  } catch (error) { if (error instanceof Error && error.message.includes('NEXT_REDIRECT')) throw error; redirect('/login'); }
}
