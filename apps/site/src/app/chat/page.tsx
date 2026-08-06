'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { HeartHandshake, Loader2, MessageCircle, MessagesSquare, Send, ArrowLeft } from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';
const POLL_MS = 3000;

interface Thread {
  UserId: string;
  FirstName: string;
  LastName: string;
  City: string | null;
  PhotoUrl: string | null;
  LastMessage: string | null;
  LastSentOn: string | null;
  UnreadCount: number;
}

interface Message {
  MessageId: string;
  SenderUserId: string;
  ReceiverUserId: string;
  Message: string;
  IsRead: boolean;
  SentOn: string;
}

function timeLabel(iso: string | null) {
  if (!iso) return '';
  const d = new Date(iso);
  const now = new Date();
  const sameDay = d.toDateString() === now.toDateString();
  if (sameDay) return d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
}

export default function ChatPage() {
  const [ready, setReady] = useState(false);
  const [meId, setMeId] = useState('');
  const [threads, setThreads] = useState<Thread[]>([]);
  const [threadsLoading, setThreadsLoading] = useState(true);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [msgLoading, setMsgLoading] = useState(false);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const [toast, setToast] = useState('');
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) { window.location.href = '/'; return; }
    api.get('/site/me')
      .then(({ data }) => { setMeId(data.UserId); setReady(true); })
      .catch((e) => { if (e.response?.status === 401) window.location.href = '/'; });
  }, []);

  const loadThreads = () => {
    api.get(`/site/messages/${TENANT}/threads`)
      .then(({ data }) => setThreads(data.threads ?? []))
      .catch((e) => { if (e.response?.status === 401) window.location.href = '/'; })
      .finally(() => setThreadsLoading(false));
  };

  useEffect(() => {
    if (!ready) return;
    loadThreads();
    const t = setInterval(loadThreads, POLL_MS);
    return () => clearInterval(t);
  }, [ready]);

  const loadMessages = (userId: string, initial = false) => {
    if (initial) setMsgLoading(true);
    api.get(`/site/messages/${TENANT}/${userId}`)
      .then(({ data }) => setMessages(data.messages ?? []))
      .catch((e) => { if (e.response?.status === 401) window.location.href = '/'; })
      .finally(() => setMsgLoading(false));
  };

  useEffect(() => {
    if (!activeId) return;
    loadMessages(activeId, true);
    const t = setInterval(() => loadMessages(activeId), POLL_MS);
    return () => clearInterval(t);
  }, [activeId]);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' });
  }, [messages]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 2500);
  };

  const send = async () => {
    const text = input.trim();
    if (!text || !activeId || sending) return;
    setSending(true);
    setInput('');
    try {
      await api.post(`/site/messages/${TENANT}`, { toUserId: activeId, message: text });
      loadMessages(activeId);
      loadThreads();
    } catch (e: any) {
      if (e.response?.status === 401) { window.location.href = '/'; return; }
      showToast(e.response?.data?.message || 'Could not send message');
      setInput(text);
    } finally {
      setSending(false);
    }
  };

  const handleKey = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  };

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  const activeThread = threads.find(t => t.UserId === activeId) || null;
  const totalUnread = threads.reduce((s, t) => s + (t.UnreadCount || 0), 0);

  return (
    <div className="flex h-screen flex-col bg-background text-white">
      <nav className="flex shrink-0 items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <span className="text-sm text-white/40">
          Messages{totalUnread > 0 ? ` · ${totalUnread} unread` : ''}
        </span>
      </nav>

      <div className="mx-auto flex w-full max-w-6xl flex-1 overflow-hidden px-0 sm:px-6 sm:py-6">
        <div className="grid w-full flex-1 grid-cols-1 overflow-hidden rounded-none border-white/10 bg-white/[0.02] sm:grid-cols-[300px_1fr] sm:rounded-2xl sm:border">
          {/* Thread list */}
          <aside className={`${activeId ? 'hidden sm:flex' : 'flex'} flex-col overflow-hidden border-white/8 sm:border-r`}>
            <div className="shrink-0 border-b border-white/8 px-4 py-3">
              <p className="text-sm font-medium text-white/80">Conversations</p>
            </div>
            <div className="flex-1 overflow-y-auto">
              {threadsLoading ? (
                <div className="flex items-center justify-center py-16 text-white/40">
                  <Loader2 className="size-5 animate-spin" />
                </div>
              ) : threads.length === 0 ? (
                <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
                  <MessagesSquare className="size-8 text-white/20" />
                  <p className="text-sm text-white/50">You have no conversations yet — accept interests to start chatting</p>
                  <Link href="/matches" className="mt-1 text-sm text-emerald-400 hover:text-emerald-300">
                    Go to matches →
                  </Link>
                </div>
              ) : (
                threads.map(t => {
                  const initials = `${t.FirstName?.[0] ?? ''}${t.LastName?.[0] ?? ''}`.toUpperCase();
                  const isActive = t.UserId === activeId;
                  return (
                    <button
                      key={t.UserId}
                      onClick={() => setActiveId(t.UserId)}
                      className={`flex w-full cursor-pointer items-center gap-3 border-b border-white/5 px-4 py-3 text-left transition-colors duration-150 ${
                        isActive ? 'bg-emerald-500/10' : 'hover:bg-white/[0.04]'
                      }`}
                    >
                      {t.PhotoUrl ? (
                        <img src={t.PhotoUrl} alt={t.FirstName} className="size-11 shrink-0 rounded-full object-cover" />
                      ) : (
                        <div className="flex size-11 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-emerald-500/25 to-amber-500/25 text-sm font-semibold">
                          {initials}
                        </div>
                      )}
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center justify-between gap-2">
                          <p className="truncate text-sm font-medium">{t.FirstName} {t.LastName}</p>
                          <span className="shrink-0 text-[11px] text-white/35">{timeLabel(t.LastSentOn)}</span>
                        </div>
                        <div className="mt-0.5 flex items-center justify-between gap-2">
                          <p className="truncate text-xs text-white/45">{t.LastMessage || 'Say hello 👋'}</p>
                          {t.UnreadCount > 0 && (
                            <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-emerald-500 text-[10px] font-bold text-emerald-950">
                              {t.UnreadCount}
                            </span>
                          )}
                        </div>
                      </div>
                    </button>
                  );
                })
              )}
            </div>
          </aside>

          {/* Conversation */}
          <section className={`${activeId ? 'flex' : 'hidden sm:flex'} flex-col overflow-hidden`}>
            {!activeThread ? (
              <div className="flex flex-1 flex-col items-center justify-center gap-2 text-center text-white/40">
                <MessageCircle className="size-8 text-white/20" />
                <p className="text-sm">Select a conversation to start chatting</p>
              </div>
            ) : (
              <>
                <div className="flex shrink-0 items-center gap-3 border-b border-white/8 px-4 py-3">
                  <button
                    onClick={() => setActiveId(null)}
                    className="flex size-8 shrink-0 cursor-pointer items-center justify-center rounded-lg text-white/50 transition-colors hover:bg-white/5 hover:text-white sm:hidden"
                  >
                    <ArrowLeft className="size-4" />
                  </button>
                  {activeThread.PhotoUrl ? (
                    <img src={activeThread.PhotoUrl} alt={activeThread.FirstName} className="size-9 shrink-0 rounded-full object-cover" />
                  ) : (
                    <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-emerald-500/25 to-amber-500/25 text-xs font-semibold">
                      {`${activeThread.FirstName?.[0] ?? ''}${activeThread.LastName?.[0] ?? ''}`.toUpperCase()}
                    </div>
                  )}
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium">{activeThread.FirstName} {activeThread.LastName}</p>
                    {activeThread.City && <p className="truncate text-xs text-white/40">{activeThread.City}</p>}
                  </div>
                </div>

                <div ref={scrollRef} className="flex-1 space-y-2.5 overflow-y-auto px-4 py-4">
                  {msgLoading ? (
                    <div className="flex items-center justify-center py-16 text-white/40">
                      <Loader2 className="size-5 animate-spin" />
                    </div>
                  ) : messages.length === 0 ? (
                    <div className="flex h-full flex-col items-center justify-center gap-1 text-center text-white/40">
                      <p className="text-sm">No messages yet</p>
                      <p className="text-xs text-white/30">Send the first message below</p>
                    </div>
                  ) : (
                    messages.map(m => {
                      const mine = m.SenderUserId === meId;
                      return (
                        <div key={m.MessageId} className={`flex ${mine ? 'justify-end' : 'justify-start'}`}>
                          <div
                            className={`max-w-[75%] rounded-2xl px-3.5 py-2 text-sm ${
                              mine
                                ? 'rounded-br-sm bg-emerald-500 text-emerald-950'
                                : 'rounded-bl-sm border border-white/10 bg-white/[0.05] text-white'
                            }`}
                          >
                            <p className="whitespace-pre-wrap break-words">{m.Message}</p>
                            <p className={`mt-1 text-right text-[10px] ${mine ? 'text-emerald-950/60' : 'text-white/35'}`}>
                              {timeLabel(m.SentOn)}
                            </p>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>

                <div className="flex shrink-0 items-center gap-2 border-t border-white/8 p-3">
                  <input
                    value={input}
                    onChange={e => setInput(e.target.value)}
                    onKeyDown={handleKey}
                    placeholder="Type a message…"
                    className="flex-1 rounded-full border border-white/10 bg-white/[0.03] px-4 py-2.5 text-sm text-white outline-none transition-colors placeholder:text-white/30 focus:border-emerald-500/60 focus:ring-3 focus:ring-emerald-500/15"
                  />
                  <button
                    onClick={send}
                    disabled={!input.trim() || sending}
                    className="flex size-10 shrink-0 cursor-pointer items-center justify-center rounded-full bg-emerald-500 text-emerald-950 transition-colors hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-40"
                  >
                    {sending ? <Loader2 className="size-4 animate-spin" /> : <Send className="size-4" />}
                  </button>
                </div>
              </>
            )}
          </section>
        </div>
      </div>

      {/* Toast */}
      <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 transition-all duration-300 ${toast ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-3 opacity-0'}`}>
        <div className="flex items-center gap-2 rounded-full border border-red-500/30 bg-red-500/15 px-4 py-2 text-sm font-medium text-red-300 shadow-lg shadow-black/30 backdrop-blur-md">
          {toast}
        </div>
      </div>
    </div>
  );
}
