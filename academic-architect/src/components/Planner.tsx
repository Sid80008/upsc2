import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Calendar, Clock, BookOpen, Sparkles, Loader2, Check, AlertTriangle } from 'lucide-react';

export default function Planner({ user, profile }: { user: any, profile: any }) {
  const [dailyHours, setDailyHours] = useState(profile?.daily_study_hours || 8);
  const [caWeight, setCaWeight] = useState(profile?.current_affairs_weight || 30);
  const [focusLevel, setFocusLevel] = useState(profile?.focus_level || 'Medium');
  const [distractionLevel, setDistractionLevel] = useState(profile?.distraction_level || 'Low');
  const [weakSubjects, setWeakSubjects] = useState(profile?.weak_subjects || '');
  const [strongSubjects, setStrongSubjects] = useState(profile?.strong_subjects || '');
  const [subjects, setSubjects] = useState<string[]>(['Polity', 'Economy', 'History', 'Geography', 'Environment']);
  const [activeCategory, setActiveCategory] = useState('All');
  const [isGenerating, setIsGenerating] = useState(false);
  const [success, setSuccess] = useState(false);

  const categories = ['All', 'Core', 'Current Affairs', 'Optional', 'CSAT'];

  const handleGenerate = async () => {
    setIsGenerating(true);
    try {
      // 1. Update Preferences on Backend
      await fetch('http://127.0.0.1:8000/auth/preferences', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer mock_token',
        },
        body: JSON.stringify({
          daily_study_hours: dailyHours,
          current_affairs_weight: caWeight,
          focus_level: focusLevel,
          revision_preference: 'Standard',
        }),
      });

      // 2. Trigger Recovery/Optimization Engine (Simulated Sync)
      await fetch('http://127.0.0.1:8000/recovery/optimize', {
        method: 'POST',
        headers: { 'Authorization': 'Bearer mock_token' }
      });
      
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (error) {
      console.error("Generation failed:", error);
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div className="space-y-10">
      <header className="space-y-1">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Subject Library</h1>
        <p className="text-slate-500 font-medium">Manage your UPSC curriculum and configure the behavioral scheduler.</p>
      </header>

      {/* Category Filter */}
      <div className="flex items-center gap-3 overflow-x-auto pb-2 scrollbar-hide">
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`px-6 py-2.5 rounded-full text-sm font-bold whitespace-nowrap transition-all ${
              activeCategory === cat 
                ? 'bg-primary text-white shadow-lg shadow-primary/20' 
                : 'bg-white dark:bg-slate-900 text-slate-500 border border-slate-200 dark:border-slate-800 hover:border-primary/30'
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Scheduler Config */}
        <div className="lg:col-span-1 space-y-6">
          <div className="academic-card p-8 space-y-8">
            <h3 className="text-lg font-bold flex items-center gap-2">
              <Sparkles size={20} className="text-primary" />
              Behavioral Engine
            </h3>
            
            <div className="space-y-6">
              <div className="space-y-3">
                <div className="flex justify-between items-end">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Daily Study Hours</label>
                  <span className="text-sm font-bold text-primary">{dailyHours}h</span>
                </div>
                <input 
                  type="range" 
                  min="2" 
                  max="16" 
                  value={dailyHours}
                  onChange={(e) => setDailyHours(Number(e.target.value))}
                  className="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-lg appearance-none cursor-pointer accent-primary"
                />
              </div>

              <div className="space-y-3">
                <div className="flex justify-between items-end">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Current Affairs Weight</label>
                  <span className="text-sm font-bold text-primary">{caWeight}%</span>
                </div>
                <input 
                  type="range" 
                  min="0" 
                  max="100" 
                  value={caWeight}
                  onChange={(e) => setCaWeight(Number(e.target.value))}
                  className="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-lg appearance-none cursor-pointer accent-primary"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Focus Level</label>
                  <select 
                    value={focusLevel}
                    onChange={(e) => setFocusLevel(e.target.value)}
                    className="w-full p-2 rounded-lg bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-xs font-bold"
                  >
                    <option>Low</option>
                    <option>Medium</option>
                    <option>High</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Distraction</label>
                  <select 
                    value={distractionLevel}
                    onChange={(e) => setDistractionLevel(e.target.value)}
                    className="w-full p-2 rounded-lg bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-xs font-bold"
                  >
                    <option>Low</option>
                    <option>Medium</option>
                    <option>High</option>
                  </select>
                </div>
              </div>

              <div className="space-y-3">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Weak Subjects</label>
                <input 
                  type="text"
                  placeholder="e.g. Economy, History"
                  value={weakSubjects}
                  onChange={(e) => setWeakSubjects(e.target.value)}
                  className="w-full p-3 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-sm"
                />
              </div>
            </div>

            <button 
              onClick={handleGenerate}
              disabled={isGenerating}
              className="w-full py-4 rounded-2xl bg-primary hover:bg-primary/90 disabled:bg-slate-100 text-white font-bold transition-all flex items-center justify-center gap-3"
            >
              {isGenerating ? <Loader2 size={20} className="animate-spin" /> : success ? <Check size={20} /> : <Sparkles size={20} />}
              {isGenerating ? 'Recalculating...' : success ? 'Schedule Ready' : 'Sync Scheduler'}
            </button>
          </div>
        </div>

        {/* Subject Cards */}
        <div className="lg:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-6">
          {subjects.map((subject, i) => (
            <div key={i} className="academic-card p-6 space-y-6 group">
              <div className="flex items-center justify-between">
                <div className="w-12 h-12 rounded-2xl bg-slate-50 dark:bg-slate-800 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white transition-all">
                  <BookOpen size={24} />
                </div>
                <div className="px-2 py-1 rounded-md bg-emerald-50 text-[10px] font-bold text-emerald-600 uppercase tracking-wider">
                  Core
                </div>
              </div>
              
              <div>
                <h4 className="text-xl font-bold text-slate-900 dark:text-white mb-1">{subject}</h4>
                <p className="text-xs text-slate-500 font-medium">UPSC General Studies Paper I</p>
              </div>

              <div className="space-y-2">
                <div className="flex justify-between text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                  <span>Mastery</span>
                  <span>{40 + i * 12}%</span>
                </div>
                <div className="h-1.5 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-primary transition-all duration-500" 
                    style={{ width: `${40 + i * 12}%` }} 
                  />
                </div>
              </div>

              <button className="w-full py-3 rounded-xl border border-slate-200 dark:border-slate-800 text-sm font-bold text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 transition-all">
                Study Now
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
