import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { CheckCircle2, Circle, Clock, Flame, Trophy, Zap, AlertCircle, Target, Sparkles } from 'lucide-react';
import { getBehavioralInsight } from '../services/gemini';

export default function Dashboard({ user, profile }: { user: any, profile: any }) {
  const [todayBlocks, setTodayBlocks] = useState<any[]>([]);
  const [insight, setInsight] = useState<any>(null);
  const [stats, setStats] = useState({
    completed: 0,
    total: 0,
    xp: profile?.xp || 0,
    streak: profile?.streak || 0
  });

  useEffect(() => {
    const today = new Date().toISOString().split('T')[0];
    
    // Fetch Summary
    fetch('http://127.0.0.1:8000/dashboard/summary', {
      headers: { Authorization: "Bearer mock_token" }
    }).then(res => res.json()).then(data => {
      setStats(prev => ({
        ...prev,
        xp: data.xp || 0,
        streak: data.streak_days || 0,
      }));
    }).catch(console.error);

    // Fetch Schedule
    fetch(`http://127.0.0.1:8000/schedule/1/${today}`, {
      headers: { Authorization: "Bearer mock_token" }
    }).then(res => res.json()).then(data => {
      if (data && data.blocks) {
        setTodayBlocks(data.blocks);
        setStats(prev => ({
          ...prev,
          completed: data.blocks.filter((b: any) => b.status === 'completed').length,
          total: data.blocks.length
        }));
        if (data.blocks.length > 0 && !insight) {
          getBehavioralInsight(profile, data.blocks.slice(0, 5)).then(setInsight);
        }
      }
    }).catch(console.error);

  }, [user.uid, profile]);

  const toggleStatus = async (block: any) => {
    const newStatus = block.status === 'completed' ? 'pending' : 'completed';
    
    // Update local state (in a full implementation, this triggers an API call)
    setTodayBlocks(prev => prev.map(b => b.id === block.id ? { ...b, status: newStatus } : b));
    if (newStatus === 'completed') {
      setStats(prev => ({...prev, xp: prev.xp + 10, completed: prev.completed + 1}));
    } else {
      setStats(prev => ({...prev, xp: prev.xp - 10, completed: prev.completed - 1}));
    }
  };

  const progress = stats.total > 0 ? (stats.completed / stats.total) * 100 : 0;

  return (
    <div className="space-y-10">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div className="space-y-1">
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Aspirant Dashboard</h1>
          <p className="text-slate-500 font-medium">Welcome back, {user.displayName?.split(' ')[0]}. Your focus is your greatest asset.</p>
        </div>
        <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-primary/5 border border-primary/10 text-primary text-xs font-bold uppercase tracking-widest">
          <Zap size={14} />
          Premium Access
        </div>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Flow Progress Card */}
        <div className="lg:col-span-2 academic-card p-10 bg-primary text-white relative overflow-hidden">
          <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-8">
            <div className="space-y-4 text-center md:text-left">
              <h2 className="text-4xl font-bold tracking-tight">Flow Progress</h2>
              <p className="text-primary-foreground/80 max-w-md font-medium">
                You've completed {stats.completed} out of {stats.total} tasks today. 
                Keep the momentum going to reach your daily goal.
              </p>
              <div className="flex items-center gap-4 justify-center md:justify-start">
                <div className="px-4 py-2 rounded-xl bg-white/10 backdrop-blur-md border border-white/20 text-sm font-bold">
                  {Math.round(progress)}% Daily Target
                </div>
              </div>
            </div>
            <div className="relative w-48 h-48 flex items-center justify-center">
              <svg className="w-full h-full transform -rotate-90">
                <circle
                  cx="96"
                  cy="96"
                  r="80"
                  stroke="currentColor"
                  strokeWidth="12"
                  fill="transparent"
                  className="text-white/10"
                />
                <circle
                  cx="96"
                  cy="96"
                  r="80"
                  stroke="currentColor"
                  strokeWidth="12"
                  fill="transparent"
                  strokeDasharray={502}
                  strokeDashoffset={502 - (502 * progress) / 100}
                  strokeLinecap="round"
                  className="text-white transition-all duration-1000 ease-out"
                />
              </svg>
              <span className="absolute text-4xl font-black">{Math.round(progress)}%</span>
            </div>
          </div>
          {/* Decorative elements */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full -mr-32 -mt-32 blur-3xl" />
          <div className="absolute bottom-0 left-0 w-48 h-48 bg-black/10 rounded-full -ml-24 -mb-24 blur-2xl" />
        </div>

        {/* Behavioral Insight Card */}
        <div className="lg:col-span-1 academic-card p-8 space-y-6 border-primary/20 bg-primary/5">
          <div className="flex items-center gap-2 text-primary font-bold text-xs uppercase tracking-widest">
            <Sparkles size={16} />
            Behavioral Insight
          </div>
          
          {insight ? (
            <div className="space-y-4">
              <p className="text-slate-700 dark:text-slate-300 font-medium leading-relaxed italic">
                "{insight.insight}"
              </p>
              <div className="p-4 rounded-xl bg-white dark:bg-slate-900 border border-primary/10 space-y-2">
                <div className="text-[10px] font-bold text-primary uppercase tracking-widest">Action Point</div>
                <p className="text-sm font-bold text-slate-900 dark:text-white">{insight.actionPoint}</p>
              </div>
            </div>
          ) : (
            <div className="animate-pulse space-y-4">
              <div className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-full" />
              <div className="h-4 bg-slate-200 dark:bg-slate-800 rounded w-3/4" />
              <div className="h-20 bg-slate-200 dark:bg-slate-800 rounded w-full" />
            </div>
          )}
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[
          { label: 'Streak', value: stats.streak, icon: Flame, color: 'text-orange-500', bg: 'bg-orange-50' },
          { label: 'XP Earned', value: stats.xp, icon: Zap, color: 'text-primary', bg: 'bg-primary/5' },
          { label: 'Focus Score', value: '8.4', icon: Target, color: 'text-emerald-500', bg: 'bg-emerald-50' },
        ].map((stat, i) => (
          <div key={i} className="academic-card p-6 flex items-center gap-5">
            <div className={`w-14 h-14 rounded-2xl ${stat.bg} flex items-center justify-center ${stat.color}`}>
              <stat.icon size={28} strokeWidth={2.5} />
            </div>
            <div>
              <div className="text-2xl font-bold text-slate-900 dark:text-white">{stat.value}</div>
              <div className="text-xs font-bold text-slate-400 uppercase tracking-widest">{stat.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Activity Feed */}
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h3 className="text-xl font-bold text-slate-900 dark:text-white">Today's Plan</h3>
          <button className="text-xs font-bold text-primary uppercase tracking-widest hover:underline">View All</button>
        </div>

        <div className="space-y-4">
          {todayBlocks.length === 0 ? (
            <div className="academic-card p-12 text-center space-y-4 border-dashed">
              <div className="w-16 h-16 bg-slate-50 dark:bg-slate-900 rounded-full flex items-center justify-center mx-auto text-slate-300">
                <Clock size={32} />
              </div>
              <p className="text-slate-500 font-medium">No activities scheduled for today.</p>
            </div>
          ) : (
            todayBlocks.map((block, idx) => (
              <motion.div
                key={block.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: idx * 0.1 }}
                className="academic-card p-5 flex items-center gap-6 group"
              >
                <div className="flex flex-col items-center gap-1 min-w-[60px]">
                  <span className="text-xs font-bold text-slate-400 uppercase">
                    {block.startTime}
                  </span>
                  <div className="w-px h-8 bg-slate-100 dark:bg-slate-800" />
                </div>
                
                <button 
                  onClick={() => toggleStatus(block)}
                  className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all ${
                    block.status === 'completed' 
                      ? 'bg-success text-white' 
                      : 'bg-slate-50 dark:bg-slate-800 text-slate-300 hover:text-primary hover:bg-primary/5'
                  }`}
                >
                  {block.status === 'completed' ? <CheckCircle2 size={20} /> : <Circle size={20} />}
                </button>

                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="px-2 py-0.5 rounded-md bg-slate-100 dark:bg-slate-800 text-[10px] font-bold text-slate-500 uppercase tracking-wider">
                      {block.subject}
                    </span>
                  </div>
                  <h4 className={`font-bold text-lg ${block.status === 'completed' ? 'text-slate-400 line-through' : 'text-slate-900 dark:text-white'}`}>
                    {block.topic}
                  </h4>
                </div>

                <div className="text-right hidden sm:block">
                  <div className="text-sm font-bold text-slate-900 dark:text-white">{block.durationMinutes}m</div>
                  <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Duration</div>
                </div>
              </motion.div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
