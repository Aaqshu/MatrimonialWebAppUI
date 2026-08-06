'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { Bell, Heart, MessageCircle, X } from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';
const POLL_MS = 5000;
const TOAST_MS = 6000;

interface Notif {
  NotificationId: string;
  Title: string;
  Message: string | null;
  IsRead: boolean;
  CreatedOn: string;
  RefUserId?: string | null;
}

const TITLE_ICON: Record<string, React.ComponentType<{ className?: string }>> = {
  'New message': MessageCircle,
  Interest: Heart,
};

export default function NotificationToast() {
  const [toast, setToast] = useState<Notif | null>(null);
  const seen = useRef<Set<string>>(new Set());
  const dismissTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const showToast = useCallback((n: Notif) => {
    setToast(n);
    if (dismissTimer.current) clearTimeout(dismissTimer.current);
    dismissTimer.current = setTimeout(() => setToast(null), TOAST_MS);
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) return;

    const poll = () => {
      api.get(`/site/notifications/${TENANT}`)
        .then(({ data }) => {
          const list: Notif[] = data.notifications ?? [];
          for (const n of list) {
            if (!n.IsRead && !seen.current.has(n.NotificationId)) {
              seen.current.add(n.NotificationId);
              showToast(n);
            }
          }
        })
        .catch(() => {});
    };

    poll();
    const t = setInterval(poll, POLL_MS);
    return () => clearInterval(t);
  }, [showToast]);

  if (!toast) return null;
  const Icon = TITLE_ICON[toast.Title] || Bell;
  // click → chat window for messages, profile for interest
  const href = toast.Title === 'New message' && toast.RefUserId
    ? `/chat?userId=${toast.RefUserId}`
    : toast.Title === 'Interest' && toast.RefUserId
      ? `/profile/${toast.RefUserId}`
      : '/notifications';

  return (
    <div className="fixed right-4 top-4 z-50 sm:right-6 sm:top-6">
      <Link
        href={href}
        onClick={() => setToast(null)}
        className={`animate-slide-in-right block w-80 overflow-hidden rounded-2xl border border-emerald-500/25 bg-zinc-900/95 shadow-2xl shadow-black/50 backdrop-blur-md transition-colors hover:border-emerald-500/50 ${toast.Title === 'New message' ? 'cursor-pointer' : ''}`}
      >
        <div className="flex items-start gap-3 p-4">
          <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-emerald-500/15 text-emerald-400">
            <Icon className="size-5" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-white">{toast.Title}</p>
            <p className="mt-0.5 line-clamp-2 text-xs text-white/60">{toast.Message}</p>
            {toast.Title === 'New message' && (
              <span className="mt-2 inline-block text-xs font-medium text-emerald-400">
                Open chat →
              </span>
            )}
          </div>
          <button
            onClick={(e) => { e.preventDefault(); e.stopPropagation(); setToast(null); }}
            className="shrink-0 cursor-pointer rounded-lg p-1 text-white/40 transition-colors hover:bg-white/10 hover:text-white"
            aria-label="Dismiss"
          >
            <X className="size-4" />
          </button>
        </div>
      </Link>
    </div>
  );
}
