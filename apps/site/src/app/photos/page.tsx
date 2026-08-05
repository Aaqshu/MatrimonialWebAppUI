'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import {
  HeartHandshake, UploadCloud, Star, Trash2, Loader2, ImageOff, ImagePlus,
} from 'lucide-react';

const TENANT = 'provision-test_provisiontestmatrimony';
const MAX_PHOTOS = 6;

interface Photo {
  PhotoId: string;
  PhotoUrl: string;
  IsPrimary: boolean;
  DisplayOrder: number;
  IsApproved: boolean;
}

export default function PhotosPage() {
  const [ready, setReady] = useState(false);
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [dragOver, setDragOver] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const loadPhotos = useCallback(async () => {
    try {
      const { data } = await api.get(`/site/photos/${TENANT}`);
      setPhotos((data.photos ?? []).sort((a: Photo, b: Photo) => a.DisplayOrder - b.DisplayOrder));
    } catch (e: any) {
      if (e.response?.status === 401) {
        window.location.href = '/';
        return;
      }
    }
    setReady(true);
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('site_token')) {
      window.location.href = '/';
      return;
    }
    loadPhotos();
  }, [loadPhotos]);

  async function uploadFile(file: File) {
    if (photos.length >= MAX_PHOTOS) {
      setError(`You can upload up to ${MAX_PHOTOS} photos.`);
      return;
    }
    if (!file.type.startsWith('image/')) {
      setError('Please choose an image file.');
      return;
    }
    setError('');
    setUploading(true);
    setProgress(0);
    const form = new FormData();
    form.append('file', file);
    try {
      await api.post(`/site/photos/${TENANT}`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
        onUploadProgress: (evt) => {
          if (evt.total) setProgress(Math.round((evt.loaded / evt.total) * 100));
        },
      });
      await loadPhotos();
    } catch (e: any) {
      if (e.response?.status === 401) {
        window.location.href = '/';
        return;
      }
      setError(e.response?.data?.message || 'Upload failed. Please try again.');
    } finally {
      setUploading(false);
      setProgress(0);
    }
  }

  function handleDrop(e: React.DragEvent<HTMLDivElement>) {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files?.[0];
    if (file) uploadFile(file);
  }

  function handlePick(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) uploadFile(file);
    e.target.value = '';
  }

  async function setPrimary(photoId: string) {
    setBusyId(photoId);
    try {
      await api.patch(`/site/photos/${TENANT}/${photoId}`, { isPrimary: true });
      await loadPhotos();
    } catch (e: any) {
      if (e.response?.status === 401) { window.location.href = '/'; return; }
      setError('Could not set primary photo.');
    } finally {
      setBusyId(null);
    }
  }

  async function removePhoto(photoId: string) {
    setBusyId(photoId);
    try {
      await api.delete(`/site/photos/${TENANT}/${photoId}`);
      setPhotos(prev => prev.filter(p => p.PhotoId !== photoId));
    } catch (e: any) {
      if (e.response?.status === 401) { window.location.href = '/'; return; }
      setError('Could not delete photo.');
    } finally {
      setBusyId(null);
    }
  }

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background text-white/50">
        <Loader2 className="size-5 animate-spin" />
      </div>
    );
  }

  const atLimit = photos.length >= MAX_PHOTOS;

  return (
    <div className="min-h-screen bg-background text-white">
      <nav className="flex items-center justify-between border-b border-white/8 px-6 py-4">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-emerald-500 text-emerald-950">
            <HeartHandshake className="size-4.5" />
          </div>
          <span className="font-semibold">Matrimony</span>
        </Link>
        <span className="text-sm text-white/40">Photos</span>
      </nav>

      <div className="mx-auto max-w-3xl px-6 py-10">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">Your photos</h1>
            <p className="mt-1 text-sm text-white/50">
              Add up to {MAX_PHOTOS} photos — {photos.length}/{MAX_PHOTOS} uploaded
            </p>
          </div>
        </div>

        {/* Dropzone */}
        <div
          onDragOver={(e) => { e.preventDefault(); if (!atLimit) setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={atLimit ? undefined : handleDrop}
          onClick={() => !atLimit && !uploading && fileInputRef.current?.click()}
          className={`flex flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed p-10 text-center transition-colors duration-150 ${
            atLimit
              ? 'cursor-not-allowed border-white/10 bg-white/[0.02] opacity-50'
              : dragOver
                ? 'cursor-pointer border-emerald-500/60 bg-emerald-500/5'
                : 'cursor-pointer border-white/15 bg-white/[0.02] hover:border-white/25 hover:bg-white/[0.03]'
          }`}
        >
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handlePick}
            disabled={atLimit || uploading}
          />
          {uploading ? (
            <>
              <Loader2 className="size-7 animate-spin text-emerald-400" />
              <p className="text-sm text-white/60">Uploading… {progress}%</p>
              <div className="h-1.5 w-48 overflow-hidden rounded-full bg-white/8">
                <div className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-amber-500 transition-all" style={{ width: `${progress}%` }} />
              </div>
            </>
          ) : atLimit ? (
            <>
              <ImageOff className="size-7 text-white/30" />
              <p className="text-sm text-white/40">Photo limit reached — delete one to add more</p>
            </>
          ) : (
            <>
              <div className="flex size-12 items-center justify-center rounded-full bg-emerald-500/10 text-emerald-400">
                <UploadCloud className="size-6" />
              </div>
              <p className="text-sm font-medium text-white/80">Drag &amp; drop a photo, or click to browse</p>
              <p className="text-xs text-white/35">JPG, PNG — up to {MAX_PHOTOS} photos</p>
            </>
          )}
        </div>

        {error && <p className="mt-4 rounded-lg bg-red-500/10 p-3 text-sm text-red-400">{error}</p>}

        {/* Grid */}
        {photos.length === 0 ? (
          <div className="mt-8 flex flex-col items-center gap-2 rounded-xl border border-dashed border-white/10 bg-white/[0.02] py-14 text-center">
            <ImagePlus className="size-8 text-white/20" />
            <p className="text-sm text-white/40">No photos yet — add your first one above</p>
          </div>
        ) : (
          <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3">
            {photos.map((p) => (
              <div key={p.PhotoId} className="group relative overflow-hidden rounded-xl border border-white/8 bg-white/[0.03]">
                <div className="aspect-square w-full overflow-hidden">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={p.PhotoUrl} alt="Profile" className="size-full object-cover" />
                </div>

                {p.IsPrimary && (
                  <span className="absolute left-2 top-2 flex items-center gap-1 rounded-full bg-emerald-500 px-2 py-0.5 text-[11px] font-semibold text-emerald-950">
                    <Star className="size-3 fill-current" /> PRIMARY
                  </span>
                )}
                {!p.IsApproved && (
                  <span className="absolute right-2 top-2 rounded-full bg-amber-500/90 px-2 py-0.5 text-[10px] font-semibold text-amber-950">
                    Pending review
                  </span>
                )}

                <div className="flex items-center justify-between gap-2 bg-black/40 p-2 backdrop-blur-sm">
                  <button
                    type="button"
                    onClick={() => setPrimary(p.PhotoId)}
                    disabled={p.IsPrimary || busyId === p.PhotoId}
                    className="flex flex-1 cursor-pointer items-center justify-center gap-1 rounded-lg py-1.5 text-xs font-medium text-white/70 transition-colors duration-150 hover:bg-white/10 hover:text-white disabled:cursor-not-allowed disabled:opacity-40"
                  >
                    {busyId === p.PhotoId ? <Loader2 className="size-3.5 animate-spin" /> : <Star className="size-3.5" />}
                    Set primary
                  </button>
                  <button
                    type="button"
                    onClick={() => removePhoto(p.PhotoId)}
                    disabled={busyId === p.PhotoId}
                    className="flex cursor-pointer items-center justify-center rounded-lg p-1.5 text-red-400/80 transition-colors duration-150 hover:bg-red-500/10 hover:text-red-400 disabled:cursor-not-allowed disabled:opacity-40"
                    aria-label="Delete photo"
                  >
                    <Trash2 className="size-3.5" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
