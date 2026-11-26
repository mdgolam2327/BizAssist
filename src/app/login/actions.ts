'use server';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
export async function authenticate(formData: FormData) {
  const mode=String(formData.get('mode')||'login'); const email=String(formData.get('email')||'').trim(); const password=String(formData.get('password')||'');
  let supabase;
  try { supabase=await createClient(); }
  catch(error) {
    if(error instanceof Error&&error.message.includes('Supabase is not configured')) redirect('/login?error=config');
    throw error;
  }
  if(mode==='signup') { const {error}=await supabase.auth.signUp({email,password,options:{emailRedirectTo:`${process.env.NEXT_PUBLIC_SITE_URL||'http://localhost:3000'}/auth/callback`}}); if(error) redirect('/login?error=signup'); redirect('/login?message=verify'); }
  const {error}=await supabase.auth.signInWithPassword({email,password}); if(error) redirect('/login?error=credentials'); redirect('/');
}
