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

  if (!tenant) return <p className="text-gray-400">Loading...</p>;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">{tenant.CompanyName}</h2>
          <p className="text-sm text-gray-400 font-mono">{tenant.TenantCode} · {tenant.TenantId}</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => router.push('/tenants')}>← Back</Button>
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

      <Card className="bg-gray-900 border-gray-800">
        <CardHeader><CardTitle className="text-lg">Tenant Details</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-3 gap-3 text-sm">
          <div><Label className="text-gray-500">Owner</Label><p>{tenant.OwnerName || '—'}</p></div>
          <div><Label className="text-gray-500">Email</Label><p>{tenant.Email}</p></div>
          <div><Label className="text-gray-500">Phone</Label><p>{tenant.Phone || '—'}</p></div>
          <div><Label className="text-gray-500">City</Label><p>{tenant.City || '—'}</p></div>
          <div><Label className="text-gray-500">State</Label><p>{tenant.State || '—'}</p></div>
          <div><Label className="text-gray-500">Country</Label><p>{tenant.Country}</p></div>
          <div><Label className="text-gray-500">DB Server</Label><p className="font-mono">{tenant.DatabaseServer || '—'}</p></div>
        </CardContent>
      </Card>

      {theme && (
        <Card className="bg-gray-900 border-gray-800">
          <CardHeader><CardTitle className="text-lg">Theme & Branding</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-2 gap-3 text-sm">
            <div><Label>Business Name</Label><Input value={theme.BusinessName} onChange={e => setTheme({...theme, BusinessName: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
            <div><Label>Tagline</Label><Input value={theme.Tagline || ''} onChange={e => setTheme({...theme, Tagline: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
            <div><Label>Primary Color</Label><div className="flex gap-2 items-center"><input type="color" value={theme.PrimaryColor} onChange={e => setTheme({...theme, PrimaryColor: e.target.value})} className="h-8 w-12 rounded bg-gray-800" /><Input value={theme.PrimaryColor} onChange={e => setTheme({...theme, PrimaryColor: e.target.value})} className="bg-gray-800 border-gray-700 font-mono" /></div></div>
            <div><Label>Secondary Color</Label><div className="flex gap-2 items-center"><input type="color" value={theme.SecondaryColor} onChange={e => setTheme({...theme, SecondaryColor: e.target.value})} className="h-8 w-12 rounded bg-gray-800" /><Input value={theme.SecondaryColor} onChange={e => setTheme({...theme, SecondaryColor: e.target.value})} className="bg-gray-800 border-gray-700 font-mono" /></div></div>
            <div><Label>Font</Label><Input value={theme.FontFamily} onChange={e => setTheme({...theme, FontFamily: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
            <div><Label>Contact Email</Label><Input value={theme.ContactEmail || ''} onChange={e => setTheme({...theme, ContactEmail: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
            <div><Label>Contact Phone</Label><Input value={theme.ContactPhone || ''} onChange={e => setTheme({...theme, ContactPhone: e.target.value})} className="bg-gray-800 border-gray-700" /></div>
            <div className="col-span-2"><Button onClick={saveTheme}>Save Theme</Button></div>
          </CardContent>
        </Card>
      )}

      {flags && (
        <Card className="bg-gray-900 border-gray-800">
          <CardHeader><CardTitle className="text-lg">Feature Flags</CardTitle></CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex justify-between items-center"><Label>Matching Enabled</Label><Switch checked={flags.MatchingEnabled} onCheckedChange={v => setFlags({...flags, MatchingEnabled: v})} /></div>
            <div className="flex justify-between items-center"><Label>Video Call Enabled</Label><Switch checked={flags.VideoCallEnabled} onCheckedChange={v => setFlags({...flags, VideoCallEnabled: v})} /></div>
            <div className="flex justify-between items-center"><Label>Kundli Matching</Label><Switch checked={flags.KundliMatchingEnabled} onCheckedChange={v => setFlags({...flags, KundliMatchingEnabled: v})} /></div>
            <div className="flex justify-between items-center"><Label>Max Photos Per Profile</Label><Input type="number" value={flags.MaxPhotosPerProfile} onChange={e => setFlags({...flags, MaxPhotosPerProfile: Number(e.target.value)})} className="bg-gray-800 border-gray-700 w-24" /></div>
            <Button onClick={saveFlags}>Save Flags</Button>
          </CardContent>
        </Card>
      )}

      <Card className="bg-gray-900 border-gray-800">
        <CardHeader><CardTitle className="text-lg">Provisioning Logs</CardTitle></CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-gray-800">
                <TableHead className="text-gray-400">Step</TableHead>
                <TableHead className="text-gray-400">Status</TableHead>
                <TableHead className="text-gray-400">Error</TableHead>
                <TableHead className="text-gray-400">Time</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {logs.map((l, i) => (
                <TableRow key={i} className="border-gray-800">
                  <TableCell className="font-mono text-xs">{l.Step}</TableCell>
                  <TableCell><Badge variant={l.Status === 'success' ? 'default' : l.Status === 'failed' ? 'destructive' : 'secondary'}>{l.Status}</Badge></TableCell>
                  <TableCell className="text-red-400 text-xs">{l.ErrorMessage || '—'}</TableCell>
                  <TableCell className="text-gray-400 text-xs">{new Date(l.CreatedOn).toLocaleString()}</TableCell>
                </TableRow>
              ))}
              {logs.length === 0 && <TableRow><TableCell colSpan={4} className="text-center text-gray-500 py-6">Not provisioned yet — click Run Provisioning</TableCell></TableRow>}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
