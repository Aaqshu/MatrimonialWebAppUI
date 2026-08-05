'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Repeat, Plus } from 'lucide-react';

const statusColors: Record<string, string> = {
  active: 'bg-primary/15 text-primary border-primary/30',
  past_due: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  cancelled: 'bg-muted text-muted-foreground border-border',
  paid: 'bg-primary/15 text-primary border-primary/30',
  pending: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  failed: 'bg-destructive/15 text-destructive border-destructive/30',
};

const StatusBadge = ({ value }: { value: string }) => (
  <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs capitalize ${statusColors[value] || 'bg-muted text-muted-foreground border-border'}`}>
    {value.replace('_', ' ')}
  </span>
);

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

interface TenantOption { TenantId: string; CompanyName: string; }
interface PlanOption { PlanId: string; PlanName: string; Price: number; BillingCycle: string; }

const today = () => new Date().toISOString().slice(0, 10);

const addMonths = (base: string, months: number) => {
  const d = new Date(base + 'T00:00:00');
  d.setMonth(d.getMonth() + months);
  return d.toISOString().slice(0, 10);
};

const addDays = (base: string, days: number) => {
  const d = new Date(base + 'T00:00:00');
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
};

export default function SubscriptionsPage() {
  const [subs, setSubs] = useState<Subscription[]>([]);
  const [tenants, setTenants] = useState<TenantOption[]>([]);
  const [plans, setPlans] = useState<PlanOption[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ TenantId: '', PlanId: '', StartDate: today(), EndDate: '' });

  const fetch = () => api.get('/admin/subscriptions').then(({ data }) => setSubs(data)).catch(console.error);
  const fetchOptions = () => {
    api.get('/admin/tenants').then(({ data }) => setTenants(data.map((t: any) => ({ TenantId: t.TenantId, CompanyName: t.CompanyName })))).catch(console.error);
    api.get('/admin/plans').then(({ data }) => setPlans(data.map((p: any) => ({ PlanId: p.PlanId, PlanName: p.PlanName, Price: Number(p.Price), BillingCycle: p.BillingCycle })))).catch(console.error);
  };

  useEffect(() => { fetch(); fetchOptions(); }, []);

  const openCreate = () => {
    setForm({ TenantId: '', PlanId: '', StartDate: today(), EndDate: '' });
    setOpen(true);
  };

  const handlePlanChange = (planId: string | null) => {
    if (!planId) return;
    const plan = plans.find(p => p.PlanId === planId);
    if (!plan) { setForm({ ...form, PlanId: planId }); return; }
    const end = plan.BillingCycle === 'yearly' ? addDays(today(), 365) : addMonths(today(), 1);
    setForm({ ...form, PlanId: planId, StartDate: today(), EndDate: end });
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    const plan = plans.find(p => p.PlanId === form.PlanId);
    await api.post('/admin/subscriptions', {
      TenantId: form.TenantId,
      PlanId: form.PlanId,
      StartDate: form.StartDate,
      EndDate: form.EndDate,
      Amount: plan?.Price ?? 0,
      PaymentStatus: 'pending',
      SubscriptionStatus: 'active',
    });
    setOpen(false);
    fetch();
  };

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Tenant Subscriptions</h2>
          <p className="mt-1 text-sm text-muted-foreground">Plans billed to tenants</p>
        </div>
        <Button onClick={openCreate}><Plus />Add Subscription</Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>New Subscription</DialogTitle></DialogHeader>
          <form onSubmit={handleCreate} className="space-y-3">
            <div>
              <Label>Tenant</Label>
              <Select value={form.TenantId} onValueChange={v => setForm({...form, TenantId: v ?? ''})}>
                <SelectTrigger className="w-full">
                  <SelectValue>
                    {(v: string | null) => v ? (tenants.find(t => t.TenantId === v)?.CompanyName ?? v) : 'Select tenant'}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  {tenants.map(t => <SelectItem key={t.TenantId} value={t.TenantId}>{t.CompanyName}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Plan</Label>
              <Select value={form.PlanId} onValueChange={handlePlanChange}>
                <SelectTrigger className="w-full">
                  <SelectValue>
                    {(v: string | null) => v ? (plans.find(p => p.PlanId === v)?.PlanName ?? v) : 'Select plan'}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  {plans.map(p => <SelectItem key={p.PlanId} value={p.PlanId}>{p.PlanName} — ₹{p.Price}/{p.BillingCycle}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div><Label>Start Date</Label><Input type="date" value={form.StartDate} onChange={e => setForm({...form, StartDate: e.target.value})} required /></div>
              <div><Label>End Date</Label><Input type="date" value={form.EndDate} onChange={e => setForm({...form, EndDate: e.target.value})} required /></div>
            </div>
            <p className="text-xs text-muted-foreground">Dates auto-fill from plan billing cycle — adjust if needed.</p>
            <Button type="submit" className="w-full">Create</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Tenant</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Plan</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Amount</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Period</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Payment</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {subs.map((s) => (
                <TableRow key={s.TenantSubscriptionId}>
                  <TableCell className="font-medium">{s.CompanyName || s.TenantId.slice(0, 8)}</TableCell>
                  <TableCell>{s.PlanName || s.PlanId.slice(0, 8)}</TableCell>
                  <TableCell className="tabular-nums">₹{s.Amount}</TableCell>
                  <TableCell className="text-xs text-muted-foreground">{s.StartDate?.slice(0, 10)} → {s.EndDate?.slice(0, 10) || '∞'}</TableCell>
                  <TableCell><StatusBadge value={s.PaymentStatus} /></TableCell>
                  <TableCell><StatusBadge value={s.SubscriptionStatus} /></TableCell>
                </TableRow>
              ))}
              {subs.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="py-14 text-center">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <Repeat className="size-8 opacity-40" />
                      <p className="text-sm">No subscriptions yet</p>
                    </div>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
