'use client';

import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import {
  HeartHandshake,
  LayoutDashboard,
  Building2,
  Repeat,
  Wallet,
  CreditCard,
  Mail,
  Users,
  Settings,
  LogOut,
  ShieldCheck,
  DatabaseBackup,
} from 'lucide-react';

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/tenants', label: 'Tenants', icon: Building2 },
  { href: '/subscriptions', label: 'Subscriptions', icon: Repeat },
  { href: '/payments', label: 'Payments', icon: Wallet },
  { href: '/plans', label: 'Plans', icon: CreditCard },
  { href: '/verifications', label: 'Verifications', icon: ShieldCheck },
  { href: '/templates', label: 'Email Templates', icon: Mail },
  { href: '/admin-users', label: 'Admin Users', icon: Users },
  { href: '/backups', label: 'Backups', icon: DatabaseBackup },
  { href: '/settings', label: 'Settings', icon: Settings },
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
    <div className="flex h-screen bg-background text-foreground">
      <aside className="flex w-64 flex-col border-r border-sidebar-border bg-sidebar p-4">
        <div className="mb-6 flex items-center gap-2.5 px-1">
          <div className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground">
            <HeartHandshake className="size-4.5" />
          </div>
          <div className="leading-tight">
            <p className="text-sm font-semibold text-sidebar-foreground">Matrimonial</p>
            <p className="text-xs text-muted-foreground">Admin Console</p>
          </div>
        </div>
        <nav className="flex-1 space-y-0.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`group relative flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium transition-colors duration-150 ${
                  active
                    ? 'bg-sidebar-accent text-sidebar-accent-foreground'
                    : 'text-muted-foreground hover:bg-sidebar-accent/60 hover:text-sidebar-foreground'
                }`}
              >
                {active && (
                  <span className="absolute -left-4 h-5 w-0.5 rounded-full bg-primary" />
                )}
                <Icon className={`size-4 shrink-0 ${active ? 'text-primary' : ''}`} />
                {item.label}
              </Link>
            );
          })}
        </nav>
        <Separator className="my-3" />
        <Button
          variant="ghost"
          onClick={handleLogout}
          className="justify-start gap-2.5 text-muted-foreground hover:text-foreground"
        >
          <LogOut className="size-4" />
          Sign Out
        </Button>
      </aside>
      <main className="flex-1 overflow-auto p-8">{children}</main>
    </div>
  );
}
