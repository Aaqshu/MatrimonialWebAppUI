'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { HeartHandshake, Loader2, Sparkles } from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';

interface Story {
  StoryId: string;
  FirstName1: string;
  FirstName2: string;
  Testimonial: string;
  PhotoUrl: string | null;
  MarriageDate: string | null;
}

export default function StoriesPage() {
  const [stories, setStories] = useState<Story[]>([]);
  const [loading, setLoading] = useState(true);
  const [authed, setAuthed] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      setAuthed(!!localStorage.getItem('site_token'));
    }
    api.get(`/site/stories/${TENANT}`)
      .then(({ data }) => setStories(data.stories ?? []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <Link
          href={authed ? '/dashboard' : '/'}
          className="text-sm text-white/50 transition-colors hover:text-white"
        >
          {authed ? 'Back to Dashboard' : 'Sign In'}
        </Link>
      </nav>

      <div className="mx-auto max-w-6xl px-6 py-14">
        {/* Hero */}
        <div className="mx-auto max-w-2xl text-center">
          <div className="mx-auto flex size-12 items-center justify-center rounded-2xl bg-gradient-to-br from-emerald-500/20 to-amber-500/20 text-amber-300">
            <Sparkles className="size-5" />
          </div>
          <h1 className="mt-4 text-3xl font-semibold tracking-tight sm:text-4xl">
            Success stories — real couples, real matches
          </h1>
          <p className="mt-3 text-sm text-white/50">
            Every love story is beautiful, but ours are our favorite. Here&apos;s a glimpse of couples who found each other on Matrimony.
          </p>
        </div>

        {/* Grid */}
        <div className="mt-12">
          {loading ? (
            <div className="flex items-center justify-center py-20 text-white/40">
              <Loader2 className="size-6 animate-spin" />
            </div>
          ) : stories.length === 0 ? (
            <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-white/10 bg-white/[0.02] py-20 text-center">
              <HeartHandshake className="size-8 text-white/20" />
              <p className="text-sm text-white/50">No success stories published yet</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {stories.map(s => (
                <StoryCard key={s.StoryId} story={s} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function StoryCard({ story }: { story: Story }) {
  const initials = `${story.FirstName1?.[0] || ''}${story.FirstName2?.[0] || ''}`.toUpperCase();
  const marriageDate = story.MarriageDate
    ? new Date(story.MarriageDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
    : null;

  return (
    <div className="overflow-hidden rounded-2xl border border-white/8 bg-white/[0.03] p-6 transition-all hover:border-white/20">
      <div className="flex items-center gap-3">
        {story.PhotoUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={story.PhotoUrl} alt="" className="size-14 shrink-0 rounded-full border border-white/10 object-cover" />
        ) : (
          <div className="flex size-14 shrink-0 items-center justify-center rounded-full border border-white/10 bg-gradient-to-br from-emerald-500/20 to-amber-500/20 text-lg font-semibold">
            {initials}
          </div>
        )}
        <div>
          <p className="font-medium">{story.FirstName1} &amp; {story.FirstName2}</p>
          <p className="text-xs text-white/40">got married{marriageDate ? ` · ${marriageDate}` : ''}</p>
        </div>
      </div>
      <p className="mt-4 line-clamp-4 text-sm leading-relaxed text-white/60">
        &ldquo;{story.Testimonial}&rdquo;
      </p>
    </div>
  );
}
