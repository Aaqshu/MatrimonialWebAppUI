'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Building2, CreditCard, Wallet } from 'lucide-react';

export default function DashboardPage() {
  const [stats, setStats] = useState<{ tenants: number; activePlans: number; recentPayments: number } | null>(null);

  useEffect(() => {
    api.get('/admin/dashboard').then(({ data }) => setStats(data)).catch(console.error);
  }, []);

  const cards = [
    {
      label: 'Total Tenants',
      value: stats?.tenants,
      icon: Building2,
      hint: 'Organizations on the platform',
    },
    {
      label: 'Active Plans',
      value: stats?.activePlans,
      icon: CreditCard,
      hint: 'Currently billable subscription tiers',
    },
    {
      label: 'Recent Payments',
      value: stats?.recentPayments,
      icon: Wallet,
      hint: 'Transactions in the last cycle',
    },
  ];

  return (
    <div>
      <div className="mb-8">
        <h2 className="text-2xl font-semibold tracking-tight">Dashboard</h2>
        <p className="mt-1 text-sm text-muted-foreground">Overview of your platform&apos;s activity</p>
      </div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {cards.map(({ label, value, icon: Icon, hint }) => (
          <Card
            key={label}
            className="group transition-all duration-200 hover:border-primary/30 hover:shadow-lg hover:shadow-black/10"
          >
            <CardHeader className="flex items-start justify-between">
              <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
              <div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary transition-colors group-hover:bg-primary/15">
                <Icon className="size-4.5" />
              </div>
            </CardHeader>
            <CardContent>
              <p className="text-3xl font-semibold tabular-nums">{value ?? '—'}</p>
              <p className="mt-1.5 text-xs text-muted-foreground">{hint}</p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
