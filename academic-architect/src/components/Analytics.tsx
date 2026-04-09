import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { BarChart3, TrendingUp, Calendar, Clock, Target, Zap } from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  LineChart,
  Line,
  AreaChart,
  Area
} from 'recharts';

export default function Analytics({ user }: { user: any }) {
  const [reports, setReports] = useState<any[]>([]);
  const [blocks, setBlocks] = useState<any[]>([]);

  useEffect(() => {
    // In a full integration, this fetches from /analytics/weekly
    const mockBlocks = [
      { date: new Date().toISOString().split('T')[0], status: 'completed', subject: 'Polity' },
      { date: new Date().toISOString().split('T')[0], status: 'completed', subject: 'History' },
      { date: new Date().toISOString().split('T')[0], status: 'pending', subject: 'Economy' },
    ];
    setBlocks(mockBlocks);
  }, [user.uid]);

  // Aggregate data for charts
  const last7Days = [...Array(7)].map((_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - i);
    return d.toISOString().split('T')[0];
  }).reverse();

  const chartData = last7Days.map(date => {
    const dayBlocks = blocks.filter(b => b.date === date);
    const completed = dayBlocks.filter(b => b.status === 'completed').length;
    return {
      name: new Date(date).toLocaleDateString([], { weekday: 'short' }),
      completed,
      total: dayBlocks.length,
      efficiency: dayBlocks.length > 0 ? (completed / dayBlocks.length) * 100 : 0
    };
  });

  const subjectData = Array.from(new Set(blocks.map(b => b.subject))).map(subject => {
    const subBlocks = blocks.filter(b => b.subject === subject);
    const completed = subBlocks.filter(b => b.status === 'completed').length;
    return {
      name: subject,
      value: completed
    };
  });

  return (
    <div className="space-y-10">
      <header className="space-y-1">
        <h2 className="text-sm font-bold text-emerald-500 uppercase tracking-[0.2em]">Performance Intelligence</h2>
        <h1 className="text-4xl font-bold tracking-tight">Analytics & Reports</h1>
        <p className="text-zinc-500">Deep dive into your study patterns and efficiency metrics.</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="p-6 rounded-3xl bg-zinc-900 border border-zinc-800 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Avg. Efficiency</span>
            <TrendingUp size={16} className="text-emerald-500" />
          </div>
          <div className="text-3xl font-bold">
            {Math.round(chartData.reduce((acc, curr) => acc + curr.efficiency, 0) / 7)}%
          </div>
        </div>
        <div className="p-6 rounded-3xl bg-zinc-900 border border-zinc-800 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Total Blocks</span>
            <Target size={16} className="text-emerald-500" />
          </div>
          <div className="text-3xl font-bold">
            {blocks.filter(b => b.status === 'completed').length}
          </div>
        </div>
        <div className="p-6 rounded-3xl bg-zinc-900 border border-zinc-800 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">Focus Streak</span>
            <Zap size={16} className="text-orange-500" />
          </div>
          <div className="text-3xl font-bold">12 Days</div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Weekly Activity */}
        <div className="p-8 rounded-3xl bg-zinc-900 border border-zinc-800 space-y-6">
          <h3 className="font-bold flex items-center gap-2">
            <Calendar size={18} className="text-emerald-500" />
            Weekly Block Completion
          </h3>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" vertical={false} />
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fill: '#71717a', fontSize: 12 }} 
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fill: '#71717a', fontSize: 12 }} 
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#18181b', border: '1px solid #27272a', borderRadius: '12px' }}
                  itemStyle={{ color: '#10b981' }}
                />
                <Bar dataKey="completed" fill="#10b981" radius={[4, 4, 0, 0]} barSize={30} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Subject Distribution */}
        <div className="p-8 rounded-3xl bg-zinc-900 border border-zinc-800 space-y-6">
          <h3 className="font-bold flex items-center gap-2">
            <Book size={18} className="text-emerald-500" />
            Subject Mastery
          </h3>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="colorEff" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#27272a" vertical={false} />
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fill: '#71717a', fontSize: 12 }} 
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fill: '#71717a', fontSize: 12 }} 
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#18181b', border: '1px solid #27272a', borderRadius: '12px' }}
                />
                <Area type="monotone" dataKey="efficiency" stroke="#10b981" fillOpacity={1} fill="url(#colorEff)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}

const Book = ({ size, className }: { size: number, className?: string }) => (
  <svg 
    width={size} 
    height={size} 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke="currentColor" 
    strokeWidth="2" 
    strokeLinecap="round" 
    strokeLinejoin="round" 
    className={className}
  >
    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
  </svg>
);
