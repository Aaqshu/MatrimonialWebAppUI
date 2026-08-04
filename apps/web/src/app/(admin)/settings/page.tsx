'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
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

  useEffect(() => { api.get('/admin/settings').then(({ data }) => setSettings(data)).catch(console.error); }, []);

  const handleSave = async (id: string) => {
    await api.patch(`/admin/settings/${id}`, { settingValue: value });
    setEditing(null);
    setSettings(settings.map(s => s.id === id ? { ...s, settingValue: value } : s));
  };

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">System Settings</h2>
      <div className="space-y-3 max-w-xl">
        {settings.map((s) => (
          <Card key={s.id} className="bg-gray-900 border-gray-800">
            <CardContent className="flex items-center justify-between py-3">
              <Label className="text-gray-300">{s.settingKey}</Label>
              {editing === s.id ? (
                <div className="flex gap-2">
                  <Input value={value} onChange={e => setValue(e.target.value)} className="bg-gray-800 border-gray-700 w-48" />
                  <Button size="sm" onClick={() => handleSave(s.id)}>Save</Button>
                  <Button size="sm" variant="ghost" onClick={() => setEditing(null)}>Cancel</Button>
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <span className="text-gray-400 text-sm">{s.settingValue || '—'}</span>
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
