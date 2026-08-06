'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { Bell, BellOff, CheckCheck, HeartHandshake, Loader2, MessageCircle, Heart } from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

interface Notification {
  NotificationId: string;
  Title: string;
  Message: string;
  IsRead: boolean;
  CreatedOn: string;
}

function iconFor(title: string) {
  const t = title.toLowerCase();
  if (t.includes('message')) return MessageCircle;
  if (t.includes('interest') || t.includes('match')) return Heart;
  return Bell;
}

function timeAgo(iso: string) {
  const d = new Date(iso);
  const diffMs = Date.now() - d.getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
}

export default function NotificationsPage() {
  const [ready, setReady] = useState(false);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [marking, setMarking] = useState(false);

  const load = () => {
    api.get(`/site/notifications/${TENANT}`)
      .then(({ data }) => {
        setNotifications(data.notifications ?? []);
        setUnreadCount(data.unreadCount ?? 0);
      })
      .catch((e) => { if (e.response?.status === 401) window.location.href = '/'; })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) { window.location.href = '/'; return; }
    setReady(true);
    load();
  }, []);

  const markAllRead = async () => {
    if (unreadCount === 0 || marking) return;
    setMarking(true);
    try {
      await api.patch(`/site/notifications/${TENANT}/read`);
      setNotifications(prev => prev.map(n => ({ ...n, IsRead: true })));
      setUnreadCount(0);
    } catch (e: any) {
      if (e.response?.status === 401) window.location.href = '/';
    } finally {
      setMarking(false);
    }
  };

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
        <span className="text-sm text-white/40">Notifications</span>
      </nav>

      <div className="mx-auto max-w-2xl px-6 py-10">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">Notifications</h1>
            <p className="mt-1 text-sm text-white/50">
              {unreadCount > 0 ? `${unreadCount} unread notification${unreadCount > 1 ? 's' : ''}` : 'You\'re all caught up'}
            </p>
          </div>
          <button
            onClick={markAllRead}
            disabled={unreadCount === 0 || marking}
            className="flex shrink-0 cursor-pointer items-center gap-1.5 rounded-full border border-white/10 px-3.5 py-2 text-sm font-medium text-white/70 transition-colors hover:border-emerald-500/40 hover:text-emerald-300 disabled:cursor-not-allowed disabled:opacity-40"
          >
            {marking ? <Loader2 className="size-3.5 animate-spin" /> : <CheckCheck className="size-3.5" />}
            Mark all read
          </button>
        </div>

        <div className="mt-6 space-y-2">
          {loading ? (
            <div className="flex items-center justify-center py-20 text-white/40">
              <Loader2 className="size-6 animate-spin" />
            </div>
          ) : notifications.length === 0 ? (
            <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-white/10 bg-white/[0.02] py-20 text-center">
              <BellOff className="size-8 text-white/20" />
              <p className="text-sm text-white/50">No notifications yet</p>
            </div>
          ) : (
            notifications.map(n => {
              const Icon = iconFor(n.Title);
              return (
                <div
                  key={n.NotificationId}
                  className={`flex items-start gap-3.5 rounded-xl border-l-2 border border-white/8 bg-white/[0.03] p-4 transition-colors duration-150 hover:bg-white/[0.04] ${
                    !n.IsRead ? 'border-l-emerald-500' : 'border-l-transparent'
                  }`}
                >
                  <div className={`flex size-9 shrink-0 items-center justify-center rounded-lg ${
                    !n.IsRead ? 'bg-emerald-500/15 text-emerald-400' : 'bg-white/5 text-white/50'
                  }`}>
                    <Icon className="size-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className={`text-sm font-medium ${!n.IsRead ? 'text-white' : 'text-white/70'}`}>{n.Title}</p>
                      {!n.IsRead && <span className="size-1.5 shrink-0 rounded-full bg-emerald-400" />}
                    </div>
                    <p className="mt-0.5 text-sm text-white/50">{n.Message}</p>
                    <p className="mt-1.5 text-xs text-white/35">{timeAgo(n.CreatedOn)}</p>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
