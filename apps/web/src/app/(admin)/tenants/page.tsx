'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Building2, CircleDot, Plus } from 'lucide-react';

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
  const router = useRouter();
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
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Tenants</h2>
          <p className="mt-1 text-sm text-muted-foreground">Organizations provisioned on the platform</p>
        </div>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger render={<Button><Plus />Add Tenant</Button>} />
          <DialogContent className="max-w-lg">
            <DialogHeader><DialogTitle>New Tenant</DialogTitle></DialogHeader>
            <form onSubmit={handleCreate} className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div><Label>Code</Label><Input value={form.tenantCode} onChange={e => setForm({...form, tenantCode: e.target.value})} required /></div>
                <div><Label>Company Name</Label><Input value={form.companyName} onChange={e => setForm({...form, companyName: e.target.value})} required /></div>
                <div><Label>Owner</Label><Input value={form.ownerName} onChange={e => setForm({...form, ownerName: e.target.value})} /></div>
                <div><Label>Email</Label><Input value={form.email} onChange={e => setForm({...form, email: e.target.value})} required /></div>
                <div><Label>Phone</Label><Input value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} /></div>
                <div><Label>City</Label><Input value={form.city} onChange={e => setForm({...form, city: e.target.value})} /></div>
                <div><Label>State</Label><Input value={form.state} onChange={e => setForm({...form, state: e.target.value})} /></div>
                <div><Label>DB Server <span className="text-muted-foreground">(optional)</span></Label><Input value={form.databaseServer} onChange={e => setForm({...form, databaseServer: e.target.value})} /></div>
                <div className="col-span-2"><Label>Secret Ref <span className="text-muted-foreground">(optional)</span></Label><Input value={form.connectionSecretRef} onChange={e => setForm({...form, connectionSecretRef: e.target.value})} /></div>
              </div>
              <Button type="submit" className="w-full">Create Tenant</Button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Code</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Company</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Owner</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Email</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Active</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tenants.map((t) => (
                <TableRow key={t.id} className="cursor-pointer" onClick={() => router.push(`/tenants/${t.id}`)}>
                  <TableCell className="font-mono text-sm underline-offset-4 hover:underline">{t.tenantCode}</TableCell>
                  <TableCell className="font-medium">{t.companyName}</TableCell>
                  <TableCell>{t.ownerName}</TableCell>
                  <TableCell className="text-muted-foreground">{t.email}</TableCell>
                  <TableCell><Badge variant={t.status === 'active' ? 'default' : 'secondary'}>{t.status}</Badge></TableCell>
                  <TableCell onClick={e => e.stopPropagation()}>
                    <Button variant="ghost" size="icon-sm" onClick={() => handleToggle(t.id, t.isActive)} aria-label={t.isActive ? 'Deactivate tenant' : 'Activate tenant'}>
                      <CircleDot className={t.isActive ? 'text-primary' : 'text-muted-foreground'} />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {tenants.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="py-14 text-center">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <Building2 className="size-8 opacity-40" />
                      <p className="text-sm">No tenants yet</p>
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
