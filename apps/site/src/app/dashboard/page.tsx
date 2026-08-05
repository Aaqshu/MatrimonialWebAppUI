'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { HeartHandshake, LogOut, Sparkles, UserCircle2 } from 'lucide-react';

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

  useEffect(() => {
    api.get('/site/me')
      .then(({ data }) => setUser(data))
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

        <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
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
        </div>

        <div className="mt-6 rounded-xl border border-dashed border-white/15 bg-white/[0.02] p-10 text-center">
          <Sparkles className="mx-auto size-6 text-emerald-400/60" />
          <p className="mt-3 text-white/50">Profile builder coming next — Phase 2</p>
        </div>
      </div>
    </div>
  );
}
