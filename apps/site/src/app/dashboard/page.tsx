'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { ArrowRight, HeartHandshake, LogOut, ShieldCheck, Sparkles, UserCircle2, CheckCircle2 } from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

interface User {
  UserId: string;
  FirstName: string;
  LastName: string;
  Email: string;
  Phone: string;
  Status: string;
}

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null);
  const [completion, setCompletion] = useState<number | null>(null);
  const [hasProfile, setHasProfile] = useState(false);

  useEffect(() => {
    api.get('/site/me')
      .then(({ data }) => {
        setUser(data);
        return api.get(`/site/profile/${TENANT}`).catch(() => null);
      })
      .then((res: any) => {
        if (res?.data?.profile) {
          setHasProfile(true);
          setCompletion(res.data.profile.ProfileCompletionPercent ?? 0);
        }
      })
      .catch(() => { window.location.href = '/'; });
  }, []);

  const logout = () => {
    localStorage.removeItem('site_token');
    window.location.href = '/';
  };

  if (!user) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        Loading…
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <div className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </div>
        <button
          onClick={logout}
          className="flex cursor-pointer items-center gap-1.5 text-sm text-white/50 transition-colors hover:text-white"
        >
          <LogOut className="size-4" />
          Sign Out
        </button>
      </nav>

      <div className="mx-auto max-w-4xl p-8">
        <h2 className="text-2xl font-semibold tracking-tight">Welcome, {user.FirstName}!</h2>
        <p className="mt-1 text-sm text-white/50">Here&apos;s where your journey begins</p>

        {/* Profile completion card — links to the builder */}
        <Link
          href="/profile"
          className="mt-6 block rounded-2xl border border-emerald-500/25 bg-gradient-to-br from-emerald-500/10 via-transparent to-amber-500/10 p-6 transition-all hover:border-emerald-500/50 hover:shadow-lg hover:shadow-emerald-500/5"
        >
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="flex size-10 items-center justify-center rounded-xl bg-emerald-500 text-emerald-950">
                {hasProfile && completion === 100 ? <CheckCircle2 className="size-5" /> : <UserCircle2 className="size-5" />}
              </div>
              <div>
                <p className="font-medium">
                  {hasProfile
                    ? completion === 100 ? 'Profile complete!' : 'Continue building your profile'
                    : 'Create your profile'}
                </p>
                <p className="text-sm text-white/50">
                  {hasProfile
                    ? completion === 100 ? 'You look great — matches are coming soon.' : 'A complete profile gets 3× more matches.'
                    : 'Your profile is the first thing others see.'}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              {completion !== null && (
                <div className="text-right">
                  <p className="text-xl font-semibold text-emerald-400">{completion}%</p>
                  <p className="text-xs text-white/40">complete</p>
                </div>
              )}
              <ArrowRight className="size-5 text-white/40" />
            </div>
          </div>
          {/* progress bar */}
          <div className="mt-4 h-1.5 overflow-hidden rounded-full bg-white/8">
            <div
              className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-amber-500 transition-all"
              style={{ width: `${completion ?? 0}%` }}
            />
          </div>
        </Link>

        <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div className="rounded-xl border border-white/8 bg-white/[0.03] p-5">
            <div className="flex items-center gap-2 text-white/50">
              <UserCircle2 className="size-4" />
              <p className="text-sm">Profile Status</p>
            </div>
            <p className="mt-2 text-lg font-medium capitalize">{user.Status.replace('_', ' ')}</p>
          </div>
          <div className="rounded-xl border border-white/8 bg-white/[0.03] p-5">
            <div className="flex items-center gap-2 text-white/50">
              <Sparkles className="size-4" />
              <p className="text-sm">Contact</p>
            </div>
            <p className="mt-2 text-lg font-medium">{user.Phone || user.Email}</p>
          </div>
          <div className="rounded-xl border border-white/8 bg-white/[0.03] p-5">
            <div className="flex items-center gap-2 text-white/50">
              <ShieldCheck className="size-4" />
              <p className="text-sm">Verification</p>
            </div>
            <p className="mt-2 text-lg font-medium text-amber-400">Pending</p>
          </div>
        </div>

        <div className="mt-6 rounded-xl border border-dashed border-white/15 bg-white/[0.02] p-8 text-center">
          <Sparkles className="mx-auto size-6 text-emerald-400/60" />
          <p className="mt-3 text-white/50">Daily matches, chat &amp; more — coming in the next phase</p>
        </div>
      </div>
    </div>
  );
}
