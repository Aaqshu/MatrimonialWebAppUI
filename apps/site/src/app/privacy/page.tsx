'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { HeartHandshake, Loader2, Eye, Image, ShieldCheck, Wifi, Check } from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

type Scope = 'everyone' | 'matches_only' | 'premium_only' | 'nobody';
type ProfileScope = 'everyone' | 'same_community' | 'premium_only';

interface PrivacySettings {
  PhotoVisibility: Scope;
  ContactVisibility: Scope;
  ProfileVisibleTo: ProfileScope;
  ShowOnlineStatus: boolean;
}

const DEFAULTS: PrivacySettings = {
  PhotoVisibility: 'everyone',
  ContactVisibility: 'matches_only',
  ProfileVisibleTo: 'everyone',
  ShowOnlineStatus: true,
};

const SCOPE_LABELS: Record<Scope, string> = {
  everyone: 'Everyone',
  matches_only: 'Matches only',
  premium_only: 'Premium only',
  nobody: 'Nobody',
};

const PROFILE_SCOPE_LABELS: Record<ProfileScope, string> = {
  everyone: 'Everyone',
  same_community: 'Same community',
  premium_only: 'Premium only',
};

interface SelectRow {
  key: keyof PrivacySettings;
  label: string;
  description: string;
  icon: React.ComponentType<{ className?: string }>;
  options: string[];
}

const SELECT_ROWS: SelectRow[] = [
  { key: 'PhotoVisibility', label: 'Who can see my photos', description: 'Control photo visibility on your profile.', icon: Image, options: ['everyone', 'matches_only', 'premium_only', 'nobody'] },
  { key: 'ContactVisibility', label: 'Who can see my contact', description: 'Phone/email is revealed only to this audience.', icon: Eye, options: ['everyone', 'matches_only', 'premium_only', 'nobody'] },
  { key: 'ProfileVisibleTo', label: 'Profile visibility', description: 'Who can find your profile in search.', icon: ShieldCheck, options: ['everyone', 'same_community', 'premium_only'] },
];

export default function PrivacyPage() {
  const [ready, setReady] = useState(false);
  const [settings, setSettings] = useState<PrivacySettings>(DEFAULTS);
  const [savingKey, setSavingKey] = useState<keyof PrivacySettings | null>(null);
  const [toast, setToast] = useState('');

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) {
      window.location.href = '/';
      return;
    }
    api.get(`/site/privacy/${TENANT}`)
      .then(({ data }) => setSettings({ ...DEFAULTS, ...data }))
      .catch((e) => {
        if (e.response?.status === 401) { window.location.href = '/'; return; }
      })
      .finally(() => setReady(true));
  }, []);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 2000);
  }

  async function save(key: keyof PrivacySettings, value: string | boolean) {
    const prev = (settings as any)[key];
    setSettings(s => ({ ...s, [key]: value }));
    setSavingKey(key);
    try {
      const { data } = await api.patch(`/site/privacy/${TENANT}`, { [key]: value });
      setSettings(s => ({ ...s, ...data }));
      showToast('Privacy settings saved');
    } catch (e: any) {
      setSettings(s => ({ ...s, [key]: prev }));
      if (e.response?.status === 401) { window.location.href = '/'; return; }
      showToast('Could not save — please try again');
    } finally {
      setSavingKey(null);
    }
  }

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <span className="text-sm text-white/40">Privacy</span>
      </nav>

      <div className="mx-auto max-w-2xl px-6 py-10">
        <h1 className="text-2xl font-semibold tracking-tight">Privacy settings</h1>
        <p className="mt-1 text-sm text-white/50">Control who can see your profile and how it appears to others.</p>

        <div className="mt-8 space-y-6">
          {SELECT_ROWS.map((row) => {
            const Icon = row.icon;
            const isProfileScope = row.key === 'ProfileVisibleTo';
            const labels: Record<string, string> = isProfileScope ? PROFILE_SCOPE_LABELS : SCOPE_LABELS;
            return (
              <div key={row.key} className="rounded-2xl border border-white/8 bg-white/[0.03] p-5">
                <div className="flex items-start gap-3">
                  <div className="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-white/5 text-white/50">
                    <Icon className="size-4" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium text-white/90">{row.label}</p>
                    <p className="mt-0.5 text-xs text-white/40">{row.description}</p>
                    <div className="mt-3 flex flex-wrap gap-2">
                      {row.options.map((opt) => (
                        <button
                          key={opt}
                          type="button"
                          disabled={savingKey === row.key}
                          onClick={() => save(row.key, opt)}
                          className={`cursor-pointer rounded-full border px-3.5 py-1.5 text-xs font-medium transition-all disabled:cursor-wait ${
                            (settings as any)[row.key] === opt
                              ? 'border-emerald-500/60 bg-emerald-500/20 text-emerald-300'
                              : 'border-white/10 bg-white/5 text-white/50 hover:border-white/25 hover:text-white/80'
                          }`}
                        >
                          {labels[opt]}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}

          {/* Online status toggle */}
          <div className="flex items-center justify-between gap-4 rounded-2xl border border-white/8 bg-white/[0.03] p-5">
            <div className="flex items-start gap-3">
              <div className="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-white/5 text-white/50">
                <Wifi className="size-4" />
              </div>
              <div>
                <p className="text-sm font-medium text-white/90">Show online status</p>
                <p className="mt-0.5 text-xs text-white/40">Let others see when you&apos;re active.</p>
              </div>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={settings.ShowOnlineStatus}
              disabled={savingKey === 'ShowOnlineStatus'}
              onClick={() => save('ShowOnlineStatus', !settings.ShowOnlineStatus)}
              className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border transition-colors duration-200 disabled:cursor-wait ${
                settings.ShowOnlineStatus ? 'border-emerald-500/50 bg-emerald-500' : 'border-white/15 bg-white/10'
              }`}
            >
              <span
                className={`inline-block size-4.5 transform rounded-full bg-white shadow-sm transition-transform duration-200 ${
                  settings.ShowOnlineStatus ? 'translate-x-[22px]' : 'translate-x-0.5'
                }`}
              />
            </button>
          </div>
        </div>
      </div>

      {/* Toast */}
      <div
        className={`fixed bottom-6 left-1/2 -translate-x-1/2 transition-all duration-300 ${
          toast ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-3 opacity-0'
        }`}
      >
        <div className="flex items-center gap-2 rounded-full border border-emerald-500/30 bg-emerald-500/15 px-4 py-2 text-sm font-medium text-emerald-300 shadow-lg shadow-black/30 backdrop-blur-md">
          <Check className="size-4" />
          {toast}
        </div>
      </div>
    </div>
  );
}
