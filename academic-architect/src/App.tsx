import React, { useState, useEffect } from 'react';
import { 
  LayoutDashboard, 
  Calendar, 
  BookOpen, 
  Timer, 
  BarChart3, 
  MessageSquare, 
  Settings,
  LogOut,
  Flame,
  Trophy,
  User as UserIcon,
  Brain
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { auth, db } from './firebase';
import { onAuthStateChanged, signInWithPopup, GoogleAuthProvider, signOut, User } from 'firebase/auth';
import { doc, getDoc, setDoc, collection, query, where, onSnapshot } from 'firebase/firestore';

// Components
import Dashboard from './components/Dashboard';
import Planner from './components/Planner';
import KnowledgeHub from './components/KnowledgeHub';
import StudyMode from './components/StudyMode';
import Analytics from './components/Analytics';
import ChatAssistant from './components/ChatAssistant';
import MockTests from './components/MockTests';

export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        const userDoc = await getDoc(doc(db, 'users', u.uid));
        if (userDoc.exists()) {
          setUserProfile(userDoc.data());
        } else {
          // New user - redirect to planner or set default
          const defaultProfile = {
            uid: u.uid,
            displayName: u.displayName,
            examMode: 'UPSC',
            streak: 0,
            xp: 0,
            badges: [],
            lastActive: new Date().toISOString()
          };
          await setDoc(doc(db, 'users', u.uid), defaultProfile);
          setUserProfile(defaultProfile);
          setActiveTab('planner');
        }
      }
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const handleLogin = async () => {
    const provider = new GoogleAuthProvider();
    try {
      await signInWithPopup(auth, provider);
    } catch (error) {
      console.error("Login failed:", error);
    }
  };

  const handleLogout = () => signOut(auth);

  if (loading) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-zinc-950 text-zinc-100">
        <div className="animate-pulse flex flex-col items-center gap-4">
          <div className="w-12 h-12 rounded-full border-4 border-primary border-t-transparent animate-spin" />
          <p className="text-zinc-400 font-medium tracking-widest uppercase text-xs">Initializing Academic Architect...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="h-screen w-full flex flex-col items-center justify-center bg-zinc-950 text-zinc-100 p-6">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-md w-full text-center space-y-8"
        >
          <div className="space-y-2">
            <h1 className="text-5xl font-bold tracking-tighter text-primary italic">ACADEMIC ARCHITECT</h1>
            <p className="text-zinc-400 text-lg">Your Personal AI Study Command Center</p>
          </div>
          
          <div className="p-8 rounded-3xl bg-zinc-900/50 border border-zinc-800 space-y-6">
            <p className="text-zinc-300">Master your preparation with AI-driven scheduling, discipline tracking, and real-time analytics.</p>
            <button 
              onClick={handleLogin}
              className="w-full py-4 px-6 rounded-xl bg-primary hover:bg-primary/90 text-white font-bold transition-all flex items-center justify-center gap-3"
            >
              <UserIcon size={20} />
              Continue with Google
            </button>
          </div>
          
          <div className="grid grid-cols-3 gap-4 text-[10px] uppercase tracking-widest text-zinc-500 font-bold">
            <div className="space-y-1">
              <div className="h-px bg-zinc-800 w-full" />
              <span>Adaptive</span>
            </div>
            <div className="space-y-1">
              <div className="h-px bg-zinc-800 w-full" />
              <span>Disciplined</span>
            </div>
            <div className="space-y-1">
              <div className="h-px bg-zinc-800 w-full" />
              <span>Optimized</span>
            </div>
          </div>
        </motion.div>
      </div>
    );
  }

  const navItems = [
    { id: 'dashboard', icon: LayoutDashboard, label: 'Dashboard' },
    { id: 'library', icon: BookOpen, label: 'Library' },
    { id: 'mocktests', icon: Brain, label: 'Mock Tests' },
    { id: 'focus', icon: Timer, label: 'Focus Mode' },
    { id: 'insights', icon: BarChart3, label: 'Insights' },
  ];

  return (
    <div className="h-screen w-full flex bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 overflow-hidden">
      {/* Sidebar */}
      <nav className="w-20 md:w-72 border-r border-slate-200 dark:border-slate-900 flex flex-col p-6 bg-white dark:bg-slate-950">
        <div className="flex items-center gap-3 px-2 mb-12">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-white font-black">AA</div>
          <span className="hidden md:block text-xl font-bold tracking-tight text-primary">Academic Architect</span>
        </div>

        <div className="flex-1 space-y-2">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center gap-4 p-4 rounded-2xl transition-all group ${
                activeTab === item.id 
                  ? 'bg-primary/10 text-primary' 
                  : 'text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-900'
              }`}
            >
              <item.icon size={22} strokeWidth={activeTab === item.id ? 2.5 : 2} />
              <span className={`hidden md:block font-semibold ${activeTab === item.id ? 'opacity-100' : 'opacity-70'}`}>{item.label}</span>
            </button>
          ))}
        </div>

        <div className="pt-6 border-t border-slate-100 dark:border-slate-900 space-y-6">
          <div className="hidden md:block px-2">
            <div className="flex items-center justify-between text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">
              <span>Aspirant Level</span>
              <span>{userProfile?.xp || 0} XP</span>
            </div>
            <div className="h-2 w-full bg-slate-100 dark:bg-slate-900 rounded-full overflow-hidden">
              <div 
                className="h-full bg-primary transition-all duration-500" 
                style={{ width: `${Math.min((userProfile?.xp || 0) % 100, 100)}%` }} 
              />
            </div>
          </div>
          
          <button 
            onClick={handleLogout}
            className="w-full flex items-center gap-4 p-4 rounded-2xl text-slate-500 hover:bg-rose-50 dark:hover:bg-rose-950/20 hover:text-rose-500 transition-all"
          >
            <LogOut size={22} />
            <span className="hidden md:block font-semibold">Logout</span>
          </button>
        </div>
      </nav>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto relative bg-slate-50 dark:bg-slate-950">
        <AnimatePresence mode="wait">
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.3, ease: "easeOut" }}
            className="p-8 md:p-12 max-w-6xl mx-auto"
          >
            {activeTab === 'dashboard' && <Dashboard user={user} profile={userProfile} />}
            {activeTab === 'library' && <Planner user={user} profile={userProfile} />}
            {activeTab === 'mocktests' && <MockTests user={user} />}
            {activeTab === 'focus' && <StudyMode user={user} />}
            {activeTab === 'insights' && <Analytics user={user} />}
          </motion.div>
        </AnimatePresence>

        <ChatAssistant user={user} />
      </main>
    </div>
  );
}
