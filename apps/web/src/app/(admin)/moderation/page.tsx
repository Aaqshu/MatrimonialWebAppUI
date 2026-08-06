'use client';

import { useCallback, useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Flag, Check, X, Loader2, HeartHandshake, ShieldAlert } from 'lucide-react';

interface Report {
  ReportId: string;
  Reason: string;
  Description: string | null;
  Status: 'pending' | 'resolved' | 'dismissed';
  CreatedOn: string;
  ReporterPhone: string;
  ReportedPhone: string;
  ReportedFirstName: string;
}

interface Story {
  StoryId: string;
  FirstName1: string;
  FirstName2: string;
  Testimonial: string;
  IsPublished: boolean;
}

const reasonColors: Record<string, string> = {
  fake_profile: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  harassment: 'bg-destructive/15 text-destructive border-destructive/30',
  inappropriate_content: 'bg-destructive/15 text-destructive border-destructive/30',
  other: 'bg-muted text-muted-foreground border-border',
};

const reasonLabels: Record<string, string> = {
  fake_profile: 'Fake profile',
  harassment: 'Harassment',
  inappropriate_content: 'Inappropriate content',
  other: 'Other',
};

const statusColors: Record<string, string> = {
  pending: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  resolved: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
  dismissed: 'bg-muted text-muted-foreground border-border',
};

const ReasonBadge = ({ value }: { value: string }) => (
  <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs ${reasonColors[value] || 'bg-muted text-muted-foreground border-border'}`}>
    {reasonLabels[value] || value}
  </span>
);

const StatusBadge = ({ value }: { value: string }) => (
  <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs capitalize ${statusColors[value] || 'bg-muted text-muted-foreground border-border'}`}>
    {value}
  </span>
);

export default function ModerationPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [stories, setStories] = useState<Story[]>([]);
  const [busyId, setBusyId] = useState<string | null>(null);

  const fetchAll = useCallback(() => {
    api.get('/admin/moderation').then(({ data }) => {
      setReports(data.reports ?? []);
      setStories(data.stories ?? []);
    }).catch(console.error);
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  const sortedReports = [...reports].sort((a, b) => {
    if (a.Status === b.Status) return new Date(b.CreatedOn).getTime() - new Date(a.CreatedOn).getTime();
    return a.Status === 'pending' ? -1 : b.Status === 'pending' ? 1 : 0;
  });

  const handleReport = async (id: string, status: 'resolved' | 'dismissed') => {
    setBusyId(id);
    try {
      await api.patch(`/admin/moderation/reports/${id}`, { Status: status });
      await fetchAll();
    } finally {
      setBusyId(null);
    }
  };

  const handleStory = async (id: string, publish: boolean) => {
    setBusyId(id);
    try {
      await api.patch(`/admin/moderation/stories/${id}`, { IsPublished: publish });
      await fetchAll();
    } finally {
      setBusyId(null);
    }
  };

  const pendingCount = reports.filter(r => r.Status === 'pending').length;

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-2xl font-semibold tracking-tight">Moderation</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          {pendingCount > 0 ? `${pendingCount} report${pendingCount === 1 ? '' : 's'} awaiting review` : 'All caught up'}
        </p>
      </div>

      <Tabs defaultValue="reports">
        <TabsList>
          <TabsTrigger value="reports">Reports</TabsTrigger>
          <TabsTrigger value="stories">Stories</TabsTrigger>
        </TabsList>

        <TabsContent value="reports" className="mt-4">
          <Card>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Reason</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Description</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Reported User</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Reporter</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Created</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                    <TableHead className="text-right text-xs uppercase tracking-wide text-muted-foreground">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {sortedReports.map((r) => (
                    <TableRow key={r.ReportId}>
                      <TableCell><ReasonBadge value={r.Reason} /></TableCell>
                      <TableCell className="max-w-[220px] truncate text-muted-foreground">{r.Description || '—'}</TableCell>
                      <TableCell className="font-medium">{r.ReportedFirstName || '—'} <span className="text-muted-foreground">{r.ReportedPhone}</span></TableCell>
                      <TableCell className="text-muted-foreground">{r.ReporterPhone}</TableCell>
                      <TableCell className="text-xs text-muted-foreground">{new Date(r.CreatedOn).toLocaleDateString()}</TableCell>
                      <TableCell><StatusBadge value={r.Status} /></TableCell>
                      <TableCell className="text-right">
                        {r.Status === 'pending' ? (
                          <div className="flex justify-end gap-1.5">
                            <Button
                              size="sm"
                              variant="outline"
                              className="text-primary hover:text-primary"
                              disabled={busyId === r.ReportId}
                              onClick={() => handleReport(r.ReportId, 'resolved')}
                            >
                              {busyId === r.ReportId ? <Loader2 className="animate-spin" /> : <Check />}
                              Resolve
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              className="text-destructive hover:text-destructive"
                              disabled={busyId === r.ReportId}
                              onClick={() => handleReport(r.ReportId, 'dismissed')}
                            >
                              <X />
                              Dismiss
                            </Button>
                          </div>
                        ) : (
                          <span className="text-xs text-muted-foreground">Reviewed</span>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                  {sortedReports.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={7} className="py-14 text-center">
                        <div className="flex flex-col items-center gap-2 text-muted-foreground">
                          <Flag className="size-8 opacity-40" />
                          <p className="text-sm">No reports</p>
                        </div>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="stories" className="mt-4">
          <Card>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Couple</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Testimonial</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                    <TableHead className="text-right text-xs uppercase tracking-wide text-muted-foreground">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {stories.map((s) => (
                    <TableRow key={s.StoryId}>
                      <TableCell className="font-medium">{s.FirstName1} &amp; {s.FirstName2}</TableCell>
                      <TableCell className="max-w-[360px] truncate text-muted-foreground">{s.Testimonial}</TableCell>
                      <TableCell>
                        <span className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs ${
                          s.IsPublished ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30' : 'bg-muted text-muted-foreground border-border'
                        }`}>
                          {s.IsPublished ? 'Published' : 'Unpublished'}
                        </span>
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          size="sm"
                          variant="outline"
                          className={s.IsPublished ? 'text-muted-foreground' : 'text-primary hover:text-primary'}
                          disabled={busyId === s.StoryId}
                          onClick={() => handleStory(s.StoryId, !s.IsPublished)}
                        >
                          {busyId === s.StoryId ? <Loader2 className="animate-spin" /> : <HeartHandshake />}
                          {s.IsPublished ? 'Unpublish' : 'Publish'}
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                  {stories.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={4} className="py-14 text-center">
                        <div className="flex flex-col items-center gap-2 text-muted-foreground">
                          <ShieldAlert className="size-8 opacity-40" />
                          <p className="text-sm">No success stories submitted</p>
                        </div>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
