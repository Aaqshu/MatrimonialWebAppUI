'use client';

import { useCallback, useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Archive, Download, Loader2, RefreshCw, Trash2 } from 'lucide-react';

interface Backup {
  name: string;
  size: number;
  modified: string;
}

function fmtSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

export default function BackupsPage() {
  const [backups, setBackups] = useState<Backup[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [message, setMessage] = useState('');

  const load = useCallback(() => {
    api.get('/admin/backups')
      .then(({ data }) => setBackups(data.backups ?? []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { load(); }, [load]);

  const create = async () => {
    setCreating(true);
    setMessage('');
    try {
      const { data } = await api.post('/admin/backups');
      setMessage(`Backup created: ${data.backups.length} database(s) dumped (admin + tenants)`);
      load();
    } catch (e: any) {
      setMessage('Backup failed — check server logs');
    } finally {
      setCreating(false);
    }
  };

  const download = (name: string) => {
    window.open(`${process.env.NEXT_PUBLIC_API_URL || 'http://178.212.35.171:3001'}/admin/backups/${name}`, '_blank');
  };

  const remove = async (name: string) => {
    if (!confirm(`Delete backup ${name}?`)) return;
    await api.post(`/admin/backups/${name}/delete`);
    load();
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-lg">Database Backups</CardTitle>
          <Button onClick={create} disabled={creating}>
            {creating ? <Loader2 className="size-4 animate-spin" /> : <Archive className="size-4" />}
            {creating ? 'Backing up…' : 'Create Backup Now'}
          </Button>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-white/60">
            Full SQL dumps (schema + data) of the admin database and every tenant database, via pg_dump.
            Stored on the server — last {backups.length > 0 ? backups.length : 10} kept. Download a file and re-import with psql to restore.
          </p>
          {message && (
            <p className="mt-3 rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-3 py-2 text-sm text-emerald-300">
              {message}
            </p>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-lg">Backup History</CardTitle>
          <Button variant="ghost" size="sm" onClick={load}>
            <RefreshCw className="size-4" />
          </Button>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-10 text-white/40">
              <Loader2 className="size-5 animate-spin" />
            </div>
          ) : backups.length === 0 ? (
            <div className="rounded-xl border border-dashed border-white/15 py-12 text-center text-sm text-white/40">
              <Archive className="mx-auto mb-2 size-6 text-white/20" />
              No backups yet — click "Create Backup Now"
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>File</TableHead>
                  <TableHead>Size</TableHead>
                  <TableHead>Created</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {backups.map(b => (
                  <TableRow key={b.name}>
                    <TableCell className="font-mono text-xs">{b.name}</TableCell>
                    <TableCell>{fmtSize(b.size)}</TableCell>
                    <TableCell>{new Date(b.modified).toLocaleString()}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-1">
                        <Button variant="ghost" size="sm" onClick={() => download(b.name)} title="Download">
                          <Download className="size-4" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => remove(b.name)} title="Delete" className="text-red-400 hover:text-red-300">
                          <Trash2 className="size-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
