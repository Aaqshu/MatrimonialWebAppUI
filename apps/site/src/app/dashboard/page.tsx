'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';

interface User {
  UserId: string;
  FirstName: string;
  LastName: string;
  Email: string;
  Phone: string;
  Status: string;
}

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    api.get('/site/me')
      .then(({ data }) => setUser(data))
      .catch(() => { window.location.href = '/'; });
  }, []);

  const logout = () => {
    localStorage.removeItem('site_token');
    window.location.href = '/';
  };

  if (!user) return <p className="p-10 text-gray-400">Loading...</p>;

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <nav className="border-b border-gray-800 px-6 py-4 flex justify-between items-center">
        <h1 className="font-bold text-emerald-400">Matrimony</h1>
        <button onClick={logout} className="text-sm text-gray-400 hover:text-white">Sign Out</button>
      </nav>
      <div className="max-w-4xl mx-auto p-8">
        <h2 className="text-2xl font-bold mb-6">Welcome, {user.FirstName}! 🎉</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded-xl border border-gray-800 bg-gray-900 p-5">
            <p className="text-sm text-gray-400">Profile Status</p>
            <p className="mt-1 text-lg font-medium capitalize">{user.Status.replace('_', ' ')}</p>
          </div>
          <div className="rounded-xl border border-gray-800 bg-gray-900 p-5">
            <p className="text-sm text-gray-400">Contact</p>
            <p className="mt-1 text-lg">{user.Phone || user.Email}</p>
          </div>
        </div>
        <div className="mt-8 rounded-xl border border-dashed border-gray-700 bg-gray-900/50 p-8 text-center">
          <p className="text-gray-400">Profile builder coming next — Phase 2</p>
        </div>
      </div>
    </div>
  );
}
