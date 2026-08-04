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
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

interface Plan {
  id: string;
  planName: string;
  description: string;
  price: number;
  billingCycle: string;
  isActive: boolean;
}

const EMPTY_FORM = { planName: '', description: '', price: '', billingCycle: 'monthly' };

export default function PlansPage() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Plan | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);

  const fetchPlans = () => api.get('/admin/plans').then(({ data }) => setPlans(data.map((p: any) => ({
    id: p.PlanId, planName: p.PlanName, description: p.Description, price: Number(p.Price), billingCycle: p.BillingCycle, isActive: p.IsActive,
  })))).catch(console.error);
  useEffect(() => { fetchPlans(); }, []);

  const openCreate = () => {
    setEditing(null);
    setForm(EMPTY_FORM);
    setOpen(true);
  };

  const openEdit = (p: Plan) => {
    setEditing(p);
    setForm({ planName: p.planName, description: p.description || '', price: String(p.price), billingCycle: p.billingCycle });
    setOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      PlanName: form.planName,
      Description: form.description || null,
      Price: parseFloat(form.price),
      BillingCycle: form.billingCycle,
    };
    if (editing) await api.patch(`/admin/plans/${editing.id}`, payload);
    else await api.post('/admin/plans', payload);
    setOpen(false);
    fetchPlans();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this plan?')) return;
    await api.delete(`/admin/plans/${id}`);
    fetchPlans();
  };

  const handleToggle = async (p: Plan) => {
    await api.patch(`/admin/plans/${p.id}`, { IsActive: !p.isActive });
    fetchPlans();
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-2xl font-bold">Subscription Plans</h2>
          <p className="text-sm text-gray-400 mt-1">Tiers billed to tenants (Razorpay payment integration ready)</p>
        </div>
        <Button onClick={openCreate}>Add Plan</Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="bg-gray-900 border-gray-700 text-white max-w-lg">
          <DialogHeader><DialogTitle>{editing ? 'Edit Plan' : 'New Plan'}</DialogTitle></DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <div><Label>Name</Label><Input value={form.planName} onChange={e => setForm({...form, planName: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <div><Label>Price (₹)</Label><Input type="number" step="0.01" min="0" value={form.price} onChange={e => setForm({...form, price: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <div className="col-span-2"><Label>Description</Label><Input value={form.description} onChange={e => setForm({...form, description: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
              <div>
                <Label>Billing Cycle</Label>
                <Select value={form.billingCycle} onValueChange={v => setForm({...form, billingCycle: v ?? 'monthly'})}>
                  <SelectTrigger className="bg-gray-800 border-gray-700"><SelectValue /></SelectTrigger>
                  <SelectContent className="bg-gray-800 border-gray-700">
                    <SelectItem value="monthly">Monthly</SelectItem>
                    <SelectItem value="yearly">Yearly</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <Button type="submit" className="w-full">{editing ? 'Save Changes' : 'Create Plan'}</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Card className="bg-gray-900 border-gray-800">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-gray-800">
                <TableHead className="text-gray-400">Name</TableHead>
                <TableHead className="text-gray-400">Price</TableHead>
                <TableHead className="text-gray-400">Billing</TableHead>
                <TableHead className="text-gray-400">Description</TableHead>
                <TableHead className="text-gray-400">Active</TableHead>
                <TableHead className="text-gray-400 text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {plans.map((p) => (
                <TableRow key={p.id} className="border-gray-800">
                  <TableCell className="font-medium">{p.planName}</TableCell>
                  <TableCell>₹{p.price}</TableCell>
                  <TableCell className="capitalize">{p.billingCycle}</TableCell>
                  <TableCell className="text-gray-400 max-w-xs truncate">{p.description || '—'}</TableCell>
                  <TableCell>
                    <Switch checked={p.isActive} onCheckedChange={() => handleToggle(p)} aria-label="toggle" />
                  </TableCell>
                  <TableCell className="text-right space-x-2">
                    <Button variant="ghost" size="sm" onClick={() => openEdit(p)}>Edit</Button>
                    <Button variant="ghost" size="sm" className="text-red-400 hover:text-red-300" onClick={() => handleDelete(p.id)}>Delete</Button>
                  </TableCell>
                </TableRow>
              ))}
              {plans.length === 0 && <TableRow><TableCell colSpan={6} className="text-center text-gray-500 py-8">No plans yet</TableCell></TableRow>}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
