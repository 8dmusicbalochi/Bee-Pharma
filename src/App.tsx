import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { Session } from '@supabase/supabase-js';
import { supabase } from './lib/supabase';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import { Pill } from 'lucide-react';

function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const getSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setSession(session);
      setLoading(false);
    };

    getSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-secondary">
        <Pill className="h-12 w-12 text-primary animate-bounce" />
        <p className="mt-4 text-lg font-medium text-secondary-foreground">Loading B-Pharma POS...</p>
      </div>
    );
  }

  return (
    <Router>
      {!session ? <LoginPage /> : <DashboardPage />}
    </Router>
  );
}

export default App;
