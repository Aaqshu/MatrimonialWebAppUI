'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { ArrowRight, Bell, HeartHandshake, ImagePlus, Loader2, Lock, LogOut, MessageCircle, SearchIcon, ShieldCheck, CheckCircle2 } from 'lucide-react';

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
  const [pendingInterests, setPendingInterests] = useState(0);
  const [unreadMessages, setUnreadMessages] = useState(0);
  const [unreadNotifications, setUnreadNotifications] = useState(0);

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
        return api.get(`/site/matches/${TENANT}`).catch(() => null);
      })
      .then((m: any) => {
        if (m?.data?.received) {
          setPendingInterests(m.data.received.filter((r: any) => r.Status === 'pending').length);
        }
        return api.get(`/site/messages/${TENANT}/threads`).catch(() => null);
      })
      .then((th: any) => {
        const sum = (th?.data?.threads ?? []).reduce((s: number, t: any) => s + (t.UnreadCount || 0), 0);
        setUnreadMessages(sum);
        return api.get(`/site/notifications/${TENANT}`).catch(() => null);
      })
      .then((nf: any) => {
        setUnreadNotifications(nf?.data?.unreadCount ?? 0);
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
        <Loader2 className="size-5 animate-spin" />
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

      <div className="mx-auto max-w-4xl px-6 py-10">
        <h1 className="text-2xl font-semibold tracking-tight">Welcome, {user.FirstName}!</h1>
        <p className="mt-1 text-sm text-white/50">Here&apos;s where your journey begins</p>

        {/* Profile completion card — links to the builder */}
        <Link
          href="/profile"
          className="group mt-6 block rounded-2xl border border-emerald-500/25 bg-gradient-to-br from-emerald-500/10 via-transparent to-amber-500/10 p-6 transition-all duration-200 hover:border-emerald-500/50 hover:shadow-lg hover:shadow-emerald-500/10"
        >
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-3.5">
              <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-emerald-500 text-emerald-950 shadow-lg shadow-emerald-500/20">
                {hasProfile && completion === 100 ? <CheckCircle2 className="size-5" /> : <HeartHandshake className="size-5" />}
              </div>
              <div>
                <p className="font-medium">
                  {hasProfile
                    ? completion === 100 ? 'Profile complete!' : 'Continue building your profile'
                    : 'Create your profile'}
                </p>
                <p className="mt-0.5 text-sm text-white/50">
                  {hasProfile
                    ? completion === 100 ? 'You look great — matches are coming soon.' : 'A complete profile gets 3× more matches.'
                    : 'Your profile is the first thing others see.'}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              {completion !== null && (
                <div className="text-right">
                  <p className="text-xl font-semibold tabular-nums text-emerald-400">{completion}%</p>
                  <p className="text-xs text-white/40">complete</p>
                </div>
              )}
              <ArrowRight className="size-5 text-white/40 transition-transform group-hover:translate-x-0.5" />
            </div>
          </div>
          {/* progress bar */}
          <div className="mt-4 h-1.5 overflow-hidden rounded-full bg-white/8">
            <div
              className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-amber-500 transition-all duration-500"
              style={{ width: `${completion ?? 0}%` }}
            />
          </div>
        </Link>

        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
          <Link href="/photos" className="rounded-xl border border-white/8 bg-white/[0.03] p-5 transition-all duration-200 hover:border-white/20 hover:bg-white/[0.05]">
            <div className="flex size-9 items-center justify-center rounded-lg bg-white/5 text-white/60">
              <ImagePlus className="size-4" />
            </div>
            <p className="mt-3 text-xs font-medium uppercase tracking-wide text-white/40">Photos</p>
            <p className="mt-1 text-base font-medium">Manage photos</p>
          </Link>
          <Link href="/verification" className="rounded-xl border border-white/8 bg-white/[0.03] p-5 transition-all duration-200 hover:border-amber-500/30 hover:bg-white/[0.05]">
            <div className="flex size-9 items-center justify-center rounded-lg bg-amber-500/10 text-amber-400">
              <ShieldCheck className="size-4" />
            </div>
            <p className="mt-3 text-xs font-medium uppercase tracking-wide text-white/40">Verification</p>
            <p className="mt-1 text-base font-medium text-amber-400">Get verified</p>
          </Link>
          <Link href="/privacy" className="rounded-xl border border-white/8 bg-white/[0.03] p-5 transition-all duration-200 hover:border-white/20 hover:bg-white/[0.05]">
            <div className="flex size-9 items-center justify-center rounded-lg bg-white/5 text-white/60">
              <Lock className="size-4" />
            </div>
            <p className="mt-3 text-xs font-medium uppercase tracking-wide text-white/40">Privacy</p>
            <p className="mt-1 text-base font-medium">Control visibility</p>
          </Link>
        </div>

        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Link href="/matches" className="block rounded-2xl border border-emerald-500/25 bg-gradient-to-br from-emerald-500/10 to-transparent p-6 transition-all duration-200 hover:border-emerald-500/50 hover:shadow-lg hover:shadow-emerald-500/10">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3.5">
                <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-emerald-500 text-emerald-950 shadow-lg shadow-emerald-500/20">
                  <HeartHandshake className="size-5" />
                </div>
                <div>
                  <p className="font-medium">Your matches</p>
                  <p className="mt-0.5 text-sm text-white/50">
                    {pendingInterests > 0 ? `${pendingInterests} new interest${pendingInterests > 1 ? 's' : ''} waiting` : 'No new interests yet'}
                  </p>
                </div>
              </div>
              {pendingInterests > 0 && (
                <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-emerald-500 text-sm font-bold text-emerald-950">
                  {pendingInterests}
                </span>
              )}
            </div>
          </Link>
          <Link href="/search" className="block rounded-2xl border border-white/8 bg-white/[0.03] p-6 transition-all duration-200 hover:border-white/20 hover:bg-white/[0.05]">
            <div className="flex items-center gap-3.5">
              <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-white/5 text-white/60">
                <SearchIcon className="size-5" />
              </div>
              <div>
                <p className="font-medium">Find matches</p>
                <p className="mt-0.5 text-sm text-white/50">Search profiles by religion, city &amp; more</p>
              </div>
            </div>
          </Link>
        </div>

        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Link href="/chat" className="block rounded-2xl border border-white/8 bg-white/[0.03] p-6 transition-all duration-200 hover:border-emerald-500/30 hover:bg-white/[0.05]">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3.5">
                <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-white/5 text-white/60">
                  <MessageCircle className="size-5" />
                </div>
                <div>
                  <p className="font-medium">Messages</p>
                  <p className="mt-0.5 text-sm text-white/50">
                    {unreadMessages > 0 ? `${unreadMessages} unread message${unreadMessages > 1 ? 's' : ''}` : 'No new messages'}
                  </p>
                </div>
              </div>
              {unreadMessages > 0 && (
                <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-emerald-500 text-sm font-bold text-emerald-950">
                  {unreadMessages}
                </span>
              )}
            </div>
          </Link>
          <Link href="/notifications" className="block rounded-2xl border border-white/8 bg-white/[0.03] p-6 transition-all duration-200 hover:border-amber-500/30 hover:bg-white/[0.05]">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3.5">
                <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-white/5 text-white/60">
                  <Bell className="size-5" />
                </div>
                <div>
                  <p className="font-medium">Notifications</p>
                  <p className="mt-0.5 text-sm text-white/50">
                    {unreadNotifications > 0 ? `${unreadNotifications} unread` : 'You\'re all caught up'}
                  </p>
                </div>
              </div>
              {unreadNotifications > 0 && (
                <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-amber-500 text-sm font-bold text-amber-950">
                  {unreadNotifications}
                </span>
              )}
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
}
