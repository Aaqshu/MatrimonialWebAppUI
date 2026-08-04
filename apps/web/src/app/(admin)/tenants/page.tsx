'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

interface Tenant {
  id: string;
  tenantCode: string;
  companyName: string;
  ownerName: string;
  email: string;
  phone: string;
  city: string;
  status: string;
  isActive: boolean;
}

export default function TenantsPage() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ tenantCode: '', companyName: '', ownerName: '', email: '', phone: '', city: '', state: '', country: 'India', databaseServer: '', connectionSecretRef: '' });

  const fetchTenants = () =>
    api.get('/admin/tenants')
      .then(({ data }) => setTenants(data.map((t: any) => ({
        id: t.TenantId,
        tenantCode: t.TenantCode,
        companyName: t.CompanyName,
        ownerName: t.OwnerName,
        email: t.Email,
        phone: t.Phone,
        city: t.City,
        state: t.State,
        status: t.Status,
        isActive: t.IsActive,
      }))))
      .catch(console.error);

  useEffect(() => { fetchTenants(); }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    await api.post('/admin/tenants', form);
    setOpen(false);
    setForm({ tenantCode: '', companyName: '', ownerName: '', email: '', phone: '', city: '', state: '', country: 'India', databaseServer: '', connectionSecretRef: '' });
    fetchTenants();
  };

  const handleToggle = async (id: string, isActive: boolean) => {
    await api.patch(`/admin/tenants/${id}`, { IsActive: !isActive, Status: !isActive ? 'active' : 'suspended' });
    fetchTenants();
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Tenants</h2>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger render={<Button>Add Tenant</Button>} />
          <DialogContent className="bg-gray-900 border-gray-700 text-white max-w-lg">
            <DialogHeader><DialogTitle>New Tenant</DialogTitle></DialogHeader>
            <form onSubmit={handleCreate} className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div><Label>Code</Label><Input value={form.tenantCode} onChange={e => setForm({...form, tenantCode: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
                <div><Label>Company Name</Label><Input value={form.companyName} onChange={e => setForm({...form, companyName: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
                <div><Label>Owner</Label><Input value={form.ownerName} onChange={e => setForm({...form, ownerName: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
                <div><Label>Email</Label><Input value={form.email} onChange={e => setForm({...form, email: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
                <div><Label>Phone</Label><Input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
                <div><Label>City</Label><Input value={form.city} onChange={e => setForm({...form, city: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
                <div><Label>State</Label><Input value={form.state} onChange={e => setForm({...form, state: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
                <div><Label>DB Server <span className="text-gray-500">(optional)</span></Label><Input value={form.databaseServer} onChange={e => setForm({...form, databaseServer: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
                <div className="col-span-2"><Label>Secret Ref <span className="text-gray-500">(optional)</span></Label><Input value={form.connectionSecretRef} onChange={e => setForm({...form, connectionSecretRef: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
              </div>
              <Button type="submit" className="w-full">Create Tenant</Button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
      <Card className="bg-gray-900 border-gray-800">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-gray-800">
                <TableHead className="text-gray-400">Code</TableHead>
                <TableHead className="text-gray-400">Company</TableHead>
                <TableHead className="text-gray-400">Owner</TableHead>
                <TableHead className="text-gray-400">Email</TableHead>
                <TableHead className="text-gray-400">Status</TableHead>
                <TableHead className="text-gray-400">Active</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tenants.map((t) => (
                <TableRow key={t.id} className="border-gray-800">
                  <TableCell className="font-mono text-sm">{t.tenantCode}</TableCell>
                  <TableCell>{t.companyName}</TableCell>
                  <TableCell>{t.ownerName}</TableCell>
                  <TableCell className="text-gray-400">{t.email}</TableCell>
                  <TableCell><Badge variant={t.status === 'active' ? 'default' : 'secondary'}>{t.status}</Badge></TableCell>
                  <TableCell>
                    <Button variant="ghost" size="sm" onClick={() => handleToggle(t.id, t.isActive)}>
                      {t.isActive ? '🟢' : '🔴'}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {tenants.length === 0 && (
                <TableRow><TableCell colSpan={6} className="text-center text-gray-500 py-8">No tenants yet</TableCell></TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
