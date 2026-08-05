'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Wallet } from 'lucide-react';

interface Payment {
  PaymentId: string;
  CompanyName: string;
  Amount: number;
  Currency: string;
  PaymentGateway: string;
  TransactionId: string;
  Status: string;
  PaidOn: string;
}

export default function PaymentsPage() {
  const [payments, setPayments] = useState<Payment[]>([]);

  useEffect(() => { api.get('/admin/payments').then(({ data }) => setPayments(data)).catch(console.error); }, []);

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-2xl font-semibold tracking-tight">Payments</h2>
        <p className="mt-1 text-sm text-muted-foreground">Transaction history across all tenants</p>
      </div>
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Tenant</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Amount</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Gateway</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Transaction</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Paid On</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {payments.map((p) => (
                <TableRow key={p.PaymentId}>
                  <TableCell className="font-medium">{p.CompanyName || '—'}</TableCell>
                  <TableCell className="tabular-nums">{p.Currency} ₹{p.Amount}</TableCell>
                  <TableCell className="text-muted-foreground">{p.PaymentGateway || '—'}</TableCell>
                  <TableCell className="font-mono text-xs text-muted-foreground">{p.TransactionId || '—'}</TableCell>
                  <TableCell>
                    <Badge variant={p.Status === 'success' ? 'default' : p.Status === 'failed' ? 'destructive' : 'secondary'}>{p.Status}</Badge>
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">{p.PaidOn ? new Date(p.PaidOn).toLocaleString() : '—'}</TableCell>
                </TableRow>
              ))}
              {payments.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="py-14 text-center">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <Wallet className="size-8 opacity-40" />
                      <p className="text-sm">No payments yet</p>
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
