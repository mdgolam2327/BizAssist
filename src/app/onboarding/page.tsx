import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import Onboarding from './Onboarding';
export default async function OnboardingPage() {
  try { const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser(); if(!user) redirect('/login'); return <Onboarding/>; }
  catch(error) { if(error instanceof Error&&error.message.includes('NEXT_REDIRECT')) throw error; return <main className="grid min-h-screen place-items-center bg-slate-50 p-6"><div className="max-w-md rounded-2xl bg-white p-8 shadow"><h1 className="text-xl font-bold">Connect your workspace</h1><p className="text-sm leading-6 text-slate-600">Supabase authentication is not configured yet. Add the project URL and anon key from <code>.env.example</code>, then run the database migration to start onboarding.</p></div></main>; }
}
