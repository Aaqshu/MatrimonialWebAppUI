'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';

interface Subscription {
  TenantSubscriptionId: string;
  TenantId: string;
  PlanId: string;
  CompanyName: string;
  PlanName: string;
  StartDate: string;
  EndDate: string;
  Amount: number;
  PaymentStatus: string;
  SubscriptionStatus: string;
}

export default function SubscriptionsPage() {
  const [subs, setSubs] = useState<Subscription[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ TenantId: '', PlanId: '', StartDate: '', EndDate: '', Amount: '' });

  const fetch = () => api.get('/admin/subscriptions').then(({ data }) => setSubs(data)).catch(console.error);
  useEffect(() => { fetch(); }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    await api.post('/admin/subscriptions', { ...form, Amount: parseFloat(form.Amount), PaymentStatus: 'pending', SubscriptionStatus: 'active' });
    setOpen(false);
    setForm({ TenantId: '', PlanId: '', StartDate: '', EndDate: '', Amount: '' });
    fetch();
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-2xl font-bold">Tenant Subscriptions</h2>
          <p className="text-sm text-gray-400 mt-1">Plans billed to tenants</p>
        </div>
        <Button onClick={() => setOpen(true)}>Add Subscription</Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="bg-gray-900 border-gray-700 text-white">
          <DialogHeader><DialogTitle>New Subscription</DialogTitle></DialogHeader>
          <form onSubmit={handleCreate} className="space-y-3">
            <div><Label>Tenant ID</Label><Input value={form.TenantId} onChange={e => setForm({...form, TenantId: e.target.value})} className="bg-gray-800 border-gray-700 font-mono" required /></div>
            <div><Label>Plan ID</Label><Input value={form.PlanId} onChange={e => setForm({...form, PlanId: e.target.value})} className="bg-gray-800 border-gray-700 font-mono" required /></div>
            <div className="grid grid-cols-2 gap-3">
              <div><Label>Start</Label><Input type="date" value={form.StartDate} onChange={e => setForm({...form, StartDate: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <div><Label>End</Label><Input type="date" value={form.EndDate} onChange={e => setForm({...form, EndDate: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
            </div>
            <div><Label>Amount (₹)</Label><Input type="number" value={form.Amount} onChange={e => setForm({...form, Amount: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
            <Button type="submit" className="w-full">Create</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Card className="bg-gray-900 border-gray-800">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-gray-800">
                <TableHead className="text-gray-400">Tenant</TableHead>
                <TableHead className="text-gray-400">Plan</TableHead>
                <TableHead className="text-gray-400">Amount</TableHead>
                <TableHead className="text-gray-400">Period</TableHead>
                <TableHead className="text-gray-400">Payment</TableHead>
                <TableHead className="text-gray-400">Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {subs.map((s) => (
                <TableRow key={s.TenantSubscriptionId} className="border-gray-800">
                  <TableCell>{s.CompanyName || s.TenantId.slice(0, 8)}</TableCell>
                  <TableCell>{s.PlanName || s.PlanId.slice(0, 8)}</TableCell>
                  <TableCell>₹{s.Amount}</TableCell>
                  <TableCell className="text-gray-400 text-xs">{s.StartDate?.slice(0, 10)} → {s.EndDate?.slice(0, 10) || '∞'}</TableCell>
                  <TableCell><Badge variant={s.PaymentStatus === 'paid' ? 'default' : 'secondary'}>{s.PaymentStatus}</Badge></TableCell>
                  <TableCell><Badge variant={s.SubscriptionStatus === 'active' ? 'default' : 'secondary'}>{s.SubscriptionStatus}</Badge></TableCell>
                </TableRow>
              ))}
              {subs.length === 0 && <TableRow><TableCell colSpan={6} className="text-center text-gray-500 py-8">No subscriptions yet</TableCell></TableRow>}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
