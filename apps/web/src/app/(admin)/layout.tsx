'use client';

import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: '📊' },
  { href: '/tenants', label: 'Tenants', icon: '🏢' },
  { href: '/plans', label: 'Plans', icon: '💳' },
  { href: '/templates', label: 'Email Templates', icon: '📧' },
  { href: '/settings', label: 'Settings', icon: '⚙️' },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [authed, setAuthed] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem('admin_token');
    if (!token) {
      router.push('/login');
    } else {
      setAuthed(true);
    }
  }, [router]);

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    router.push('/login');
  };

  if (!authed) return null;

  return (
    <div className="flex h-screen bg-gray-950 text-white">
      <aside className="w-60 bg-gray-900 border-r border-gray-800 p-4 flex flex-col">
        <h1 className="text-lg font-bold mb-4">Matrimonial Admin</h1>
        <nav className="flex-1 space-y-1">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm ${
                pathname === item.href ? 'bg-gray-800 text-white' : 'text-gray-400 hover:text-white hover:bg-gray-800'
              }`}
            >
              <span>{item.icon}</span>
              {item.label}
            </Link>
          ))}
        </nav>
        <Separator className="my-2 bg-gray-700" />
        <Button variant="ghost" onClick={handleLogout} className="text-gray-400 hover:text-white justify-start">
          Sign Out
        </Button>
      </aside>
      <main className="flex-1 overflow-auto p-6">{children}</main>
    </div>
  );
}
