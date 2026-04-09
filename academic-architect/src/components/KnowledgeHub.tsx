import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Book, Plus, Search, Trash2, FileText, Folder } from 'lucide-react';

export default function KnowledgeHub({ user }: { user: any }) {
  const [notes, setNotes] = useState<any[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [newNote, setNewNote] = useState({ title: '', content: '', category: 'General' });
  const [searchQuery, setSearchQuery] = useState('');

  const fetchNotes = () => {
    fetch('http://127.0.0.1:8000/library/assets', {
      headers: { Authorization: "Bearer mock_token" }
    })
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) {
          setNotes(data.filter(a => a.asset_type === 'note'));
        }
      })
      .catch(console.error);
  };

  useEffect(() => {
    fetchNotes();
  }, [user.uid]);

  const handleAddNote = async () => {
    if (!newNote.title || !newNote.content) return;
    
    await fetch('http://127.0.0.1:8000/library/assets/link', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        Authorization: "Bearer mock_token" 
      },
      body: JSON.stringify({
        title: newNote.title,
        asset_type: 'note',
        meta_info: newNote.category,
        content_url: newNote.content,
      })
    });
    
    setNewNote({ title: '', content: '', category: 'General' });
    setIsAdding(false);
    fetchNotes();
  };

  const handleDelete = async (id: string) => {
    // In future, call delete endpoint. For now, mock local remove
    setNotes(prev => prev.filter(n => n.id !== id));
  };

  const filteredNotes = notes.filter(n => 
    (n.title?.toLowerCase() || '').includes(searchQuery.toLowerCase()) || 
    (n.content_url?.toLowerCase() || '').includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-8">
      <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div className="space-y-1">
          <h2 className="text-sm font-bold text-emerald-500 uppercase tracking-[0.2em]">Central Repository</h2>
          <h1 className="text-4xl font-bold tracking-tight">Knowledge Hub</h1>
          <p className="text-zinc-500">Organize your lecture notes, revision materials, and research.</p>
        </div>
        
        <button 
          onClick={() => setIsAdding(true)}
          className="px-6 py-3 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-zinc-950 font-bold transition-all flex items-center gap-2"
        >
          <Plus size={20} />
          New Entry
        </button>
      </header>

      <div className="flex items-center gap-4 p-2 rounded-2xl bg-zinc-900 border border-zinc-800">
        <Search size={20} className="ml-3 text-zinc-500" />
        <input 
          type="text" 
          placeholder="Search your knowledge base..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="flex-1 bg-transparent border-none p-3 text-zinc-100 focus:outline-none"
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <AnimatePresence>
          {isAdding && (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="p-6 rounded-3xl bg-zinc-900 border-2 border-emerald-500/30 space-y-4"
            >
              <input 
                type="text" 
                placeholder="Entry Title"
                value={newNote.title}
                onChange={(e) => setNewNote({ ...newNote, title: e.target.value })}
                className="w-full bg-zinc-950 border border-zinc-800 rounded-xl p-3 text-zinc-100 focus:outline-none focus:border-emerald-500"
              />
              <select 
                value={newNote.category}
                onChange={(e) => setNewNote({ ...newNote, category: e.target.value })}
                className="w-full bg-zinc-950 border border-zinc-800 rounded-xl p-3 text-zinc-100 focus:outline-none"
              >
                <option>General</option>
                <option>Current Affairs</option>
                <option>Revision Notes</option>
                <option>Subject Materials</option>
              </select>
              <textarea 
                placeholder="Content..."
                rows={4}
                value={newNote.content}
                onChange={(e) => setNewNote({ ...newNote, content: e.target.value })}
                className="w-full bg-zinc-950 border border-zinc-800 rounded-xl p-3 text-zinc-100 focus:outline-none focus:border-emerald-500 resize-none"
              />
              <div className="flex gap-2">
                <button 
                  onClick={handleAddNote}
                  className="flex-1 py-3 rounded-xl bg-emerald-500 text-zinc-950 font-bold hover:bg-emerald-400"
                >
                  Save
                </button>
                <button 
                  onClick={() => setIsAdding(false)}
                  className="flex-1 py-3 rounded-xl bg-zinc-800 text-zinc-100 font-bold hover:bg-zinc-700"
                >
                  Cancel
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {filteredNotes.map((note) => (
          <motion.div
            key={note.id}
            layout
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="p-6 rounded-3xl bg-zinc-900 border border-zinc-800 hover:border-zinc-700 transition-all group relative"
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2 px-2 py-1 rounded-lg bg-zinc-950 text-[10px] font-bold text-zinc-500 uppercase tracking-widest border border-zinc-800">
                <Folder size={10} />
                {note.meta_info || 'Note'}
              </div>
              <button 
                onClick={() => handleDelete(note.id)}
                className="text-zinc-700 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-all"
              >
                <Trash2 size={16} />
              </button>
            </div>
            <h3 className="text-xl font-bold mb-2">{note.title}</h3>
            <p className="text-zinc-500 text-sm line-clamp-4 leading-relaxed">
              {note.content_url}
            </p>
            <div className="mt-6 pt-4 border-t border-zinc-800 flex items-center justify-between">
              <span className="text-[10px] text-zinc-600 font-medium">
                {new Date(note.created_at || Date.now()).toLocaleDateString()}
              </span>
              <FileText size={14} className="text-zinc-700" />
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
