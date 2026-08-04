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

interface Template {
  id: string;
  templateName: string;
  subject: string;
  isActive: boolean;
}

export default function TemplatesPage() {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ templateName: '', subject: '', body: '' });

  const fetch = () => api.get('/admin/email-templates').then(({ data }) => setTemplates(data)).catch(console.error);
  useEffect(() => { fetch(); }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    await api.post('/admin/email-templates', form);
    setOpen(false);
    setForm({ templateName: '', subject: '', body: '' });
    fetch();
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Email Templates</h2>
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger render={<Button>Add Template</Button>} />
          <DialogContent className="bg-gray-900 border-gray-700 text-white">
            <DialogHeader><DialogTitle>New Template</DialogTitle></DialogHeader>
            <form onSubmit={handleCreate} className="space-y-3">
              <div><Label>Name</Label><Input value={form.templateName} onChange={e => setForm({...form, templateName: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <div><Label>Subject</Label><Input value={form.subject} onChange={e => setForm({...form, subject: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <div><Label>Body</Label><textarea rows={4} value={form.body} onChange={e => setForm({...form, body: e.target.value})} className="w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm text-white" required /></div>
              <Button type="submit" className="w-full">Create</Button>
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
                <TableHead className="text-gray-400">Subject</TableHead>
                <TableHead className="text-gray-400">Active</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {templates.map((t) => (
                <TableRow key={t.id} className="border-gray-800">
                  <TableCell>{t.templateName}</TableCell>
                  <TableCell className="text-gray-400">{t.subject}</TableCell>
                  <TableCell><Badge variant={t.isActive ? 'default' : 'secondary'}>{t.isActive ? 'Yes' : 'No'}</Badge></TableCell>
                </TableRow>
              ))}
              {templates.length === 0 && <TableRow><TableCell colSpan={3} className="text-center text-gray-500 py-8">No templates</TableCell></TableRow>}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
