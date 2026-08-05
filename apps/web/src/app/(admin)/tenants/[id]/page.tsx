'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { ArrowLeft, ClipboardList } from 'lucide-react';

interface TenantDetail {
  TenantId: string;
  TenantCode: string;
  CompanyName: string;
  OwnerName: string;
  Email: string;
  Phone: string;
  City: string;
  State: string;
  Country: string;
  DatabaseName: string;
  DatabaseServer: string;
  Status: string;
  IsActive: boolean;
}

interface ThemeConfig {
  BusinessName: string;
  PrimaryColor: string;
  SecondaryColor: string;
  FontFamily: string;
  Tagline: string;
  ContactEmail: string;
  ContactPhone: string;
}

interface FeatureFlags {
  MatchingEnabled: boolean;
  VideoCallEnabled: boolean;
  KundliMatchingEnabled: boolean;
  MaxPhotosPerProfile: number;
}

interface ProvisionLog {
  Step: string;
  Status: string;
  ErrorMessage: string;
  CreatedOn: string;
}

export default function TenantDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const [tenant, setTenant] = useState<TenantDetail | null>(null);
  const [theme, setTheme] = useState<ThemeConfig | null>(null);
  const [flags, setFlags] = useState<FeatureFlags | null>(null);
  const [logs, setLogs] = useState<ProvisionLog[]>([]);
  const [provisioning, setProvisioning] = useState(false);

  const fetchAll = () => {
    api.get(`/admin/tenants/${id}`).then(({ data }) => setTenant(data)).catch(console.error);
    api.get(`/admin/theme-configs/${id}`).then(({ data }) => setTheme(data)).catch(console.error);
    api.get(`/admin/feature-flags/${id}`).then(({ data }) => setFlags(data)).catch(console.error);
    api.get(`/admin/provisioning/${id}`).then(({ data }) => setLogs(data)).catch(console.error);
  };

  useEffect(() => { fetchAll(); }, [id]);

  const saveTheme = async () => {
    if (!theme) return;
    await api.patch(`/admin/theme-configs/${id}`, theme);
  };

  const saveFlags = async () => {
    if (!flags) return;
    await api.patch(`/admin/feature-flags/${id}`, flags);
  };

  const runProvisioning = async () => {
    setProvisioning(true);
    try {
      await api.post(`/admin/provisioning/${id}/run`);
      fetchAll();
    } catch (e) {
      console.error(e);
    } finally {
      setProvisioning(false);
    }
  };

  if (!tenant) return <p className="text-muted-foreground">Loading...</p>;

  return (
    <div className="max-w-4xl space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">{tenant.CompanyName}</h2>
          <p className="font-mono text-sm text-muted-foreground">{tenant.TenantCode} · {tenant.TenantId}</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => router.push('/tenants')}><ArrowLeft />Back</Button>
          <Button onClick={runProvisioning} disabled={provisioning}>
            {provisioning ? 'Provisioning...' : 'Run Provisioning'}
          </Button>
        </div>
      </div>

      <div className="flex gap-2">
        <Badge>{tenant.Status}</Badge>
        <Badge variant={tenant.IsActive ? 'default' : 'secondary'}>{tenant.IsActive ? 'Active' : 'Inactive'}</Badge>
        <Badge variant="secondary" className="font-mono">{tenant.DatabaseName}</Badge>
      </div>

      <Card>
        <CardHeader><CardTitle className="text-lg">Tenant Details</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-3 gap-4 text-sm">
          <div><Label className="text-muted-foreground">Owner</Label><p className="mt-1">{tenant.OwnerName || '—'}</p></div>
          <div><Label className="text-muted-foreground">Email</Label><p className="mt-1">{tenant.Email}</p></div>
          <div><Label className="text-muted-foreground">Phone</Label><p className="mt-1">{tenant.Phone || '—'}</p></div>
          <div><Label className="text-muted-foreground">City</Label><p className="mt-1">{tenant.City || '—'}</p></div>
          <div><Label className="text-muted-foreground">State</Label><p className="mt-1">{tenant.State || '—'}</p></div>
          <div><Label className="text-muted-foreground">Country</Label><p className="mt-1">{tenant.Country}</p></div>
          <div><Label className="text-muted-foreground">DB Server</Label><p className="mt-1 font-mono">{tenant.DatabaseServer || '—'}</p></div>
        </CardContent>
      </Card>

      {theme && (
        <Card>
          <CardHeader><CardTitle className="text-lg">Theme & Branding</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-2 gap-3 text-sm">
            <div><Label>Business Name</Label><Input value={theme.BusinessName} onChange={e => setTheme({...theme, BusinessName: e.target.value})} /></div>
            <div><Label>Tagline</Label><Input value={theme.Tagline || ''} onChange={e => setTheme({...theme, Tagline: e.target.value})} /></div>
            <div><Label>Primary Color</Label><div className="flex items-center gap-2"><input type="color" value={theme.PrimaryColor} onChange={e => setTheme({...theme, PrimaryColor: e.target.value})} className="h-8 w-12 rounded-md border border-input bg-transparent" /><Input value={theme.PrimaryColor} onChange={e => setTheme({...theme, PrimaryColor: e.target.value})} className="font-mono" /></div></div>
            <div><Label>Secondary Color</Label><div className="flex items-center gap-2"><input type="color" value={theme.SecondaryColor} onChange={e => setTheme({...theme, SecondaryColor: e.target.value})} className="h-8 w-12 rounded-md border border-input bg-transparent" /><Input value={theme.SecondaryColor} onChange={e => setTheme({...theme, SecondaryColor: e.target.value})} className="font-mono" /></div></div>
            <div><Label>Font</Label><Input value={theme.FontFamily} onChange={e => setTheme({...theme, FontFamily: e.target.value})} /></div>
            <div><Label>Contact Email</Label><Input value={theme.ContactEmail || ''} onChange={e => setTheme({...theme, ContactEmail: e.target.value})} /></div>
            <div><Label>Contact Phone</Label><Input value={theme.ContactPhone || ''} onChange={e => setTheme({...theme, ContactPhone: e.target.value})} /></div>
            <div className="col-span-2"><Button onClick={saveTheme}>Save Theme</Button></div>
          </CardContent>
        </Card>
      )}

      {flags && (
        <Card>
          <CardHeader><CardTitle className="text-lg">Feature Flags</CardTitle></CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex items-center justify-between"><Label>Matching Enabled</Label><Switch checked={flags.MatchingEnabled} onCheckedChange={v => setFlags({...flags, MatchingEnabled: v})} /></div>
            <div className="flex items-center justify-between"><Label>Video Call Enabled</Label><Switch checked={flags.VideoCallEnabled} onCheckedChange={v => setFlags({...flags, VideoCallEnabled: v})} /></div>
            <div className="flex items-center justify-between"><Label>Kundli Matching</Label><Switch checked={flags.KundliMatchingEnabled} onCheckedChange={v => setFlags({...flags, KundliMatchingEnabled: v})} /></div>
            <div className="flex items-center justify-between"><Label>Max Photos Per Profile</Label><Input type="number" value={flags.MaxPhotosPerProfile} onChange={e => setFlags({...flags, MaxPhotosPerProfile: Number(e.target.value)})} className="w-24" /></div>
            <Button onClick={saveFlags}>Save Flags</Button>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader><CardTitle className="text-lg">Provisioning Logs</CardTitle></CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Step</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Error</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Time</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {logs.map((l, i) => (
                <TableRow key={i}>
                  <TableCell className="font-mono text-xs">{l.Step}</TableCell>
                  <TableCell><Badge variant={l.Status === 'success' ? 'default' : l.Status === 'failed' ? 'destructive' : 'secondary'}>{l.Status}</Badge></TableCell>
                  <TableCell className="text-xs text-destructive">{l.ErrorMessage || '—'}</TableCell>
                  <TableCell className="text-xs text-muted-foreground">{new Date(l.CreatedOn).toLocaleString()}</TableCell>
                </TableRow>
              ))}
              {logs.length === 0 && (
                <TableRow>
                  <TableCell colSpan={4} className="py-10 text-center">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <ClipboardList className="size-7 opacity-40" />
                      <p className="text-sm">Not provisioned yet — click Run Provisioning</p>
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
