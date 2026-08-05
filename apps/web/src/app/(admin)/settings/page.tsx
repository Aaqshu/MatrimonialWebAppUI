'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

interface Setting {
  id: string;
  settingKey: string;
  settingValue: string;
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<Setting[]>([]);
  const [editing, setEditing] = useState<string | null>(null);
  const [value, setValue] = useState('');

  useEffect(() => {
    api.get('/admin/settings').then(({ data }) => setSettings(data.map((s: any) => ({
      id: s.SettingId, settingKey: s.SettingKey, settingValue: s.SettingValue,
    })))).catch(console.error);
  }, []);

  const handleSave = async (id: string) => {
    await api.patch(`/admin/settings/${id}`, { SettingValue: value });
    setEditing(null);
    setSettings(settings.map(s => s.id === id ? { ...s, settingValue: value } : s));
  };

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-2xl font-semibold tracking-tight">System Settings</h2>
        <p className="mt-1 text-sm text-muted-foreground">Platform-wide configuration key/value pairs</p>
      </div>
      <div className="max-w-xl space-y-2">
        {settings.map((s) => (
          <Card key={s.id}>
            <CardContent className="flex items-center justify-between py-3">
              <Label className="text-foreground">{s.settingKey}</Label>
              {editing === s.id ? (
                <div className="flex gap-2">
                  <Input value={value} onChange={e => setValue(e.target.value)} className="w-48" />
                  <Button size="sm" onClick={() => handleSave(s.id)}>Save</Button>
                  <Button size="sm" variant="ghost" onClick={() => setEditing(null)}>Cancel</Button>
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground">{s.settingValue || '—'}</span>
                  <Button size="sm" variant="ghost" onClick={() => { setEditing(s.id); setValue(s.settingValue); }}>Edit</Button>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
