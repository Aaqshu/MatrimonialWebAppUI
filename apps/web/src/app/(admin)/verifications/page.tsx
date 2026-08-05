'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { ShieldCheck, Check, X, Loader2 } from 'lucide-react';

interface VerificationRequest {
  VerificationId: string;
  UserId: string;
  DocType: string;
  DocReference: string;
  Status: 'pending' | 'approved' | 'rejected';
  CreatedOn: string;
  Phone: string;
  FirstName: string;
}

const statusColors: Record<string, string> = {
  pending: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  approved: 'bg-primary/15 text-primary border-primary/30',
  rejected: 'bg-destructive/15 text-destructive border-destructive/30',
};

const StatusBadge = ({ value }: { value: string }) => (
  <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs capitalize ${statusColors[value] || 'bg-muted text-muted-foreground border-border'}`}>
    {value}
  </span>
);

export default function VerificationsPage() {
  const [requests, setRequests] = useState<VerificationRequest[]>([]);
  const [busyId, setBusyId] = useState<string | null>(null);

  const fetchRequests = () => api.get('/admin/verifications').then(({ data }) => setRequests(data)).catch(console.error);
  useEffect(() => { fetchRequests(); }, []);

  const sorted = [...requests].sort((a, b) => {
    if (a.Status === b.Status) return new Date(b.CreatedOn).getTime() - new Date(a.CreatedOn).getTime();
    return a.Status === 'pending' ? -1 : b.Status === 'pending' ? 1 : 0;
  });

  const handleReview = async (id: string, status: 'approved' | 'rejected') => {
    setBusyId(id);
    try {
      await api.patch(`/admin/verifications/${id}`, { Status: status });
      await fetchRequests();
    } finally {
      setBusyId(null);
    }
  };

  const pendingCount = requests.filter(r => r.Status === 'pending').length;

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Verifications</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            {pendingCount > 0 ? `${pendingCount} request${pendingCount === 1 ? '' : 's'} awaiting review` : 'All caught up'}
          </p>
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">User</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Doc Type</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Reference</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Submitted</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                <TableHead className="text-right text-xs uppercase tracking-wide text-muted-foreground">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sorted.map((r) => (
                <TableRow key={r.VerificationId}>
                  <TableCell className="font-medium">{r.FirstName || '—'} <span className="text-muted-foreground">{r.Phone}</span></TableCell>
                  <TableCell className="capitalize">{r.DocType.replace('_', ' ')}</TableCell>
                  <TableCell className="text-muted-foreground">{r.DocReference}</TableCell>
                  <TableCell className="text-xs text-muted-foreground">{new Date(r.CreatedOn).toLocaleDateString()}</TableCell>
                  <TableCell><StatusBadge value={r.Status} /></TableCell>
                  <TableCell className="text-right">
                    {r.Status === 'pending' ? (
                      <div className="flex justify-end gap-1.5">
                        <Button
                          size="sm"
                          variant="outline"
                          className="text-primary hover:text-primary"
                          disabled={busyId === r.VerificationId}
                          onClick={() => handleReview(r.VerificationId, 'approved')}
                        >
                          {busyId === r.VerificationId ? <Loader2 className="animate-spin" /> : <Check />}
                          Approve
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          className="text-destructive hover:text-destructive"
                          disabled={busyId === r.VerificationId}
                          onClick={() => handleReview(r.VerificationId, 'rejected')}
                        >
                          <X />
                          Reject
                        </Button>
                      </div>
                    ) : (
                      <span className="text-xs text-muted-foreground">Reviewed</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
              {sorted.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="py-14 text-center">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <ShieldCheck className="size-8 opacity-40" />
                      <p className="text-sm">No verification requests</p>
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
