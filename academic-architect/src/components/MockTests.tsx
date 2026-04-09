import React, { useState } from 'react';
import { generateMockTest } from '../services/gemini';
import { motion, AnimatePresence } from 'motion/react';
import { Trophy, Brain, ChevronRight, Loader2, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';

export default function MockTests({ user }: { user: any }) {
  const [subject, setSubject] = useState('Polity');
  const [difficulty, setDifficulty] = useState('medium');
  const [questions, setQuestions] = useState<any[]>([]);
  const [currentIdx, setCurrentIdx] = useState(-1); // -1 means selection screen
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null);
  const [score, setScore] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [showResult, setShowResult] = useState(false);

  const subjects = ['Polity', 'Economy', 'History', 'Geography', 'Environment', 'Science & Tech'];

  const startTest = async () => {
    setIsLoading(true);
    try {
      const q = await generateMockTest(subject, difficulty);
      setQuestions(q);
      setCurrentIdx(0);
      setScore(0);
      setSelectedAnswer(null);
      setShowResult(false);
    } catch (error) {
      console.error("Failed to generate test:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleAnswer = (idx: number) => {
    if (selectedAnswer !== null) return;
    setSelectedAnswer(idx);
    if (idx === questions[currentIdx].correctAnswer) {
      setScore(s => s + 1);
    }
  };

  const nextQuestion = () => {
    if (currentIdx < questions.length - 1) {
      setCurrentIdx(i => i + 1);
      setSelectedAnswer(null);
    } else {
      setShowResult(true);
    }
  };

  if (isLoading) {
    return (
      <div className="h-[60vh] flex flex-col items-center justify-center space-y-6">
        <div className="relative">
          <div className="w-20 h-20 rounded-full border-4 border-primary/20 border-t-primary animate-spin" />
          <Brain className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-primary" size={32} />
        </div>
        <div className="text-center space-y-2">
          <h2 className="text-xl font-bold tracking-tight">Generating Mock Test</h2>
          <p className="text-slate-500 text-sm">Gemini is architecting UPSC-standard questions for you...</p>
        </div>
      </div>
    );
  }

  if (showResult) {
    return (
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="max-w-2xl mx-auto text-center space-y-8 py-12"
      >
        <div className="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto text-primary">
          <Trophy size={48} />
        </div>
        <div className="space-y-2">
          <h2 className="text-4xl font-black tracking-tight">Test Complete</h2>
          <p className="text-slate-500 font-medium">Performance Analysis: {subject} ({difficulty})</p>
        </div>
        
        <div className="grid grid-cols-2 gap-6">
          <div className="academic-card p-8">
            <div className="text-4xl font-black text-primary">{score}/{questions.length}</div>
            <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Score</div>
          </div>
          <div className="academic-card p-8">
            <div className="text-4xl font-black text-emerald-500">{Math.round((score / questions.length) * 100)}%</div>
            <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Accuracy</div>
          </div>
        </div>

        <button 
          onClick={() => setCurrentIdx(-1)}
          className="px-8 py-4 rounded-2xl bg-primary text-white font-bold shadow-xl shadow-primary/20 hover:bg-primary/90 transition-all"
        >
          Back to Library
        </button>
      </motion.div>
    );
  }

  if (currentIdx >= 0) {
    const q = questions[currentIdx];
    return (
      <div className="max-w-3xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary font-bold">
              {currentIdx + 1}
            </div>
            <div className="text-sm font-bold text-slate-400 uppercase tracking-widest">Question {currentIdx + 1} of {questions.length}</div>
          </div>
          <div className="px-3 py-1 rounded-md bg-slate-100 dark:bg-slate-900 text-[10px] font-bold text-slate-500 uppercase tracking-widest">
            {subject} • {difficulty}
          </div>
        </div>

        <div className="academic-card p-10 space-y-8">
          <h3 className="text-2xl font-bold leading-tight text-slate-900 dark:text-white">
            {q.question}
          </h3>

          <div className="space-y-4">
            {q.options.map((opt: string, i: number) => {
              const isSelected = selectedAnswer === i;
              const isCorrect = i === q.correctAnswer;
              const showCorrect = selectedAnswer !== null && isCorrect;
              const showWrong = selectedAnswer === i && !isCorrect;

              return (
                <button
                  key={i}
                  onClick={() => handleAnswer(i)}
                  disabled={selectedAnswer !== null}
                  className={`w-full p-5 rounded-2xl border-2 text-left transition-all flex items-center justify-between group ${
                    showCorrect 
                      ? 'bg-emerald-50 border-emerald-500 text-emerald-900' 
                      : showWrong 
                        ? 'bg-rose-50 border-rose-500 text-rose-900'
                        : isSelected
                          ? 'border-primary bg-primary/5'
                          : 'border-slate-100 dark:border-slate-800 hover:border-primary/30'
                  }`}
                >
                  <span className="font-semibold">{opt}</span>
                  {showCorrect && <CheckCircle2 size={20} className="text-emerald-500" />}
                  {showWrong && <XCircle size={20} className="text-rose-500" />}
                </button>
              );
            })}
          </div>

          <AnimatePresence>
            {selectedAnswer !== null && (
              <motion.div 
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="p-6 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800 space-y-3"
              >
                <div className="flex items-center gap-2 text-primary font-bold text-xs uppercase tracking-widest">
                  <AlertCircle size={14} />
                  Explanation
                </div>
                <p className="text-slate-600 dark:text-slate-400 text-sm leading-relaxed">
                  {q.explanation}
                </p>
                <button 
                  onClick={nextQuestion}
                  className="mt-4 w-full py-4 rounded-xl bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-bold flex items-center justify-center gap-2"
                >
                  {currentIdx === questions.length - 1 ? 'Finish Test' : 'Next Question'}
                  <ChevronRight size={18} />
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-10">
      <header className="space-y-1">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Mock Test Arena</h1>
        <p className="text-slate-500 font-medium">Simulate real UPSC conditions with AI-generated practice sets.</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="academic-card p-10 space-y-8">
          <div className="space-y-6">
            <div className="space-y-3">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Select Subject</label>
              <div className="grid grid-cols-2 gap-3">
                {subjects.map(s => (
                  <button
                    key={s}
                    onClick={() => setSubject(s)}
                    className={`p-4 rounded-xl border-2 font-bold text-sm transition-all ${
                      subject === s 
                        ? 'border-primary bg-primary/5 text-primary' 
                        : 'border-slate-100 dark:border-slate-800 text-slate-500 hover:border-primary/20'
                    }`}
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>

            <div className="space-y-3">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Difficulty Level</label>
              <div className="flex gap-3">
                {['easy', 'medium', 'hard'].map(d => (
                  <button
                    key={d}
                    onClick={() => setDifficulty(d)}
                    className={`flex-1 py-3 rounded-xl border-2 font-bold text-xs uppercase tracking-widest transition-all ${
                      difficulty === d 
                        ? 'border-primary bg-primary/5 text-primary' 
                        : 'border-slate-100 dark:border-slate-800 text-slate-500 hover:border-primary/20'
                    }`}
                  >
                    {d}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <button 
            onClick={startTest}
            className="w-full py-5 rounded-2xl bg-primary text-white font-bold shadow-xl shadow-primary/20 hover:bg-primary/90 transition-all flex items-center justify-center gap-3"
          >
            <Brain size={20} />
            Begin Simulation
          </button>
        </div>

        <div className="space-y-6">
          <div className="academic-card p-8 bg-slate-900 text-white space-y-4">
            <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center text-primary">
              <AlertCircle size={24} />
            </div>
            <h3 className="text-xl font-bold">Simulation Rules</h3>
            <ul className="space-y-3 text-sm text-slate-400 font-medium">
              <li className="flex items-start gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5" />
                Each set contains 5 high-yield UPSC style questions.
              </li>
              <li className="flex items-start gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5" />
                Explanations are provided after each answer.
              </li>
              <li className="flex items-start gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5" />
                Performance affects your overall Aspirant Level (XP).
              </li>
            </ul>
          </div>

          <div className="academic-card p-8 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-500 flex items-center justify-center">
                <Trophy size={24} />
              </div>
              <div>
                <div className="text-sm font-bold">Recent High Score</div>
                <div className="text-xs text-slate-500">Polity • Hard</div>
              </div>
            </div>
            <div className="text-2xl font-black text-slate-900 dark:text-white">4/5</div>
          </div>
        </div>
      </div>
    </div>
  );
}
