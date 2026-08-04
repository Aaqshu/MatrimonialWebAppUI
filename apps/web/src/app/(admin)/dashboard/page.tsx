'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function DashboardPage() {
  const [stats, setStats] = useState<{ tenants: number; activePlans: number; recentPayments: number } | null>(null);

  useEffect(() => {
    api.get('/admin/dashboard').then(({ data }) => setStats(data)).catch(console.error);
  }, []);

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Dashboard</h2>
      <div className="grid grid-cols-3 gap-4">
        <Card className="bg-gray-900 border-gray-800">
          <CardHeader><CardTitle className="text-gray-400 text-sm">Total Tenants</CardTitle></CardHeader>
          <CardContent><p className="text-3xl font-bold">{stats?.tenants ?? '-'}</p></CardContent>
        </Card>
        <Card className="bg-gray-900 border-gray-800">
          <CardHeader><CardTitle className="text-gray-400 text-sm">Active Plans</CardTitle></CardHeader>
          <CardContent><p className="text-3xl font-bold">{stats?.activePlans ?? '-'}</p></CardContent>
        </Card>
        <Card className="bg-gray-900 border-gray-800">
          <CardHeader><CardTitle className="text-gray-400 text-sm">Recent Payments</CardTitle></CardHeader>
          <CardContent><p className="text-3xl font-bold">{stats?.recentPayments ?? '-'}</p></CardContent>
        </Card>
      </div>
    </div>
  );
}
