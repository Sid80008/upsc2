import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Play, Pause, RotateCcw, CheckCircle2, AlertCircle, Volume2, VolumeX } from 'lucide-react';

export default function StudyMode({ user }: { user: any }) {
  const [activeBlock, setActiveBlock] = useState<any>(null);
  const [timeLeft, setTimeLeft] = useState(0);
  const [isActive, setIsActive] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const timerRef = useRef<any>(null);

  useEffect(() => {
    const today = new Date().toISOString().split('T')[0];
    
    fetch(`http://127.0.0.1:8000/schedule/1/${today}`, {
      headers: { Authorization: "Bearer mock_token" }
    })
      .then(res => res.json())
      .then(data => {
        if (data && data.blocks) {
          const pending = data.blocks.filter((b: any) => b.status === 'pending');
          if (pending.length > 0 && !activeBlock) {
            const sorted = pending.sort((a: any, b: any) => a.start_time.localeCompare(b.start_time));
            setActiveBlock(sorted[0]);
            setTimeLeft(sorted[0].duration_minutes * 60);
          }
        }
      })
      .catch(console.error);
  }, [user.uid, activeBlock]);

  useEffect(() => {
    if (isActive && timeLeft > 0) {
      timerRef.current = setInterval(() => {
        setTimeLeft(prev => prev - 1);
      }, 1000);
    } else if (timeLeft === 0 && isActive) {
      handleComplete();
    } else {
      clearInterval(timerRef.current);
    }
    return () => clearInterval(timerRef.current);
  }, [isActive, timeLeft]);

  const handleComplete = async () => {
    setIsActive(false);
    if (activeBlock) {
      // In a real implementation this sends telemetry to the backend
      setActiveBlock(null);
      // Play alarm sound (simulated)
      if (!isMuted) {
        const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
        audio.play();
      }
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  if (!activeBlock) {
    return (
      <div className="h-[60vh] flex flex-col items-center justify-center text-center space-y-6">
        <div className="w-20 h-20 rounded-full bg-zinc-900 flex items-center justify-center text-zinc-700">
          <CheckCircle2 size={40} />
        </div>
        <div className="space-y-2">
          <h2 className="text-2xl font-bold">All Blocks Clear</h2>
          <p className="text-zinc-500 max-w-sm">No pending study blocks for today. Take a break or plan your next session.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-12 py-10">
      <header className="text-center space-y-4">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-500 text-[10px] font-bold uppercase tracking-widest border border-emerald-500/20">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
          Active Study Session
        </div>
        <h1 className="text-5xl font-bold tracking-tight">{activeBlock.subject || 'Focus Time'}</h1>
        <p className="text-xl text-zinc-400">{activeBlock.topic}</p>
      </header>

      <div className="relative flex flex-col items-center justify-center">
        {/* Timer Display */}
        <div className="text-[12rem] font-black tracking-tighter text-zinc-100 leading-none select-none">
          {formatTime(timeLeft)}
        </div>

        {/* Controls */}
        <div className="flex items-center gap-8 mt-10">
          <button 
            onClick={() => setTimeLeft(activeBlock.duration_minutes * 60)}
            className="p-4 rounded-full bg-zinc-900 text-zinc-400 hover:text-zinc-100 transition-colors"
          >
            <RotateCcw size={24} />
          </button>
          
          <button 
            onClick={() => setIsActive(!isActive)}
            className={`w-24 h-24 rounded-full flex items-center justify-center transition-all ${
              isActive 
                ? 'bg-zinc-100 text-zinc-950 scale-110' 
                : 'bg-emerald-500 text-zinc-950 hover:bg-emerald-400'
            }`}
          >
            {isActive ? <Pause size={40} fill="currentColor" /> : <Play size={40} fill="currentColor" className="ml-2" />}
          </button>

          <button 
            onClick={() => setIsMuted(!isMuted)}
            className="p-4 rounded-full bg-zinc-900 text-zinc-400 hover:text-zinc-100 transition-colors"
          >
            {isMuted ? <VolumeX size={24} /> : <Volume2 size={24} />}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-12">
        <div className="p-6 rounded-3xl bg-zinc-900 border border-zinc-800 flex items-start gap-4">
          <AlertCircle className="text-emerald-500 shrink-0" size={24} />
          <div className="space-y-1">
            <h4 className="font-bold text-zinc-200">Focus Mode Active</h4>
            <p className="text-sm text-zinc-500">Tab switching is being monitored. Stay on this page for maximum XP gain.</p>
          </div>
        </div>
        
        <div className="p-6 rounded-3xl bg-zinc-900 border border-zinc-800 flex items-start gap-4">
          <div className="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-500 shrink-0 font-bold">
            +20
          </div>
          <div className="space-y-1">
            <h4 className="font-bold text-zinc-200">Session Reward</h4>
            <p className="text-sm text-zinc-500">Completing this block will grant you 20 XP and advance your daily goal.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
