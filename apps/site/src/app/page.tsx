'use client';

import { useState } from 'react';
import api from '@/lib/api';
import { HeartHandshake, MessageCircle, Mail, ShieldCheck, Sparkles, Users } from 'lucide-react';

const TENANT_DB = 'provision-test_provisiontestmatrimony';

export default function LoginPage() {
  const [step, setStep] = useState<'request' | 'verify'>('request');
  const [contact, setContact] = useState('');
  const [contactType, setContactType] = useState<'phone' | 'email'>('phone');
  const [otp, setOtp] = useState('');
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(false);
  const [devOtp, setDevOtp] = useState('');

  const requestOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true); setErr('');
    try {
      const body: any = { tenantDbName: TENANT_DB };
      if (contactType === 'phone') body.phone = contact; else body.email = contact;
      const { data } = await api.post('/site/otp/request', body);
      setMsg(`OTP sent${contactType === 'phone' ? ' on WhatsApp' : ' by email'}. Check your ${contactType}.`);
      if (data.otp) setDevOtp(data.otp);
      setStep('verify');
    } catch (e: any) {
      setErr(e.response?.data?.message || 'Failed to send OTP');
    } finally { setLoading(false); }
  };

  const verifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true); setErr('');
    try {
      const body: any = { tenantDbName: TENANT_DB, otp };
      if (contactType === 'phone') body.phone = contact; else body.email = contact;
      const { data } = await api.post('/site/otp/verify', body);
      localStorage.setItem('site_token', data.access_token);
      setMsg('Login successful! Redirecting...');
      setTimeout(() => window.location.href = '/dashboard', 800);
    } catch (e: any) {
      setErr(e.response?.data?.message || 'Invalid OTP');
    } finally { setLoading(false); }
  };

  return (
    <div className="auth-backdrop min-h-screen">
      <div className="mx-auto flex min-h-screen max-w-6xl flex-col-reverse items-center gap-12 px-6 py-12 lg:flex-row lg:items-center lg:justify-between lg:gap-8">
        {/* Hero copy */}
        <div className="w-full max-w-lg lg:w-1/2">
          <div className="mb-6 flex items-center gap-2.5">
            <div className="flex size-10 items-center justify-center rounded-xl bg-emerald-500 text-emerald-950 shadow-lg shadow-emerald-500/20">
              <HeartHandshake className="size-5" />
            </div>
            <span className="text-lg font-semibold">Matrimony</span>
          </div>
          <h1 className="text-4xl font-semibold leading-tight tracking-tight text-balance sm:text-5xl">
            Find your perfect{' '}
            <span className="bg-gradient-to-r from-emerald-400 to-amber-300 bg-clip-text text-transparent">
              life partner
            </span>
          </h1>
          <p className="mt-4 max-w-md text-base leading-relaxed text-white/60">
            A trusted, privacy-first matrimonial platform. Verified profiles, thoughtful matches,
            and a respectful path to marriage — built around your family&apos;s values.
          </p>

          <div className="mt-8 grid grid-cols-1 gap-3 sm:grid-cols-3">
            {[
              { icon: ShieldCheck, label: 'Verified profiles' },
              { icon: Sparkles, label: 'Smart matching' },
              { icon: Users, label: 'Family-first' },
            ].map(({ icon: Icon, label }) => (
              <div key={label} className="flex items-center gap-2 rounded-xl border border-white/8 bg-white/[0.03] px-3 py-2.5">
                <Icon className="size-4 shrink-0 text-emerald-400" />
                <span className="text-sm text-white/70">{label}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Auth card */}
        <div className="w-full max-w-md lg:w-1/2">
          <div className="rounded-2xl border border-white/10 bg-white/[0.04] p-8 shadow-2xl shadow-black/40 backdrop-blur-md">
            <h2 className="text-xl font-semibold">
              {step === 'request' ? 'Sign in to continue' : 'Verify your code'}
            </h2>
            <p className="mt-1 text-sm text-white/50">
              {step === 'request'
                ? 'We’ll send a one-time code to log you in'
                : `Sent to your ${contactType === 'phone' ? 'WhatsApp' : 'email'}`}
            </p>

            <div className="mt-6">
              {step === 'request' ? (
                <form onSubmit={requestOtp} className="space-y-4">
                  <div className="flex gap-2">
                    {(['phone', 'email'] as const).map(t => (
                      <button
                        key={t}
                        type="button"
                        onClick={() => setContactType(t)}
                        className={`flex flex-1 cursor-pointer items-center justify-center gap-1.5 rounded-lg border px-3 py-2.5 text-sm font-medium capitalize transition-colors duration-150 ${
                          contactType === t
                            ? 'border-emerald-500/50 bg-emerald-500/10 text-emerald-400'
                            : 'border-white/10 text-white/50 hover:border-white/20 hover:text-white/80'
                        }`}
                      >
                        {t === 'phone' ? <MessageCircle className="size-4" /> : <Mail className="size-4" />}
                        {t === 'phone' ? 'WhatsApp' : 'Email'}
                      </button>
                    ))}
                  </div>
                  <input
                    value={contact}
                    onChange={e => setContact(e.target.value)}
                    placeholder={contactType === 'phone' ? '+91XXXXXXXXXX' : 'you@example.com'}
                    className="w-full rounded-lg border border-white/10 bg-white/[0.03] px-4 py-2.5 text-white outline-none transition-colors placeholder:text-white/30 focus:border-emerald-500/60 focus:ring-3 focus:ring-emerald-500/15"
                    required
                  />
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full cursor-pointer rounded-lg bg-emerald-500 py-2.5 font-medium text-emerald-950 transition-colors duration-150 hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {loading ? 'Sending…' : 'Send OTP'}
                  </button>
                  {devOtp && (
                    <p className="rounded-lg bg-amber-500/10 px-3 py-2 text-xs text-amber-400">
                      DEV MODE — OTP: <b>{devOtp}</b> (also in API console)
                    </p>
                  )}
                </form>
              ) : (
                <form onSubmit={verifyOtp} className="space-y-4">
                  <input
                    value={otp}
                    onChange={e => setOtp(e.target.value)}
                    placeholder="000000"
                    maxLength={6}
                    className="w-full rounded-lg border border-white/10 bg-white/[0.03] px-4 py-2.5 text-center text-2xl tracking-[0.5em] text-white outline-none transition-colors placeholder:text-white/20 focus:border-emerald-500/60 focus:ring-3 focus:ring-emerald-500/15"
                    required
                  />
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full cursor-pointer rounded-lg bg-emerald-500 py-2.5 font-medium text-emerald-950 transition-colors duration-150 hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {loading ? 'Verifying…' : 'Verify & Login'}
                  </button>
                  <button
                    type="button"
                    onClick={() => { setStep('request'); setMsg(''); }}
                    className="w-full cursor-pointer text-sm text-white/50 transition-colors hover:text-white"
                  >
                    ← Change number/email
                  </button>
                  {devOtp && (
                    <p className="rounded-lg bg-amber-500/10 px-3 py-2 text-xs text-amber-400">
                      DEV MODE — OTP: <b>{devOtp}</b>
                    </p>
                  )}
                </form>
              )}

              {msg && <p className="mt-4 rounded-lg bg-emerald-500/10 p-3 text-sm text-emerald-400">{msg}</p>}
              {err && <p className="mt-4 rounded-lg bg-red-500/10 p-3 text-sm text-red-400">{err}</p>}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
