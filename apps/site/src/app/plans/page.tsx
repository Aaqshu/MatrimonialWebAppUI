'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import {
  HeartHandshake, Loader2, Check, Crown, Sparkles, Star, X, CheckCircle2,
} from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

interface Plan {
  PlanId: string;
  PlanName: string;
  Price: number | string;
  DurationDays: number;
  Features: string[] | null;
}

interface Subscription {
  SubscriptionId: string;
  Status: string;
  StartsOn: string;
  ExpiresOn: string;
  PaymentRef: string | null;
  PlanName: string;
  Price: number | string;
  DurationDays: number;
  Features: string[] | null;
}

function durationLabel(days: number) {
  if (days === 30) return 'month';
  if (days === 90) return 'quarter';
  if (days === 180) return '6 months';
  if (days === 365) return 'year';
  return `${days} days`;
}

function formatPrice(price: number | string) {
  const n = Number(price);
  if (n === 0) return 'Free';
  return `₹${n.toLocaleString('en-IN', { maximumFractionDigits: 0 })}`;
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

export default function PlansPage() {
  const [ready, setReady] = useState(false);
  const [loading, setLoading] = useState(true);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [isPremium, setIsPremium] = useState(false);
  const [isFeatured, setIsFeatured] = useState(false);
  const [confirmPlan, setConfirmPlan] = useState<Plan | null>(null);
  const [checkingOut, setCheckingOut] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');
  const [toast, setToast] = useState('');

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) { window.location.href = '/'; return; }
    setReady(true);
  }, []);

  const loadMembership = () =>
    api.get(`/site/membership/${TENANT}`).then(({ data }) => {
      setSubscription(data.subscription ?? null);
      setIsPremium(!!data.isPremium);
      setIsFeatured(!!data.isFeatured);
    });

  useEffect(() => {
    if (!ready) return;
    Promise.all([
      api.get(`/site/plans/${TENANT}`).then(({ data }) => setPlans(data.plans ?? [])),
      loadMembership(),
    ])
      .catch((e) => { if (e.response?.status === 401) window.location.href = '/'; })
      .finally(() => setLoading(false));
  }, [ready]);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 2500);
  }

  async function confirmCheckout() {
    if (!confirmPlan) return;
    setCheckingOut(true);
    try {
      const { data } = await api.post(`/site/checkout/${TENANT}`, { planId: confirmPlan.PlanId });
      setConfirmPlan(null);
      if (data.devMode) {
        setSuccessMsg(`Payment successful (dev) — ${data.plan} plan activated`);
        setTimeout(() => setSuccessMsg(''), 5000);
      } else {
        showToast('Order created — complete payment to activate.');
      }
      await loadMembership();
    } catch (e: any) {
      setConfirmPlan(null);
      if (e.response?.status === 401) { window.location.href = '/'; return; }
      showToast(e.response?.data?.message || 'Checkout failed. Please try again.');
    } finally {
      setCheckingOut(false);
    }
  }

  if (!ready || loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  const paidPlans = plans.filter(p => Number(p.Price) > 0);
  const popularId = paidPlans[1]?.PlanId;
  const gridCols = plans.length >= 4 ? 'lg:grid-cols-4' : plans.length === 3 ? 'lg:grid-cols-3' : 'lg:grid-cols-2';

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <span className="text-sm text-white/40">Plans &amp; Membership</span>
      </nav>

      <div className="mx-auto max-w-6xl px-6 py-10">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">Find your perfect plan</h1>
          <p className="mt-2 text-sm text-white/50">Unlock premium features and get noticed faster</p>
        </div>

        {successMsg && (
          <div className="mb-6 flex items-center gap-2 rounded-xl border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm font-medium text-emerald-300">
            <CheckCircle2 className="size-4.5 shrink-0" /> {successMsg}
          </div>
        )}

        {isPremium && subscription && (
          <div className="mb-8 rounded-2xl border border-amber-500/25 bg-gradient-to-br from-amber-500/10 via-transparent to-emerald-500/10 p-6">
            <div className="flex flex-wrap items-center gap-3.5">
              <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-amber-500 text-amber-950 shadow-lg shadow-amber-500/20">
                <Crown className="size-5" />
              </div>
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <p className="font-medium">{subscription.PlanName} member</p>
                  {isFeatured && (
                    <span className="flex items-center gap-1 rounded-full border border-amber-500/30 bg-amber-500/15 px-2 py-0.5 text-[11px] font-semibold text-amber-300">
                      <Star className="size-3 fill-amber-300" /> FEATURED
                    </span>
                  )}
                </div>
                <p className="mt-0.5 text-sm text-white/50">Active until {formatDate(subscription.ExpiresOn)}</p>
              </div>
            </div>
          </div>
        )}

        <div className={`grid grid-cols-1 gap-6 sm:grid-cols-2 ${gridCols}`}>
          {plans.map((plan) => {
            const price = Number(plan.Price);
            const isFree = price === 0;
            const isCurrent = !!subscription && subscription.PlanName === plan.PlanName;
            const isPopular = plan.PlanId === popularId;
            const features: string[] = Array.isArray(plan.Features) ? plan.Features : [];

            return (
              <div
                key={plan.PlanId}
                className={`relative flex flex-col rounded-2xl border p-6 transition-all duration-200 ${
                  isPopular
                    ? 'border-emerald-500/40 bg-gradient-to-b from-emerald-500/10 to-transparent shadow-lg shadow-emerald-500/10'
                    : 'border-white/10 bg-white/[0.03] hover:border-white/20'
                }`}
              >
                {isPopular && (
                  <span className="absolute -top-3 left-1/2 flex -translate-x-1/2 items-center gap-1 rounded-full bg-emerald-500 px-3 py-1 text-[11px] font-semibold text-emerald-950 shadow-lg shadow-emerald-500/30">
                    <Sparkles className="size-3" /> Most popular
                  </span>
                )}

                <p className="font-semibold">{plan.PlanName}</p>
                <div className="mt-3 flex items-baseline gap-1">
                  <span className="text-3xl font-semibold tracking-tight">{formatPrice(plan.Price)}</span>
                  {!isFree && <span className="text-sm text-white/40">/ {durationLabel(plan.DurationDays)}</span>}
                </div>

                <ul className="mt-5 flex-1 space-y-2.5">
                  {features.length === 0 ? (
                    <li className="text-sm text-white/40">No listed features</li>
                  ) : (
                    features.map((f, i) => (
                      <li key={i} className="flex items-start gap-2 text-sm text-white/70">
                        <Check className="mt-0.5 size-4 shrink-0 text-emerald-400" />
                        {f}
                      </li>
                    ))
                  )}
                </ul>

                {isFree ? (
                  <button
                    type="button"
                    disabled
                    className="mt-6 w-full cursor-not-allowed rounded-lg border border-white/10 py-2.5 text-sm font-medium text-white/40"
                  >
                    Current plan
                  </button>
                ) : isCurrent ? (
                  <button
                    type="button"
                    disabled
                    className="mt-6 flex w-full cursor-not-allowed items-center justify-center gap-1.5 rounded-lg border border-emerald-500/30 bg-emerald-500/10 py-2.5 text-sm font-medium text-emerald-400"
                  >
                    <Check className="size-4" /> Current plan
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={() => setConfirmPlan(plan)}
                    className={`mt-6 w-full cursor-pointer rounded-lg py-2.5 text-sm font-medium transition-colors duration-150 ${
                      isPopular
                        ? 'bg-emerald-500 text-emerald-950 hover:bg-emerald-400'
                        : 'border border-white/15 text-white/80 hover:border-emerald-500/50 hover:text-emerald-400'
                    }`}
                  >
                    Upgrade to {plan.PlanName}
                  </button>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Confirm dialog */}
      {confirmPlan && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl border border-white/10 bg-zinc-900 p-6 shadow-2xl">
            <div className="flex items-center justify-between">
              <p className="font-semibold">Confirm subscription</p>
              <button
                type="button"
                onClick={() => setConfirmPlan(null)}
                className="cursor-pointer rounded-lg p-1 text-white/40 transition-colors hover:bg-white/10 hover:text-white"
                aria-label="Close"
              >
                <X className="size-4" />
              </button>
            </div>
            <p className="mt-3 text-sm text-white/60">
              Subscribe to <span className="font-medium text-white">{confirmPlan.PlanName}</span> for{' '}
              <span className="font-medium text-white">
                {formatPrice(confirmPlan.Price)} / {durationLabel(confirmPlan.DurationDays)}
              </span>?
            </p>
            <div className="mt-6 flex gap-3">
              <button
                type="button"
                onClick={() => setConfirmPlan(null)}
                disabled={checkingOut}
                className="flex-1 cursor-pointer rounded-lg border border-white/10 py-2.5 text-sm font-medium text-white/70 transition-colors hover:border-white/20 hover:text-white disabled:cursor-not-allowed disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={confirmCheckout}
                disabled={checkingOut}
                className="flex flex-1 cursor-pointer items-center justify-center gap-1.5 rounded-lg bg-emerald-500 py-2.5 text-sm font-medium text-emerald-950 transition-colors duration-150 hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {checkingOut ? <Loader2 className="size-4 animate-spin" /> : 'Confirm & pay'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 transition-all duration-300 ${toast ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-3 opacity-0'}`}>
        <div className="flex items-center gap-2 rounded-full border border-red-500/30 bg-red-500/15 px-4 py-2 text-sm font-medium text-red-300 shadow-lg shadow-black/30 backdrop-blur-md">
          {toast}
        </div>
      </div>
    </div>
  );
}
