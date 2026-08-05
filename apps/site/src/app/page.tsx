'use client';

import { useState } from 'react';
import api from '@/lib/api';

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
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-emerald-950 via-gray-950 to-gray-950">
      <div className="w-full max-w-md rounded-2xl border border-emerald-500/20 bg-gray-900/70 p-8 backdrop-blur">
        <h1 className="text-2xl font-bold text-white mb-1">Matrimony</h1>
        <p className="text-sm text-gray-400 mb-6">Find your perfect life partner</p>

        {step === 'request' ? (
          <form onSubmit={requestOtp} className="space-y-4">
            <div className="flex gap-2">
              {(['phone', 'email'] as const).map(t => (
                <button key={t} type="button" onClick={() => setContactType(t)}
                  className={`flex-1 rounded-lg border px-3 py-2 text-sm capitalize ${contactType === t ? 'border-emerald-500 bg-emerald-500/10 text-emerald-400' : 'border-gray-700 text-gray-400'}`}>
                  {t === 'phone' ? '📱 WhatsApp' : '✉️ Email'}
                </button>
              ))}
            </div>
            <input
              value={contact}
              onChange={e => setContact(e.target.value)}
              placeholder={contactType === 'phone' ? '+91XXXXXXXXXX' : 'you@example.com'}
              className="w-full rounded-lg border border-gray-700 bg-gray-800 px-4 py-2.5 text-white outline-none focus:border-emerald-500"
              required
            />
            <button type="submit" disabled={loading}
              className="w-full rounded-lg bg-emerald-600 py-2.5 font-medium text-white hover:bg-emerald-500 disabled:opacity-50">
              {loading ? 'Sending...' : 'Send OTP'}
            </button>
            {devOtp && <p className="text-xs text-amber-400">DEV MODE — OTP: <b>{devOtp}</b> (also in API console)</p>}
          </form>
        ) : (
          <form onSubmit={verifyOtp} className="space-y-4">
            <input
              value={otp}
              onChange={e => setOtp(e.target.value)}
              placeholder="Enter 6-digit OTP"
              maxLength={6}
              className="w-full rounded-lg border border-gray-700 bg-gray-800 px-4 py-2.5 text-center text-2xl tracking-[0.5em] text-white outline-none focus:border-emerald-500"
              required
            />
            <button type="submit" disabled={loading}
              className="w-full rounded-lg bg-emerald-600 py-2.5 font-medium text-white hover:bg-emerald-500 disabled:opacity-50">
              {loading ? 'Verifying...' : 'Verify & Login'}
            </button>
            <button type="button" onClick={() => { setStep('request'); setMsg(''); }} className="w-full text-sm text-gray-400 hover:text-white">
              ← Change number/email
            </button>
            {devOtp && <p className="text-xs text-amber-400">DEV MODE — OTP: <b>{devOtp}</b></p>}
          </form>
        )}

        {msg && <p className="mt-4 rounded-lg bg-emerald-500/10 p-3 text-sm text-emerald-400">{msg}</p>}
        {err && <p className="mt-4 rounded-lg bg-red-500/10 p-3 text-sm text-red-400">{err}</p>}
      </div>
    </div>
  );
}
