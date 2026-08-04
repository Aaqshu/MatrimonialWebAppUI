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
import { Switch } from '@/components/ui/switch';

interface Template {
  id: string;
  templateName: string;
  subject: string;
  body: string;
  isActive: boolean;
}

const EMPTY_FORM = { templateName: '', subject: '', body: '' };

export default function TemplatesPage() {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Template | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [preview, setPreview] = useState('');

  const fetch = () => api.get('/admin/email-templates').then(({ data }) => setTemplates(data)).catch(console.error);
  useEffect(() => { fetch(); }, []);

  const openCreate = () => {
    setEditing(null);
    setForm(EMPTY_FORM);
    setPreview('');
    setOpen(true);
  };

  const openEdit = (t: Template) => {
    setEditing(t);
    setForm({ templateName: t.templateName, subject: t.subject, body: t.body });
    setPreview('');
    setOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (editing) await api.patch(`/admin/email-templates/${editing.id}`, form);
    else await api.post('/admin/email-templates', form);
    setOpen(false);
    fetch();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this template?')) return;
    await api.delete(`/admin/email-templates/${id}`);
    fetch();
  };

  const handleToggle = async (t: Template) => {
    await api.patch(`/admin/email-templates/${t.id}`, { isActive: !t.isActive });
    fetch();
  };

  // R&D: template variables used across the platform (matches development-process.md phase 6)
  const variables = ['{{FirstName}}', '{{LastName}}', '{{OTP}}', '{{VerificationLink}}', '{{LoginLink}}', '{{ProfileLink}}', '{{MatchPercentage}}', '{{SenderName}}'];

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-2xl font-bold">Email Templates</h2>
          <p className="text-sm text-gray-400 mt-1">Transactional emails for auth, matches &amp; notifications</p>
        </div>
        <Button onClick={openCreate}>Add Template</Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="bg-gray-900 border-gray-700 text-white max-w-2xl">
          <DialogHeader><DialogTitle>{editing ? 'Edit Template' : 'New Template'}</DialogTitle></DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <div><Label>Name</Label><Input value={form.templateName} onChange={e => setForm({...form, templateName: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
              <div><Label>Subject</Label><Input value={form.subject} onChange={e => setForm({...form, subject: e.target.value})} className="bg-gray-800 border-gray-700" required /></div>
            </div>
            <div>
              <Label>Body <span className="text-gray-500 text-xs">(HTML supported)</span></Label>
              <textarea rows={6} value={form.body} onChange={e => setForm({...form, body: e.target.value})} className="w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm text-white font-mono" required />
            </div>
            <div className="flex flex-wrap gap-1.5">
              {variables.map(v => (
                <button key={v} type="button" onClick={() => setForm({...form, body: form.body + v})}
                  className="text-xs px-2 py-1 rounded bg-gray-800 border border-gray-700 text-gray-300 hover:border-emerald-500 hover:text-emerald-400">
                  {v}
                </button>
              ))}
            </div>
            {preview && (
              <div className="border border-gray-700 rounded p-3 bg-gray-950">
                <Label className="text-xs text-gray-500">Preview</Label>
                <div className="text-sm mt-1 whitespace-pre-wrap">{preview}</div>
              </div>
            )}
            <Button type="submit" className="w-full">{editing ? 'Save Changes' : 'Create Template'}</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Card className="bg-gray-900 border-gray-800">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-gray-800">
                <TableHead className="text-gray-400">Name</TableHead>
                <TableHead className="text-gray-400">Subject</TableHead>
                <TableHead className="text-gray-400">Active</TableHead>
                <TableHead className="text-gray-400 text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {templates.map((t) => (
                <TableRow key={t.id} className="border-gray-800">
                  <TableCell className="font-medium">{t.templateName}</TableCell>
                  <TableCell className="text-gray-400">{t.subject}</TableCell>
                  <TableCell>
                    <Switch checked={t.isActive} onCheckedChange={() => handleToggle(t)} aria-label="toggle" />
                  </TableCell>
                  <TableCell className="text-right space-x-2">
                    <Button variant="ghost" size="sm" onClick={() => { setPreview(t.body); openEdit(t); }}>Edit</Button>
                    <Button variant="ghost" size="sm" className="text-red-400 hover:text-red-300" onClick={() => handleDelete(t.id)}>Delete</Button>
                  </TableCell>
                </TableRow>
              ))}
              {templates.length === 0 && <TableRow><TableCell colSpan={4} className="text-center text-gray-500 py-8">No templates yet</TableCell></TableRow>}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
