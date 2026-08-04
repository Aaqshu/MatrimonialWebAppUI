'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';

interface Plan {
  id: string;
  planName: string;
  description: string;
  price: number;
  billingCycle: string;
  isActive: boolean;
}

export default function PlansPage() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ planName: '', description: '', price: '', billingCycle: 'monthly' });

  const fetchPlans = () => api.get('/admin/plans').then(({ data }) => setPlans(data)).catch(console.error);
  useEffect(() => { fetchPlans(); }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    await api.post('/admin/plans', { ...form, price: parseFloat(form.price) });
    setOpen(false);
    setForm({ planName: '', description: '', price: '', billingCycle: 'monthly' });
    fetchPlans();
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Subscription Plans</h2>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild><Button>Add Plan</Button></DialogTrigger>
          <DialogContent className="bg-gray-900 border-gray-700 text-white">
            <DialogHeader><DialogTitle>New Plan</DialogTitle></DialogHeader>
            <form onSubmit={handleCreate} className="space-y-3">
              <div><Label>Name</Label><Input value={form.planName} onChange={e => setForm({...form, planName: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <div><Label>Description</Label><Input value={form.description} onChange={e => setForm({...form, description: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
              <div><Label>Price (₹)</Label><Input type="number" value={form.price} onChange={e => setForm({...form, price: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <Button type="submit" className="w-full">Create Plan</Button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
      <Card className="bg-gray-900 border-gray-800">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-gray-800">
                <TableHead className="text-gray-400">Name</TableHead>
                <TableHead className="text-gray-400">Price</TableHead>
                <TableHead className="text-gray-400">Billing</TableHead>
                <TableHead className="text-gray-400">Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {plans.map((p) => (
                <TableRow key={p.id} className="border-gray-800">
                  <TableCell className="font-medium">{p.planName}</TableCell>
                  <TableCell>₹{p.price}</TableCell>
                  <TableCell>{p.billingCycle}</TableCell>
                  <TableCell><Badge variant={p.isActive ? 'default' : 'secondary'}>{p.isActive ? 'Active' : 'Inactive'}</Badge></TableCell>
                </TableRow>
              ))}
              {plans.length === 0 && <TableRow><TableCell colSpan={4} className="text-center text-gray-500 py-8">No plans yet</TableCell></TableRow>}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
