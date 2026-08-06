'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { Check, CheckCheck, HeartHandshake, Inbox, Loader2, MessageCircle, Send, X } from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

interface InterestItem {
  InterestRequestId: string;
  FromUserId: string;
  FromFirstName: string;
  FromAge: number;
  FromCity: string;
  FromPhotoUrl: string | null;
  Status: string;
  ToUserId: string;
  ToFirstName: string;
  ToAge: number;
  ToPhotoUrl: string | null;
}

const STATUS_STYLE: Record<string, string> = {
  pending: 'border-amber-500/30 bg-amber-500/10 text-amber-300',
  accepted: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-300',
  declined: 'border-white/15 bg-white/5 text-white/50',
};

const STATUS_DOT: Record<string, string> = {
  pending: 'bg-amber-400',
  accepted: 'bg-emerald-400',
  declined: 'bg-white/40',
};

export default function MatchesPage() {
  const [tab, setTab] = useState<'received' | 'sent'>('received');
  const [received, setReceived] = useState<InterestItem[]>([]);
  const [sent, setSent] = useState<InterestItem[]>([]);
  const [busyId, setBusyId] = useState('');
  const [toast, setToast] = useState('');

  const load = () => {
    api.get(`/site/matches/${TENANT}`)
      .then(({ data }) => { setReceived(data.received); setSent(data.sent); })
      .catch((e) => { if (e.response?.status === 401) window.location.href = '/'; });
  };

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) { window.location.href = '/'; return; }
    load();
  }, []);

  const respond = async (id: string, status: 'accepted' | 'declined') => {
    setBusyId(id);
    try {
      await api.patch(`/site/interests/${TENANT}/${id}`, { status });
      showToast(status === 'accepted' ? 'Interest accepted — you matched!' : 'Interest declined');
      load();
    } catch (e: any) {
      showToast(e.response?.data?.message || 'Action failed');
    } finally {
      setBusyId('');
    }
  };

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 2500);
  };

  const renderCard = (item: InterestItem, isReceived: boolean) => {
    const name = isReceived ? item.FromFirstName : item.ToFirstName;
    const age = isReceived ? item.FromAge : item.ToAge;
    const city = isReceived ? item.FromCity : '';
    const photo = isReceived ? item.FromPhotoUrl : item.ToPhotoUrl;
    const id = isReceived ? item.FromUserId : item.ToUserId;
    const initials = (name || '?')[0]?.toUpperCase();
    const showActions = isReceived && item.Status === 'pending';

    return (
      <div key={item.InterestRequestId} className="flex items-center gap-4 rounded-2xl border border-white/8 bg-white/[0.03] p-4 transition-colors duration-150 hover:border-white/20 hover:bg-white/[0.04]">
        {photo ? (
          <img src={photo} alt={name} className="size-14 shrink-0 rounded-xl object-cover" />
        ) : (
          <div className="flex size-14 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-500/25 to-amber-500/25 text-lg font-semibold">
            {initials}
          </div>
        )}
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <Link href={`/profile/${id}`} className="truncate font-medium transition-colors hover:text-emerald-300">
              {name}{age ? `, ${age}` : ''}
            </Link>
            <span className={`inline-flex items-center gap-1.5 rounded-full border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${STATUS_STYLE[item.Status] || ''}`}>
              <span className={`size-1.5 rounded-full ${STATUS_DOT[item.Status] || 'bg-white/40'}`} />
              {item.Status}
            </span>
          </div>
          {city && <p className="mt-1 truncate text-xs text-white/40">{city}</p>}
        </div>
        {showActions && (
          <div className="flex shrink-0 gap-2">
            <button
              onClick={() => respond(item.InterestRequestId, 'accepted')}
              disabled={busyId === item.InterestRequestId}
              className="flex cursor-pointer items-center gap-1 rounded-full bg-emerald-500 px-3.5 py-2 text-xs font-semibold text-emerald-950 transition-colors hover:bg-emerald-400 disabled:cursor-wait disabled:opacity-50"
            >
              <Check className="size-3.5" /> Accept
            </button>
            <button
              onClick={() => respond(item.InterestRequestId, 'declined')}
              disabled={busyId === item.InterestRequestId}
              className="flex cursor-pointer items-center gap-1 rounded-full border border-white/15 px-3.5 py-2 text-xs font-medium text-white/60 transition-colors hover:border-red-500/40 hover:text-red-300 disabled:cursor-wait disabled:opacity-50"
            >
              <X className="size-3.5" /> Decline
            </button>
          </div>
        )}
        {item.Status === 'accepted' && (
          <Link
            href={`/chat?userId=${id}`}
            className="flex shrink-0 items-center gap-1.5 rounded-full border border-emerald-500/40 bg-emerald-500/10 px-3.5 py-2 text-xs font-semibold text-emerald-300 transition-colors hover:bg-emerald-500/20"
          >
            <MessageCircle className="size-3.5" /> Chat
          </Link>
        )}
      </div>
    );
  };

  const list = tab === 'received' ? received : sent;
  const pendingCount = received.filter(r => r.Status === 'pending').length;

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <Link href="/search" className="text-sm text-white/50 transition-colors hover:text-white">Search profiles →</Link>
      </nav>

      <div className="mx-auto max-w-3xl px-6 py-10">
        <h1 className="text-2xl font-semibold tracking-tight">Matches &amp; Interests</h1>
        <p className="mt-1 text-sm text-white/50">Interests sent and received on your profile</p>

        {/* Tabs */}
        <div className="mt-6 inline-flex gap-1 rounded-full border border-white/8 bg-white/[0.03] p-1">
          <button
            onClick={() => setTab('received')}
            className={`flex cursor-pointer items-center gap-1.5 rounded-full px-4 py-1.5 text-sm font-medium transition-colors duration-150 ${
              tab === 'received' ? 'bg-emerald-500/15 text-emerald-300' : 'text-white/50 hover:text-white'
            }`}
          >
            <Inbox className="size-4" /> Received
            {pendingCount > 0 && (
              <span className="flex size-5 items-center justify-center rounded-full bg-emerald-500 text-[10px] font-bold text-emerald-950">
                {pendingCount}
              </span>
            )}
          </button>
          <button
            onClick={() => setTab('sent')}
            className={`flex cursor-pointer items-center gap-1.5 rounded-full px-4 py-1.5 text-sm font-medium transition-colors duration-150 ${
              tab === 'sent' ? 'bg-emerald-500/15 text-emerald-300' : 'text-white/50 hover:text-white'
            }`}
          >
            <Send className="size-4" /> Sent
          </button>
        </div>

        {/* List */}
        <div className="mt-4 space-y-3">
          {list.length === 0 ? (
            <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-white/10 bg-white/[0.02] py-20 text-center">
              <CheckCheck className="size-8 text-white/20" />
              <p className="text-sm text-white/50">
                {tab === 'received' ? 'No interests received yet' : 'No interests sent yet'}
              </p>
              {tab === 'received' && (
                <Link href="/search" className="mt-1 text-sm text-emerald-400 hover:text-emerald-300">
                  Find profiles to connect with
                </Link>
              )}
            </div>
          ) : (
            list.map(item => renderCard(item, tab === 'received'))
          )}
        </div>
      </div>

      {/* Toast */}
      <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 transition-all duration-300 ${toast ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-3 opacity-0'}`}>
        <div className="flex items-center gap-2 rounded-full border border-emerald-500/30 bg-emerald-500/15 px-4 py-2 text-sm font-medium text-emerald-300 shadow-lg shadow-black/30 backdrop-blur-md">
          <HeartHandshake className="size-4" /> {toast}
        </div>
      </div>
    </div>
  );
}
