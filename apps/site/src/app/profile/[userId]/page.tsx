'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import api from '@/lib/api';
import {
  ArrowLeft, BadgeCheck, Briefcase, Cake, Heart, HeartHandshake, GraduationCap,
  Home, Languages, Loader2, MapPin, ShieldAlert, Sparkles, UserCircle2, Users,
} from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

interface PublicProfile {
  UserId: string;
  FirstName: string;
  LastName: string;
  Gender: string;
  Age: number;
  Height: number;
  Weight: number;
  MaritalStatus: string;
  Religion: string;
  Caste: string;
  SubCaste: string;
  Sect: string;
  MotherTongue: string;
  AboutMe: string;
  Qualification: string;
  Occupation: string;
  CompanyName: string;
  AnnualIncome: number;
  City: string;
  State: string;
  Diet: string;
  Hobbies: string;
  LanguagesKnown: string;
  FamilyType: string;
  FatherOccupation: string;
  MotherOccupation: string;
  Brothers: number;
  Sisters: number;
  VerificationStatus: string;
  MatchPercent: number | null;
  IsFavorite: boolean;
  IsBlocked: boolean;
  Photos: string[];
}

export default function PublicProfilePage() {
  const { userId } = useParams();
  const router = useRouter();
  const [prof, setProf] = useState<PublicProfile | null>(null);
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState('');
  const [toast, setToast] = useState('');

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) { window.location.href = '/'; return; }
    api.get(`/site/profile/${TENANT}/${userId}`)
      .then(({ data }) => setProf(data))
      .catch((e) => {
        if (e.response?.status === 401) { window.location.href = '/'; return; }
        setErr('Profile not found');
      });
  }, [userId]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(''), 2500);
  };

  const act = async (label: string, fn: () => Promise<any>) => {
    setBusy(label);
    try {
      const res = await fn();
      if (res.status === 201) {
        if (label === 'interest') { showToast('Interest sent!'); setBusy(''); return; }
      }
      if (res.data?.favorited !== undefined) setProf(p => p ? { ...p, IsFavorite: res.data.favorited } : p);
      if (res.data?.blocked !== undefined) { setProf(p => p ? { ...p, IsBlocked: true } : p); showToast('User blocked'); }
    } catch (e: any) {
      showToast(e.response?.data?.message || 'Action failed');
    } finally {
      setBusy('');
    }
  };

  if (err) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-background text-white">
        <UserCircle2 className="size-12 text-white/20" />
        <p className="text-white/60">{err}</p>
        <Link href="/search" className="text-sm text-emerald-400 hover:underline">← Back to search</Link>
      </div>
    );
  }

  if (!prof) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  const initials = `${prof.FirstName?.[0] || ''}${prof.LastName?.[0] || ''}`.toUpperCase();
  const photo = prof.Photos?.[0];

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/search" className="flex items-center gap-2 text-sm text-white/60 transition-colors hover:text-white">
          <ArrowLeft className="size-4" />
          Back to search
        </Link>
        <div className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </div>
      </nav>

      <div className="mx-auto max-w-4xl px-6 py-8">
        {/* Hero */}
        <div className="overflow-hidden rounded-2xl border border-white/8 bg-gradient-to-br from-white/[0.04] to-transparent">
          <div className="flex flex-col gap-6 p-6 sm:flex-row sm:items-start">
            <div className="relative mx-auto sm:mx-0">
              {photo ? (
                <img src={photo} alt={prof.FirstName} className="size-40 rounded-2xl border border-white/10 object-cover" />
              ) : (
                <div className="flex size-40 items-center justify-center rounded-2xl border border-white/10 bg-gradient-to-br from-emerald-500/20 to-amber-500/20 text-4xl font-semibold">
                  {initials}
                </div>
              )}
              {prof.MatchPercent !== null && (
                <div className="absolute -bottom-2 -right-2 flex size-12 items-center justify-center rounded-full border border-emerald-500/40 bg-emerald-950 text-xs font-bold text-emerald-300 shadow-lg">
                  {prof.MatchPercent}%
                </div>
              )}
            </div>
            <div className="flex-1 text-center sm:text-left">
              <div className="flex flex-wrap items-center justify-center gap-2 sm:justify-start">
                <h1 className="text-2xl font-semibold tracking-tight">{prof.FirstName} {prof.LastName}</h1>
                {prof.VerificationStatus === 'verified' && (
                  <span className="inline-flex items-center gap-1 rounded-full border border-emerald-500/30 bg-emerald-500/15 px-2 py-0.5 text-xs font-medium text-emerald-300">
                    <BadgeCheck className="size-3.5" /> Verified
                  </span>
                )}
              </div>
              <p className="mt-1 flex items-center justify-center gap-1.5 text-sm text-white/50 sm:justify-start">
                <Cake className="size-4" /> {prof.Age} yrs · {prof.Height} ft · {prof.MaritalStatus?.replace('_', ' ')}
              </p>
              <p className="mt-0.5 flex items-center justify-center gap-1.5 text-sm text-white/50 sm:justify-start">
                <MapPin className="size-4" /> {prof.City}{prof.State ? `, ${prof.State}` : ''}
              </p>
              <div className="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <button
                  onClick={() => act('interest', () => api.post(`/site/interests/${TENANT}`, { toUserId: prof.UserId }))}
                  disabled={!!busy}
                  className="flex cursor-pointer items-center gap-1.5 rounded-full bg-emerald-500 px-5 py-2 text-sm font-medium text-emerald-950 transition-colors hover:bg-emerald-400 disabled:cursor-wait disabled:opacity-50"
                >
                  <Heart className="size-4" /> Send Interest
                </button>
                <button
                  onClick={() => act('fav', () => prof.IsFavorite
                    ? api.delete(`/site/favorites/${TENANT}/${prof.UserId}`)
                    : api.post(`/site/favorites/${TENANT}/${prof.UserId}`))}
                  disabled={!!busy}
                  className={`flex cursor-pointer items-center gap-1.5 rounded-full border px-5 py-2 text-sm font-medium transition-colors disabled:cursor-wait disabled:opacity-50 ${
                    prof.IsFavorite ? 'border-rose-500/50 bg-rose-500/15 text-rose-300' : 'border-white/15 bg-white/5 text-white/70 hover:border-white/30'
                  }`}
                >
                  <Heart className={`size-4 ${prof.IsFavorite ? 'fill-rose-400 text-rose-400' : ''}`} />
                  {prof.IsFavorite ? 'Favorited' : 'Favorite'}
                </button>
                {!prof.IsBlocked && (
                  <button
                    onClick={() => act('block', () => api.post(`/site/block/${TENANT}/${prof.UserId}`))}
                    disabled={!!busy}
                    className="flex cursor-pointer items-center gap-1.5 rounded-full border border-white/10 px-5 py-2 text-sm font-medium text-white/40 transition-colors hover:border-red-500/40 hover:text-red-300 disabled:cursor-wait disabled:opacity-50"
                  >
                    <ShieldAlert className="size-4" /> Block
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Sections */}
        <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Section icon={<UserCircle2 className="size-4" />} title="Basic details">
            <Row k="Height" v={prof.Height ? `${prof.Height} ft` : '—'} />
            <Row k="Weight" v={prof.Weight ? `${prof.Weight} kg` : '—'} />
            <Row k="Marital status" v={prof.MaritalStatus?.replace('_', ' ')} />
          </Section>
          <Section icon={<Sparkles className="size-4" />} title="Religion & community">
            <Row k="Religion" v={prof.Religion} />
            <Row k="Caste" v={prof.Caste} />
            <Row k="Sect" v={prof.Sect} />
            <Row k="Mother tongue" v={prof.MotherTongue} />
          </Section>
          <Section icon={<GraduationCap className="size-4" />} title="Education & career">
            <Row k="Qualification" v={prof.Qualification} />
            <Row k="Occupation" v={prof.Occupation} />
            <Row k="Company" v={prof.CompanyName} />
            <Row k="Annual income" v={prof.AnnualIncome ? `₹${Number(prof.AnnualIncome).toLocaleString('en-IN')}` : '—'} />
          </Section>
          <Section icon={<Home className="size-4" />} title="Family">
            <Row k="Family type" v={prof.FamilyType} />
            <Row k="Father" v={prof.FatherOccupation} />
            <Row k="Mother" v={prof.MotherOccupation} />
            <Row k="Siblings" v={`${prof.Brothers ?? 0} brother(s), ${prof.Sisters ?? 0} sister(s)`} />
          </Section>
          <Section icon={<Briefcase className="size-4" />} title="Lifestyle">
            <Row k="Diet" v={prof.Diet?.replace('_', ' ')} />
            <Row k="Hobbies" v={prof.Hobbies} />
            <Row k="Languages" v={prof.LanguagesKnown} />
          </Section>
          <Section icon={<Users className="size-4" />} title="About me">
            <p className="text-sm leading-relaxed text-white/60">{prof.AboutMe || '—'}</p>
          </Section>
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

function Section({ icon, title, children }: { icon: React.ReactNode; title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-2xl border border-white/8 bg-white/[0.03] p-5">
      <div className="flex items-center gap-2 text-white/50">
        {icon}
        <h2 className="text-xs font-medium uppercase tracking-wide">{title}</h2>
      </div>
      <div className="mt-3 space-y-2">{children}</div>
    </div>
  );
}

function Row({ k, v }: { k: string; v: string | undefined }) {
  return (
    <div className="flex items-baseline justify-between gap-4">
      <span className="text-xs text-white/40">{k}</span>
      <span className="text-right text-sm text-white/80 capitalize">{v || '—'}</span>
    </div>
  );
}
