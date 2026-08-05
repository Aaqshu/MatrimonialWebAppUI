'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Switch } from '@/components/ui/switch';
import { Mail, Plus, Pencil, Trash2 } from 'lucide-react';

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

  const fetch = () => api.get('/admin/email-templates').then(({ data }) => setTemplates(data.map((t: any) => ({
    id: t.TemplateId, templateName: t.TemplateName, subject: t.Subject, body: t.Body, isActive: t.IsActive,
  })))).catch(console.error);
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
    const payload = { TemplateName: form.templateName, Subject: form.subject, Body: form.body };
    if (editing) await api.patch(`/admin/email-templates/${editing.id}`, payload);
    else await api.post('/admin/email-templates', payload);
    setOpen(false);
    fetch();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this template?')) return;
    await api.delete(`/admin/email-templates/${id}`);
    fetch();
  };

  const handleToggle = async (t: Template) => {
    await api.patch(`/admin/email-templates/${t.id}`, { IsActive: !t.isActive });
    fetch();
  };

  // R&D: template variables used across the platform (matches development-process.md phase 6)
  const variables = ['{{FirstName}}', '{{LastName}}', '{{OTP}}', '{{VerificationLink}}', '{{LoginLink}}', '{{ProfileLink}}', '{{MatchPercentage}}', '{{SenderName}}'];

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Email Templates</h2>
          <p className="mt-1 text-sm text-muted-foreground">Transactional emails for auth, matches &amp; notifications</p>
        </div>
        <Button onClick={openCreate}><Plus />Add Template</Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader><DialogTitle>{editing ? 'Edit Template' : 'New Template'}</DialogTitle></DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <div><Label>Name</Label><Input value={form.templateName} onChange={e => setForm({...form, templateName: e.target.value})} required /></div>
              <div><Label>Subject</Label><Input value={form.subject} onChange={e => setForm({...form, subject: e.target.value})} required /></div>
            </div>
            <div>
              <Label>Body <span className="text-xs text-muted-foreground">(HTML supported)</span></Label>
              <textarea rows={6} value={form.body} onChange={e => setForm({...form, body: e.target.value})} className="w-full rounded-lg border border-input bg-transparent px-3 py-2 text-sm text-foreground outline-none transition-colors focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30 font-mono" required />
            </div>
            <div className="flex flex-wrap gap-1.5">
              {variables.map(v => (
                <button key={v} type="button" onClick={() => setForm({...form, body: form.body + v})}
                  className="cursor-pointer rounded-md border border-input bg-transparent px-2 py-1 text-xs text-muted-foreground transition-colors hover:border-primary/40 hover:text-primary">
                  {v}
                </button>
              ))}
            </div>
            {preview && (
              <div className="rounded-lg border border-input p-3">
                <Label className="text-xs text-muted-foreground">Preview</Label>
                <div className="mt-1 text-sm whitespace-pre-wrap">{preview}</div>
              </div>
            )}
            <Button type="submit" className="w-full">{editing ? 'Save Changes' : 'Create Template'}</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Name</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Subject</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Active</TableHead>
                <TableHead className="text-right text-xs uppercase tracking-wide text-muted-foreground">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {templates.map((t) => (
                <TableRow key={t.id}>
                  <TableCell className="font-medium">{t.templateName}</TableCell>
                  <TableCell className="text-muted-foreground">{t.subject}</TableCell>
                  <TableCell>
                    <Switch checked={t.isActive} onCheckedChange={() => handleToggle(t)} aria-label="toggle" />
                  </TableCell>
                  <TableCell className="text-right">
                    <Button variant="ghost" size="icon-sm" onClick={() => { setPreview(t.body); openEdit(t); }} aria-label="Edit template"><Pencil /></Button>
                    <Button variant="ghost" size="icon-sm" className="text-destructive hover:text-destructive" onClick={() => handleDelete(t.id)} aria-label="Delete template"><Trash2 /></Button>
                  </TableCell>
                </TableRow>
              ))}
              {templates.length === 0 && (
                <TableRow>
                  <TableCell colSpan={4} className="py-14 text-center">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <Mail className="size-8 opacity-40" />
                      <p className="text-sm">No templates yet</p>
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
