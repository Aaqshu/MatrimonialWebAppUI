'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import {
  HeartHandshake, Heart, SearchX, Loader2, ChevronLeft, ChevronRight,
  MapPin, Briefcase, SlidersHorizontal, X, ShieldCheck,
} from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';
const PAGE_SIZE = 12;

const RELIGIONS = ['Islam', 'Hindu', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other'];
const QUALIFICATIONS = ['High School', "Bachelor's Degree", "Master's Degree", 'MBA', 'PhD', 'Diploma', 'Other'];
const DIETS = [
  { value: 'vegetarian', label: 'Vegetarian' },
  { value: 'non_vegetarian', label: 'Non-Vegetarian' },
  { value: 'eggetarian', label: 'Eggetarian' },
  { value: 'vegan', label: 'Vegan' },
];

interface SearchUser {
  UserId: string;
  FirstName: string;
  LastName: string;
  Gender: string;
  Age: number | null;
  Height: string;
  MaritalStatus: string;
  Religion: string;
  Caste: string;
  City: string;
  Occupation: string;
  Qualification: string;
  PhotoUrl: string | null;
  MatchPercent: number | null;
  IsFavorite: boolean;
  VerificationStatus?: string;
}

interface Filters {
  gender: string;
  minAge: string;
  maxAge: string;
  religion: string;
  caste: string;
  city: string;
  education: string;
  diet: string;
}

const emptyFilters: Filters = { gender: '', minAge: '', maxAge: '', religion: '', caste: '', city: '', education: '', diet: '' };

const inputCls = 'w-full rounded-lg border border-white/10 bg-white/[0.03] px-3.5 py-2.5 text-sm text-white outline-none transition-colors placeholder:text-white/30 focus:border-emerald-500/60 focus:ring-3 focus:ring-emerald-500/15';
const labelCls = 'mb-1.5 block text-xs font-medium uppercase tracking-wide text-white/40';

function matchColor(pct: number | null) {
  if (pct === null) return 'border-white/15 bg-white/5 text-white/50';
  if (pct >= 75) return 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400';
  if (pct >= 50) return 'border-amber-500/30 bg-amber-500/10 text-amber-400';
  return 'border-white/15 bg-white/5 text-white/50';
}

export default function SearchPage() {
  const [ready, setReady] = useState(false);
  const [filters, setFilters] = useState<Filters>(emptyFilters);
  const [page, setPage] = useState(1);
  const [users, setUsers] = useState<SearchUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [favBusy, setFavBusy] = useState<string | null>(null);
  const [filtersOpen, setFiltersOpen] = useState(false);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) {
      window.location.href = '/';
      return;
    }
    setReady(true);
  }, []);

  useEffect(() => {
    if (!ready) return;
    setLoading(true);
    const t = setTimeout(() => {
      const params: Record<string, string | number> = { page, pageSize: PAGE_SIZE };
      if (filters.gender) params.gender = filters.gender;
      if (filters.minAge) params.minAge = filters.minAge;
      if (filters.maxAge) params.maxAge = filters.maxAge;
      if (filters.religion) params.religion = filters.religion;
      if (filters.caste) params.caste = filters.caste;
      if (filters.city) params.city = filters.city;
      if (filters.education) params.education = filters.education;
      if (filters.diet) params.diet = filters.diet;

      api.get(`/site/search/${TENANT}`, { params })
        .then(({ data }) => {
          setUsers(data.users ?? []);
          setTotal(data.total ?? 0);
        })
        .catch((e) => {
          if (e.response?.status === 401) { window.location.href = '/'; return; }
        })
        .finally(() => setLoading(false));
    }, 350);
    return () => clearTimeout(t);
  }, [ready, filters, page]);

  function updateFilter<K extends keyof Filters>(key: K, value: Filters[K]) {
    setFilters(prev => ({ ...prev, [key]: value }));
    setPage(1);
  }

  function clearFilters() {
    setFilters(emptyFilters);
    setPage(1);
  }

  async function toggleFavorite(u: SearchUser) {
    const next = !u.IsFavorite;
    setFavBusy(u.UserId);
    setUsers(prev => prev.map(x => x.UserId === u.UserId ? { ...x, IsFavorite: next } : x));
    try {
      if (next) await api.post(`/site/favorites/${TENANT}/${u.UserId}`);
      else await api.delete(`/site/favorites/${TENANT}/${u.UserId}`);
    } catch (e: any) {
      if (e.response?.status === 401) { window.location.href = '/'; return; }
      setUsers(prev => prev.map(x => x.UserId === u.UserId ? { ...x, IsFavorite: !next } : x));
    } finally {
      setFavBusy(null);
    }
  }

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  const hasActiveFilters = Object.values(filters).some(Boolean);
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <span className="text-sm text-white/40">Search</span>
      </nav>

      <div className="mx-auto max-w-6xl px-6 py-10">
        <div className="mb-6 flex items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">Discover matches</h1>
            <p className="mt-1 text-sm text-white/50">
              {loading ? 'Searching…' : `${total} profile${total === 1 ? '' : 's'} found`}
            </p>
          </div>
          <button
            type="button"
            onClick={() => setFiltersOpen(v => !v)}
            className="flex cursor-pointer items-center gap-1.5 rounded-lg border border-white/10 bg-white/[0.03] px-3.5 py-2 text-sm font-medium text-white/70 transition-colors hover:border-white/20 hover:text-white lg:hidden"
          >
            <SlidersHorizontal className="size-4" /> Filters
          </button>
        </div>

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-[260px_1fr]">
          {/* Filter sidebar */}
          <aside className={`${filtersOpen ? 'block' : 'hidden'} h-fit rounded-2xl border border-white/10 bg-white/[0.03] p-5 lg:sticky lg:top-6 lg:block`}>
            <div className="mb-4 flex items-center justify-between">
              <p className="text-sm font-medium text-white/80">Filters</p>
              {hasActiveFilters && (
                <button
                  type="button"
                  onClick={clearFilters}
                  className="flex cursor-pointer items-center gap-1 text-xs text-white/40 transition-colors hover:text-white"
                >
                  <X className="size-3" /> Clear
                </button>
              )}
            </div>

            <div className="space-y-4">
              <div>
                <label className={labelCls}>Gender</label>
                <div className="flex gap-1.5">
                  {[{ v: '', l: 'Any' }, { v: 'male', l: 'Male' }, { v: 'female', l: 'Female' }].map(o => (
                    <button
                      key={o.v}
                      type="button"
                      onClick={() => updateFilter('gender', o.v)}
                      className={`flex-1 cursor-pointer rounded-lg border px-2 py-1.5 text-xs font-medium transition-colors duration-150 ${
                        filters.gender === o.v
                          ? 'border-emerald-500/50 bg-emerald-500/10 text-emerald-400'
                          : 'border-white/10 text-white/50 hover:border-white/20 hover:text-white/80'
                      }`}
                    >
                      {o.l}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className={labelCls}>Age range</label>
                <div className="flex items-center gap-2">
                  <input type="number" min={18} placeholder="Min" value={filters.minAge}
                    onChange={e => updateFilter('minAge', e.target.value)} className={inputCls} />
                  <span className="text-white/30">–</span>
                  <input type="number" min={18} placeholder="Max" value={filters.maxAge}
                    onChange={e => updateFilter('maxAge', e.target.value)} className={inputCls} />
                </div>
              </div>

              <div>
                <label className={labelCls}>Religion</label>
                <select value={filters.religion} onChange={e => updateFilter('religion', e.target.value)} className={inputCls}>
                  <option value="">Any</option>
                  {RELIGIONS.map(r => <option key={r} value={r}>{r}</option>)}
                </select>
              </div>

              <div>
                <label className={labelCls}>Caste</label>
                <input value={filters.caste} onChange={e => updateFilter('caste', e.target.value)} placeholder="e.g. Sheikh" className={inputCls} />
              </div>

              <div>
                <label className={labelCls}>City</label>
                <input value={filters.city} onChange={e => updateFilter('city', e.target.value)} placeholder="e.g. Mumbai" className={inputCls} />
              </div>

              <div>
                <label className={labelCls}>Education</label>
                <select value={filters.education} onChange={e => updateFilter('education', e.target.value)} className={inputCls}>
                  <option value="">Any</option>
                  {QUALIFICATIONS.map(q => <option key={q} value={q}>{q}</option>)}
                </select>
              </div>

              <div>
                <label className={labelCls}>Diet</label>
                <select value={filters.diet} onChange={e => updateFilter('diet', e.target.value)} className={inputCls}>
                  <option value="">Any</option>
                  {DIETS.map(d => <option key={d.value} value={d.value}>{d.label}</option>)}
                </select>
              </div>
            </div>
          </aside>

          {/* Results */}
          <div>
            {loading && users.length === 0 ? (
              <div className="flex items-center justify-center py-20 text-white/40">
                <Loader2 className="size-6 animate-spin" />
              </div>
            ) : users.length === 0 ? (
              <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-white/10 bg-white/[0.02] py-20 text-center">
                <SearchX className="size-8 text-white/20" />
                <p className="text-sm text-white/50">No profiles match your filters</p>
                {hasActiveFilters && (
                  <button type="button" onClick={clearFilters} className="mt-1 cursor-pointer text-sm text-emerald-400 hover:text-emerald-300">
                    Clear filters
                  </button>
                )}
              </div>
            ) : (
              <div className={`grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 transition-opacity duration-150 ${loading ? 'opacity-50' : 'opacity-100'}`}>
                {users.map(u => (
                  <div key={u.UserId} className="group overflow-hidden rounded-2xl border border-white/8 bg-white/[0.03] transition-all hover:border-white/20">
                    <div className="relative aspect-[4/5] w-full overflow-hidden bg-white/5">
                      {u.PhotoUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={u.PhotoUrl} alt={u.FirstName} className="size-full object-cover transition-transform duration-300 group-hover:scale-105" />
                      ) : (
                        <div className="flex size-full items-center justify-center bg-gradient-to-br from-emerald-500/15 to-amber-500/10 text-2xl font-semibold text-white/40">
                          {u.FirstName?.[0]}{u.LastName?.[0]}
                        </div>
                      )}

                      <span className={`absolute left-2.5 top-2.5 rounded-full border px-2 py-0.5 text-[11px] font-semibold ${matchColor(u.MatchPercent)}`}>
                        {u.MatchPercent === null ? '—' : `${u.MatchPercent}%`} match
                      </span>

                      <button
                        type="button"
                        onClick={() => toggleFavorite(u)}
                        disabled={favBusy === u.UserId}
                        aria-label={u.IsFavorite ? 'Remove from favorites' : 'Add to favorites'}
                        className="absolute right-2.5 top-2.5 flex size-8 cursor-pointer items-center justify-center rounded-full bg-black/40 text-white backdrop-blur-sm transition-colors duration-150 hover:bg-black/60 disabled:cursor-not-allowed disabled:opacity-60"
                      >
                        <Heart className={`size-4 ${u.IsFavorite ? 'fill-amber-400 text-amber-400' : 'text-white'}`} />
                      </button>

                      {u.VerificationStatus === 'verified' && (
                        <span className="absolute bottom-2.5 left-2.5 flex items-center gap-1 rounded-full bg-emerald-500 px-2 py-0.5 text-[11px] font-semibold text-emerald-950">
                          <ShieldCheck className="size-3" /> Verified
                        </span>
                      )}
                    </div>

                    <div className="p-4">
                      <div className="flex items-baseline justify-between gap-2">
                        <p className="truncate font-medium">{u.FirstName} {u.LastName}</p>
                        {u.Age && <span className="shrink-0 text-sm text-white/50">{u.Age} yrs</span>}
                      </div>
                      <p className="mt-1 truncate text-sm text-white/50">
                        {[u.Religion, u.Caste].filter(Boolean).join(' · ') || '—'}
                      </p>
                      <div className="mt-2 space-y-1 text-xs text-white/40">
                        {u.City && (
                          <p className="flex items-center gap-1.5 truncate">
                            <MapPin className="size-3 shrink-0" /> {u.City}
                          </p>
                        )}
                        {u.Occupation && (
                          <p className="flex items-center gap-1.5 truncate">
                            <Briefcase className="size-3 shrink-0" /> {u.Occupation}
                          </p>
                        )}
                      </div>
                      <Link
                        href={`/profile/${u.UserId}`}
                        className="mt-3 block w-full rounded-lg border border-white/10 py-2 text-center text-sm font-medium text-white/70 transition-colors duration-150 hover:border-emerald-500/50 hover:text-emerald-400"
                      >
                        View Profile
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Pagination */}
            {total > PAGE_SIZE && (
              <div className="mt-8 flex items-center justify-center gap-3">
                <button
                  type="button"
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page <= 1}
                  className="flex cursor-pointer items-center gap-1 rounded-lg border border-white/10 px-3 py-2 text-sm text-white/60 transition-colors hover:border-white/20 hover:text-white disabled:cursor-not-allowed disabled:opacity-30"
                >
                  <ChevronLeft className="size-4" /> Prev
                </button>
                <span className="text-sm text-white/40">Page {page} of {totalPages}</span>
                <button
                  type="button"
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page >= totalPages}
                  className="flex cursor-pointer items-center gap-1 rounded-lg border border-white/10 px-3 py-2 text-sm text-white/60 transition-colors hover:border-white/20 hover:text-white disabled:cursor-not-allowed disabled:opacity-30"
                >
                  Next <ChevronRight className="size-4" />
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
