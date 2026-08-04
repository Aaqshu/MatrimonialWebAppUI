'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';

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
      <h2 className="text-2xl font-bold mb-6">Payments</h2>
      <Card className="bg-gray-900 border-gray-800">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-gray-800">
                <TableHead className="text-gray-400">Tenant</TableHead>
                <TableHead className="text-gray-400">Amount</TableHead>
                <TableHead className="text-gray-400">Gateway</TableHead>
                <TableHead className="text-gray-400">Transaction</TableHead>
                <TableHead className="text-gray-400">Status</TableHead>
                <TableHead className="text-gray-400">Paid On</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {payments.map((p) => (
                <TableRow key={p.PaymentId} className="border-gray-800">
                  <TableCell>{p.CompanyName || '—'}</TableCell>
                  <TableCell>{p.Currency} ₹{p.Amount}</TableCell>
                  <TableCell className="text-gray-400">{p.PaymentGateway || '—'}</TableCell>
                  <TableCell className="text-gray-400 font-mono text-xs">{p.TransactionId || '—'}</TableCell>
                  <TableCell>
                    <Badge variant={p.Status === 'success' ? 'default' : p.Status === 'failed' ? 'destructive' : 'secondary'}>{p.Status}</Badge>
                  </TableCell>
                  <TableCell className="text-gray-400 text-xs">{p.PaidOn ? new Date(p.PaidOn).toLocaleString() : '—'}</TableCell>
                </TableRow>
              ))}
              {payments.length === 0 && <TableRow><TableCell colSpan={6} className="text-center text-gray-500 py-8">No payments yet</TableCell></TableRow>}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
