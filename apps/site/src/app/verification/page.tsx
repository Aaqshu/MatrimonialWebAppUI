'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import {
  HeartHandshake, ShieldCheck, ShieldAlert, ShieldQuestion, Loader2, Check,
  CreditCard, FileText, BadgeCheck, Car, Mail as MailIcon,
} from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

type DocType = 'aadhaar' | 'pan' | 'passport' | 'driving_license' | 'work_email';
type Status = 'pending' | 'verified' | 'rejected';

interface VerificationRequest {
  VerificationId: string;
  DocType: DocType;
  DocReference: string;
  Status: Status;
  CreatedOn: string;
}

const DOC_TYPES: { value: DocType; label: string; icon: React.ComponentType<{ className?: string }>; placeholder: string }[] = [
  { value: 'aadhaar', label: 'Aadhaar', icon: CreditCard, placeholder: 'Aadhaar number' },
  { value: 'pan', label: 'PAN', icon: FileText, placeholder: 'PAN number' },
  { value: 'passport', label: 'Passport', icon: BadgeCheck, placeholder: 'Passport number' },
  { value: 'driving_license', label: 'Driving License', icon: Car, placeholder: 'License number' },
  { value: 'work_email', label: 'Work Email', icon: MailIcon, placeholder: 'you@company.com' },
];

const STATUS_STYLES: Record<Status, { badge: string; hero: string; icon: React.ComponentType<{ className?: string }>; label: string }> = {
  pending: { badge: 'border-amber-500/30 bg-amber-500/10 text-amber-400', hero: 'from-amber-500/10', icon: ShieldQuestion, label: 'Pending review' },
  verified: { badge: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400', hero: 'from-emerald-500/10', icon: ShieldCheck, label: 'Verified' },
  rejected: { badge: 'border-red-500/30 bg-red-500/10 text-red-400', hero: 'from-red-500/10', icon: ShieldAlert, label: 'Rejected' },
};

export default function VerificationPage() {
  const [ready, setReady] = useState(false);
  const [requests, setRequests] = useState<VerificationRequest[]>([]);
  const [docType, setDocType] = useState<DocType>('aadhaar');
  const [reference, setReference] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [justSubmitted, setJustSubmitted] = useState(false);

  const loadRequests = async () => {
    try {
      const { data } = await api.get(`/site/verification/${TENANT}`);
      setRequests(data.requests ?? []);
    } catch (e: any) {
      if (e.response?.status === 401) { window.location.href = '/'; return; }
    }
    setReady(true);
  };

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) {
      window.location.href = '/';
      return;
    }
    loadRequests();
  }, []);

  const latest = requests[0];
  const currentStatus: Status = latest?.Status ?? 'pending';
  const hasApproved = requests.some(r => r.Status === 'verified');
  const hasPending = requests.some(r => r.Status === 'pending');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!reference.trim()) {
      setError('Please enter a document reference.');
      return;
    }
    setSubmitting(true);
    setError('');
    try {
      await api.post(`/site/verification/${TENANT}`, { docType, docReference: reference.trim() });
      setReference('');
      setJustSubmitted(true);
      setTimeout(() => setJustSubmitted(false), 2500);
      await loadRequests();
    } catch (e: any) {
      if (e.response?.status === 401) { window.location.href = '/'; return; }
      setError(e.response?.data?.message || 'Could not submit your request. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  const heroStyle = STATUS_STYLES[hasApproved ? 'verified' : (currentStatus as Status)] || STATUS_STYLES.pending;
  const HeroIcon = heroStyle.icon;

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <span className="text-sm text-white/40">Verification</span>
      </nav>

      <div className="mx-auto max-w-2xl px-6 py-10">
        {/* Status hero */}
        <div className={`rounded-2xl border border-white/10 bg-gradient-to-br ${heroStyle.hero} via-transparent to-transparent p-6 text-center`}>
          <div className={`mx-auto flex size-14 items-center justify-center rounded-2xl border ${heroStyle.badge}`}>
            <HeroIcon className="size-7" />
          </div>
          <h1 className="mt-4 text-xl font-semibold tracking-tight">
            {hasApproved ? "You're verified" : requests.length === 0 ? 'Get verified' : (STATUS_STYLES[currentStatus] || STATUS_STYLES.pending).label}
          </h1>
          <p className="mt-1 text-sm text-white/50">
            {hasApproved
              ? 'Your identity has been verified. A verified badge builds trust with matches.'
              : requests.length === 0
                ? 'Submit a document to earn a verified badge on your profile.'
                : hasPending
                  ? "We're reviewing your submitted document — this usually takes 1-2 days."
                  : 'Your last submission was rejected. You can submit another document below.'}
          </p>
        </div>

        {/* Submit form */}
        {!hasApproved && (
          <form onSubmit={handleSubmit} className="mt-8 rounded-2xl border border-white/10 bg-white/[0.03] p-6">
            <h2 className="text-sm font-medium text-white/80">Submit a document</h2>

            <div className="mt-4 grid grid-cols-2 gap-2 sm:grid-cols-3">
              {DOC_TYPES.map((d) => {
                const Icon = d.icon;
                const active = docType === d.value;
                return (
                  <button
                    key={d.value}
                    type="button"
                    onClick={() => setDocType(d.value)}
                    className={`flex cursor-pointer flex-col items-center gap-1.5 rounded-lg border px-3 py-3 text-xs font-medium transition-colors duration-150 ${
                      active
                        ? 'border-emerald-500/50 bg-emerald-500/10 text-emerald-400'
                        : 'border-white/10 text-white/50 hover:border-white/20 hover:text-white/80'
                    }`}
                  >
                    <Icon className="size-4" />
                    {d.label}
                  </button>
                );
              })}
            </div>

            <label className="mb-1.5 mt-5 block text-sm font-medium text-white/70">
              {DOC_TYPES.find(d => d.value === docType)?.label} reference
            </label>
            <input
              value={reference}
              onChange={(e) => setReference(e.target.value)}
              placeholder={DOC_TYPES.find(d => d.value === docType)?.placeholder}
              className="w-full rounded-lg border border-white/10 bg-white/[0.03] px-4 py-2.5 text-white outline-none transition-colors placeholder:text-white/30 focus:border-emerald-500/60 focus:ring-3 focus:ring-emerald-500/15"
            />

            {error && <p className="mt-3 rounded-lg bg-red-500/10 p-3 text-sm text-red-400">{error}</p>}

            <button
              type="submit"
              disabled={submitting}
              className="mt-5 flex w-full cursor-pointer items-center justify-center gap-1.5 rounded-lg bg-emerald-500 py-2.5 text-sm font-medium text-emerald-950 transition-colors duration-150 hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {submitting ? <Loader2 className="size-4 animate-spin" /> : justSubmitted ? <><Check className="size-4" /> Submitted</> : 'Submit for review'}
            </button>
          </form>
        )}

        {/* History */}
        {requests.length > 0 && (
          <div className="mt-8">
            <h2 className="mb-3 text-xs font-medium uppercase tracking-wide text-white/40">Submission history</h2>
            <div className="space-y-2">
              {requests.map((r) => {
                const s = STATUS_STYLES[r.Status];
                const Icon = s.icon;
                return (
                  <div key={r.VerificationId} className="flex items-center justify-between rounded-xl border border-white/8 bg-white/[0.02] p-4">
                    <div className="flex items-center gap-3">
                      <div className={`flex size-9 items-center justify-center rounded-lg border ${s.badge}`}>
                        <Icon className="size-4" />
                      </div>
                      <div>
                        <p className="text-sm font-medium capitalize">{r.DocType.replace('_', ' ')}</p>
                        <p className="text-xs text-white/40">{r.DocReference} · {new Date(r.CreatedOn).toLocaleDateString()}</p>
                      </div>
                    </div>
                    <span className={`rounded-full border px-2.5 py-1 text-xs font-medium capitalize ${s.badge}`}>
                      {r.Status}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
