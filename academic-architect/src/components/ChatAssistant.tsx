import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { MessageSquare, Send, X, Bot, User as UserIcon, Loader2 } from 'lucide-react';
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

export default function ChatAssistant({ user }: { user: any }) {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<any[]>([
    { role: 'assistant', text: `Hello ${user.displayName?.split(' ')[0]}! I'm your Aegis companion. How can I help you with your preparation today?` }
  ]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMsg = { role: 'user', text: input };
    setMessages(prev => [...prev, userMsg]);
    setInput('');
    setIsTyping(true);

    try {
      const chat = ai.chats.create({
        model: "gemini-1.5-flash",
        config: {
          systemInstruction: "You are Aegis, a helpful study companion for competitive exam aspirants. Be motivating, concise, and focused on helping the user succeed."
        }
      });

      const result = await chat.sendMessage({ message: input });
      
      setMessages(prev => [...prev, { role: 'assistant', text: result.text || "I'm sorry, I couldn't process that." }]);
    } catch (error) {
      console.error("Chat failed:", error);
      setMessages(prev => [...prev, { role: 'assistant', text: "I'm having trouble connecting right now. Please try again later." }]);
    } finally {
      setIsTyping(false);
    }
  };

  return (
    <div className="fixed bottom-6 right-6 z-50">
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            className="absolute bottom-20 right-0 w-80 md:w-96 h-[500px] bg-zinc-900 border border-zinc-800 rounded-3xl shadow-2xl flex flex-col overflow-hidden"
          >
            <div className="p-4 border-b border-zinc-800 bg-zinc-900/50 backdrop-blur-md flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-emerald-500 flex items-center justify-center text-zinc-950">
                  <Bot size={18} />
                </div>
                <div>
                  <h3 className="font-bold text-sm">Aegis Assistant</h3>
                  <div className="flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                    <span className="text-[10px] text-zinc-500 font-bold uppercase tracking-widest">Active</span>
                  </div>
                </div>
              </div>
              <button onClick={() => setIsOpen(false)} className="text-zinc-500 hover:text-zinc-100">
                <X size={20} />
              </button>
            </div>

            <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-4 scrollbar-hide">
              {messages.map((m, i) => (
                <div key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[85%] p-3 rounded-2xl text-sm leading-relaxed ${
                    m.role === 'user' 
                      ? 'bg-emerald-500 text-zinc-950 font-medium rounded-tr-none' 
                      : 'bg-zinc-800 text-zinc-100 rounded-tl-none'
                  }`}>
                    {m.text}
                  </div>
                </div>
              ))}
              {isTyping && (
                <div className="flex justify-start">
                  <div className="bg-zinc-800 p-3 rounded-2xl rounded-tl-none">
                    <Loader2 size={16} className="animate-spin text-zinc-500" />
                  </div>
                </div>
              )}
            </div>

            <div className="p-4 bg-zinc-950 border-t border-zinc-800">
              <div className="flex gap-2">
                <input 
                  type="text" 
                  placeholder="Ask anything..."
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                  className="flex-1 bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2 text-sm text-zinc-100 focus:outline-none focus:border-emerald-500"
                />
                <button 
                  onClick={handleSend}
                  disabled={!input.trim() || isTyping}
                  className="p-2 rounded-xl bg-emerald-500 text-zinc-950 hover:bg-emerald-400 disabled:bg-zinc-800 disabled:text-zinc-600 transition-all"
                >
                  <Send size={18} />
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`w-14 h-14 rounded-full flex items-center justify-center shadow-xl transition-all ${
          isOpen ? 'bg-zinc-100 text-zinc-950 rotate-90' : 'bg-emerald-500 text-zinc-950 hover:scale-110'
        }`}
      >
        {isOpen ? <X size={24} /> : <MessageSquare size={24} />}
      </button>
    </div>
  );
}
