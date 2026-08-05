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
import { Users, Plus, Trash2 } from 'lucide-react';

interface AdminUser {
  AdminId: string;
  AdminUserName: string;
  FirstName: string;
  LastName: string;
  Email: string;
  Phone: string;
  Role: string;
  IsActive: boolean;
  LastLogin: string;
}

const EMPTY = { AdminUserName: '', Password: '', FirstName: '', LastName: '', Email: '', Phone: '', Role: 'support' };

export default function AdminUsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState(EMPTY);

  const fetchUsers = () => api.get('/admin/admin-users').then(({ data }) => setUsers(data)).catch(console.error);
  useEffect(() => { fetchUsers(); }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    await api.post('/admin/admin-users', { ...form, IsActive: true });
    setOpen(false);
    setForm(EMPTY);
    fetchUsers();
  };

  const handleToggle = async (u: AdminUser) => {
    await api.patch(`/admin/admin-users/${u.AdminId}`, { IsActive: !u.IsActive });
    fetchUsers();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this admin user?')) return;
    await api.delete(`/admin/admin-users/${id}`);
    fetchUsers();
  };

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Admin Users</h2>
          <p className="mt-1 text-sm text-muted-foreground">Platform staff accounts</p>
        </div>
        <Button onClick={() => setOpen(true)}><Plus />Add Admin</Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>New Admin User</DialogTitle></DialogHeader>
          <form onSubmit={handleCreate} className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <div><Label>Username</Label><Input value={form.AdminUserName} onChange={e => setForm({...form, AdminUserName: e.target.value})} required /></div>
              <div><Label>Password</Label><Input type="password" value={form.Password} onChange={e => setForm({...form, Password: e.target.value})} required /></div>
              <div><Label>First Name</Label><Input value={form.FirstName} onChange={e => setForm({...form, FirstName: e.target.value})} /></div>
              <div><Label>Last Name</Label><Input value={form.LastName} onChange={e => setForm({...form, LastName: e.target.value})} /></div>
              <div><Label>Email</Label><Input type="email" value={form.Email} onChange={e => setForm({...form, Email: e.target.value})} required /></div>
              <div><Label>Phone</Label><Input value={form.Phone} onChange={e => setForm({...form, Phone: e.target.value})} /></div>
              <div className="col-span-2">
                <Label>Role</Label>
                <Select value={form.Role} onValueChange={v => setForm({...form, Role: v ?? 'support'})}>
                  <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="super_admin">Super Admin</SelectItem>
                    <SelectItem value="support">Support</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <Button type="submit" className="w-full">Create</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Username</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Name</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Email</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Role</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Active</TableHead>
                <TableHead className="text-right text-xs uppercase tracking-wide text-muted-foreground">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((u) => (
                <TableRow key={u.AdminId}>
                  <TableCell className="font-medium">{u.AdminUserName}</TableCell>
                  <TableCell>{[u.FirstName, u.LastName].filter(Boolean).join(' ') || '—'}</TableCell>
                  <TableCell className="text-muted-foreground">{u.Email}</TableCell>
                  <TableCell><Badge variant={u.Role === 'super_admin' ? 'default' : 'secondary'}>{u.Role}</Badge></TableCell>
                  <TableCell><Switch checked={u.IsActive} onCheckedChange={() => handleToggle(u)} aria-label="toggle" /></TableCell>
                  <TableCell className="text-right">
                    <Button variant="ghost" size="icon-sm" className="text-destructive hover:text-destructive" onClick={() => handleDelete(u.AdminId)} aria-label="Delete admin user"><Trash2 /></Button>
                  </TableCell>
                </TableRow>
              ))}
              {users.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="py-14 text-center">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <Users className="size-8 opacity-40" />
                      <p className="text-sm">No admin users</p>
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
